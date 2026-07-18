#!/usr/bin/env bash
# Scan the committed tree for common credential patterns.
# This file is excluded from its own search so pattern literals cannot self-match.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Long GitHub/API token shapes and private-key headers. Require a non-empty
# Docker Hub token *assignment* (TOKEN=...), not bare secret names in YAML.
PATTERN='ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{20,}|BEGIN (RSA |OPENSSH )?PRIVATE KEY|DOCKERHUB_TOKEN=[^[:space:]"'\'']{8,}'

if git grep -nIE "$PATTERN" -- . \
	':(exclude)*.md' \
	':(exclude)docs/**' \
	':(exclude)plans/**' \
	':(exclude)CHANGELOG.md' \
	':(exclude).github/**' \
	':(exclude)tests/scan-secret-patterns.sh' \
	':(exclude)tests/verify-docker-packaging.*'; then
	echo "SECRET_PATTERN_HIT" >&2
	exit 1
fi

echo "SECRET_PATTERN_SCAN_OK"
