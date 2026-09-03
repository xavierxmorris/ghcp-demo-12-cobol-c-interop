#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COBOL_SOURCE="$ROOT/src/cobol/statement_core.cob"

tr -d '\r' < "$ROOT/.gitignore" | grep -qx '/build/'

if grep -REq 'DEMO-BR-01|800000|320000|710000|260000|1450000' "$ROOT/src/c"; then
    printf 'FAIL: maintained C contains a shipped rule ID or calculation value.\n' >&2
    exit 1
fi

grep -q 'COMPUTE NET-CENTS' "$COBOL_SOURCE"
grep -q 'CALL "emit_assessment_json"' "$COBOL_SOURCE"
grep -q 'VALUE "DEMO-BR-01"' "$COBOL_SOURCE"

if find "$ROOT" \
    -path "$ROOT/build" -prune -o \
    -path "$ROOT/.git" -prune -o \
    -name 'statement_core.c' -print | grep -q .; then
    printf 'FAIL: compiler-generated statement_core.c exists outside build/.\n' >&2
    exit 1
fi

if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    if test -n "$(git -C "$ROOT" ls-files build)"; then
        printf 'FAIL: a generated build artifact is tracked by Git.\n' >&2
        exit 1
    fi
fi

printf 'PASS: shipped rule values remain in COBOL and generated C remains under build/.\n'
