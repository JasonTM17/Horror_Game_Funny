#!/usr/bin/env bash
# Scan the committed tree for common credential patterns.
# This file is excluded from its own search so pattern literals cannot self-match.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Long GitHub/API token shapes and private-key headers. Require a non-empty
# Docker Hub token *assignment* (TOKEN=...), not bare secret names in YAML.
PATTERN='ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{20,}|BEGIN (RSA |OPENSSH )?PRIVATE KEY|DOCKERHUB_TOKEN=[^[:space:]"'\'']{8,}'

# Scan the committed tree including workflows and docs/plans prose.
# Exclude only this scanner and packaging verifiers so their pattern
# literals cannot self-match. Markdown is included so DOCKERHUB_TOKEN=...
# style leaks in docs cannot hide.
if git grep -nIE "$PATTERN" -- . \
	':(exclude)tests/scan-secret-patterns.sh' \
	':(exclude)tests/verify-docker-packaging.ps1' \
	':(exclude)tests/verify-docker-packaging.sh'; then
	echo "SECRET_PATTERN_HIT" >&2
	exit 1
fi

echo "SECRET_PATTERN_SCAN_OK"
