#!/usr/bin/env bash
# Structural verification of Docker packaging for ROOM 407.
# Drives real files on disk; fails if packaging contracts are missing or wrong.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
fail=0

require_file() {
	local path="$1"
	if [[ ! -f "$path" ]]; then
		echo "MISSING: $path" >&2
		fail=1
	else
		echo "OK file: $path"
	fi
}

require_grep() {
	local path="$1"
	local pattern="$2"
	local label="$3"
	if [[ ! -f "$path" ]]; then
		echo "MISSING for grep: $path ($label)" >&2
		fail=1
		return
	fi
	if ! grep -E -q "$pattern" "$path"; then
		echo "MISSING pattern in $path ($label): $pattern" >&2
		fail=1
	else
		echo "OK pattern: $label"
	fi
}

require_no_grep() {
	local path="$1"
	local pattern="$2"
	local label="$3"
	if [[ ! -f "$path" ]]; then
		echo "MISSING for grep: $path ($label)" >&2
		fail=1
		return
	fi
	if grep -E -q "$pattern" "$path"; then
		echo "FORBIDDEN pattern in $path ($label): $pattern" >&2
		fail=1
	else
		echo "OK absent: $label"
	fi
}

require_file "Dockerfile"
require_file "docker-compose.yml"
require_file "docker-compose.local.yml"
require_file ".dockerignore"
require_file "tests/run-headless-tests.sh"
require_file "tests/run-headless-tests.ps1"

require_grep "Dockerfile" "4\\.7\\.1" "Dockerfile pins Godot 4.7.1"
require_grep "Dockerfile" "USER 65532:65532" "Dockerfile non-root user"
require_grep "Dockerfile" "HEALTHCHECK" "Dockerfile HEALTHCHECK"
require_grep "Dockerfile" "multi-stage|AS builder|AS runtime" "Dockerfile multi-stage stages"
require_grep "Dockerfile" "nguyenson1710/horror-game-suite|horror-game-suite" "Dockerfile image identity"
require_grep "Dockerfile" "GODOT_SHA256|sha256sum" "Dockerfile pins Godot download checksum"
require_grep "docker-compose.yml" "nguyenson1710/horror-game-suite" "compose image name"
require_grep ".dockerignore" "\\.env" "dockerignore excludes dotenv"
require_grep ".dockerignore" "docs/media" "dockerignore excludes docs-only cover media"
require_grep ".gitignore" "\\.env" "gitignore excludes dotenv"
require_no_grep ".github/workflows/docker-suite.yml" "^[[:space:]]*if:.*secrets\." "workflow condition does not reference secrets directly"
require_grep ".github/workflows/docker-suite.yml" "^[[:space:]]*if: github\.ref == 'refs/heads/main' && github\.event_name == 'push'$" "publish step remains main-push only"
require_grep ".github/workflows/docker-suite.yml" '^[[:space:]]*DOCKERHUB_USERNAME: \$\{\{ secrets\.DOCKERHUB_USERNAME \}\}$' "publish username stays step-scoped"
require_grep ".github/workflows/docker-suite.yml" '^[[:space:]]*DOCKERHUB_TOKEN: \$\{\{ secrets\.DOCKERHUB_TOKEN \}\}$' "publish token stays step-scoped"
require_grep ".github/workflows/docker-suite.yml" "publish skipped" "publish skips when secrets are absent"
require_grep ".github/workflows/docker-suite.yml" "permissions:" "workflow sets least-privilege permissions"
require_grep ".github/workflows/ci.yml" "permissions:" "ci workflow sets least-privilege permissions"
require_grep "docker-compose.yml" "run-headless-tests\\.sh|ENTRYPOINT" "compose suite entry"
require_grep "tests/run-headless-tests.sh" "editor-import" "shell runner editor-import"
require_grep "tests/run-headless-tests.sh" "settings-persistence-read" "shell runner last check"
require_grep "tests/run-headless-tests.sh" "ALL_TWELVE_HEADLESS_CHECKS_OK" "shell runner completion marker"
require_grep "tests/run-headless-tests.sh" "PROGRESSION_TEST_OK" "shell runner progression marker"
require_grep "tests/run-headless-tests.sh" "quit-after 120000" "shell runner physical-route frame budget"
require_grep "tests/run-headless-tests.ps1" "120000" "ps1 runner physical-route frame budget"
require_grep "tests/run-headless-tests.ps1" "settings-persistence-read" "ps1 runner last check"

# Enforce exactly twelve active runner invocations, not just twelve names that
# happen to appear somewhere in each file.
expected_checks=(
	editor-import
	menu
	gameplay
	game-state
	progression
	checkpoint-layout
	physical-route
	player-input
	visual-effects
	settings-audio
	settings-persistence-write
	settings-persistence-read
)
shell_check_count="$(grep -E -c '^[[:space:]]*run_check([[:space:]]|$)' tests/run-headless-tests.sh || true)"
ps_check_count="$(grep -E -c '^[[:space:]]*Invoke-GodotCheck[[:space:]]+' tests/run-headless-tests.ps1 || true)"
if [[ "$shell_check_count" -ne 12 ]]; then
	echo "FAIL shell runner must contain exactly 12 active run_check invocations (got $shell_check_count)" >&2
	fail=1
else
	echo "OK shell runner exact check count"
fi
if [[ "$ps_check_count" -ne 12 ]]; then
	echo "FAIL PowerShell runner must contain exactly 12 active Invoke-GodotCheck invocations (got $ps_check_count)" >&2
	fail=1
else
	echo "OK PowerShell runner exact check count"
fi
mapfile -t actual_shell_checks < <(sed -nE 's/^[[:space:]]*run_check[[:space:]]+"([^"]+)".*/\1/p' tests/run-headless-tests.sh)
if [[ "${actual_shell_checks[*]}" != "${expected_checks[*]}" ]]; then
	echo "FAIL shell runner check order/name sequence differs from the canonical twelve" >&2
	fail=1
else
	echo "OK shell runner exact check order"
fi
mapfile -t actual_ps_checks < <(sed -nE 's/^[[:space:]]*Invoke-GodotCheck[[:space:]]+.*\)[[:space:]]+"([^"]+)"([[:space:]]|$).*/\1/p' tests/run-headless-tests.ps1)
if [[ "${actual_ps_checks[*]}" != "${expected_checks[*]}" ]]; then
	echo "FAIL PowerShell runner check order/name sequence differs from the canonical twelve" >&2
	fail=1
else
	echo "OK PowerShell runner exact check order"
fi
for check in "${expected_checks[@]}"; do
	require_grep "tests/run-headless-tests.sh" "^[[:space:]]*run_check[[:space:]]+\"$check\"([[:space:]]|$)" "shell check $check"
	require_grep "tests/run-headless-tests.ps1" "^[[:space:]]*Invoke-GodotCheck .*\)[[:space:]]+\"$check\"([[:space:]]|$)" "ps1 check $check"
done

if [[ $fail -ne 0 ]]; then
	echo "DOCKER_PACKAGING_VERIFY_FAILED" >&2
	exit 1
fi
echo "DOCKER_PACKAGING_VERIFY_OK"
