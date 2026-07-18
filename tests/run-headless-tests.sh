#!/usr/bin/env bash
# POSIX equivalent of tests/run-headless-tests.ps1 for Linux/containers.
# Runs the same twelve Godot 4.7.1 headless checks and fails on non-zero exit,
# missing success markers, or scanned engine/script/leak/assert failures.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-godot}"
if [[ ! -x "$GODOT" ]] && command -v godot >/dev/null 2>&1; then
	GODOT="$(command -v godot)"
fi
if [[ ! -x "$GODOT" ]]; then
	echo "Godot executable not found: $GODOT" >&2
	exit 1
fi

export TEMP="${TEMP:-$ROOT/.tmp}"
export TMP="${TMP:-$TEMP}"
mkdir -p "$TEMP" "$ROOT/.artifacts"

PROFILE="$TEMP/godot-user-$(cat /proc/sys/kernel/random/uuid 2>/dev/null || date +%s%N)"
export XDG_DATA_HOME="$PROFILE/share"
export XDG_CONFIG_HOME="$PROFILE/config"
export XDG_CACHE_HOME="$PROFILE/cache"
export HOME="$PROFILE/home"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$HOME"

cleanup() {
	if [[ -d "$PROFILE" ]]; then
		case "$PROFILE" in
			"$TEMP"/godot-user-*) rm -rf "$PROFILE" ;;
			*) echo "Refusing to remove unexpected profile path: $PROFILE" >&2; exit 1 ;;
		esac
	fi
}
trap cleanup EXIT

FAIL_PATTERN='ERROR:|SCRIPT ERROR|Parse Error|PROGRESSION_ASSERT|LAYOUT_ASSERT|PHYSICAL_ROUTE_ASSERT|PLAYER_INPUT_ASSERT|VISUAL_EFFECTS_ASSERT|SETTINGS_AUDIO_ASSERT|SETTINGS_PERSISTENCE_ASSERT|ObjectDB instances were leaked|Leaked instance:'

run_check() {
	local name="$1"
	local expected="$2"
	local post_script="$3"
	shift 3
	local log="$ROOT/.artifacts/test-${name}.log"
	local engine_log="$PROFILE/engine-${name}.log"
	local console_log="$PROFILE/console-${name}.log"
	local exit_code=0

	set +e
	"$GODOT" "$@" --log-file "$engine_log" >"$console_log" 2>&1
	exit_code=$?
	set -e

	if [[ -n "$post_script" ]]; then
		local post_engine="$PROFILE/engine-${name}-post.log"
		local post_console="$PROFILE/console-${name}-post.log"
		set +e
		"$GODOT" --headless --path "$ROOT" --script "$post_script" --log-file "$post_engine" >"$post_console" 2>&1
		local post_exit=$?
		set -e
		if [[ $post_exit -ne 0 ]]; then
			exit_code=$post_exit
		fi
		cat "$engine_log" "$console_log" "$post_engine" "$post_console" 2>/dev/null >"$log" || true
	else
		cat "$engine_log" "$console_log" 2>/dev/null >"$log" || true
	fi

	# Ensure log exists even if Godot wrote nothing
	touch "$log"

	if [[ $exit_code -ne 0 ]]; then
		echo "$name failed with exit code $exit_code. See $log" >&2
		cat "$log" >&2
		exit "$exit_code"
	fi
	if grep -E -q "$FAIL_PATTERN" "$log"; then
		echo "$name reported an engine or progression error. See $log" >&2
		cat "$log" >&2
		exit 1
	fi
	if [[ -n "$expected" ]] && ! grep -F -q "$expected" "$log"; then
		echo "$name did not reach expected marker '$expected'. See $log" >&2
		cat "$log" >&2
		exit 1
	fi
	echo "$name OK"
}

run_check "editor-import" "PROJECT_SETTINGS_STABILITY_OK" "res://tests/project-settings-stability-test.gd" \
	--headless --path "$ROOT" --editor --quit
run_check "menu" "" "" \
	--headless --path "$ROOT" --scene "res://scenes/boot/boot.tscn" --quit-after 8
run_check "gameplay" "" "" \
	--headless --path "$ROOT" --scene "res://scenes/gameplay/gameplay.tscn" --quit-after 20
run_check "game-state" "GAME_STATE_TEST_OK" "" \
	--headless --path "$ROOT" --script "res://tests/game-state-test.gd" --quit-after 20
run_check "progression" "PROGRESSION_TEST_OK" "" \
	--headless --path "$ROOT" --scene "res://tests/progression-test.tscn" --quit-after 1200
run_check "checkpoint-layout" "CHECKPOINT_LAYOUT_TEST_OK" "" \
	--headless --path "$ROOT" --scene "res://tests/checkpoint-layout-test.tscn" --quit-after 2000
run_check "physical-route" "PHYSICAL_ROUTE_SMOKE_TEST_OK" "" \
	--headless --path "$ROOT" --scene "res://tests/physical-route-smoke-test.tscn" --quit-after 3600
run_check "player-input" "PLAYER_INPUT_INTEGRATION_TEST_OK" "" \
	--headless --path "$ROOT" --scene "res://tests/player-input-integration-test.tscn" --quit-after 600
run_check "visual-effects" "VISUAL_EFFECTS_TEST_OK" "" \
	--headless --path "$ROOT" --scene "res://tests/visual-effects-test.tscn" --quit-after 180
run_check "settings-audio" "SETTINGS_AUDIO_TEST_OK" "" \
	--headless --path "$ROOT" --scene "res://tests/settings-audio-test.tscn" --quit-after 600
run_check "settings-persistence-write" "SETTINGS_PERSISTENCE_WRITE_OK" "" \
	--headless --path "$ROOT" --scene "res://tests/settings-persistence-write-test.tscn" --quit-after 60
run_check "settings-persistence-read" "SETTINGS_PERSISTENCE_READ_OK" "" \
	--headless --path "$ROOT" --scene "res://tests/settings-persistence-read-test.tscn" --quit-after 60

echo "ALL_TWELVE_HEADLESS_CHECKS_OK"
