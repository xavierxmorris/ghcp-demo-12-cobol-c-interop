#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/build"
gcc \
    -std=c11 -pedantic -Wall -Wextra -Werror \
    -O1 -g -fno-omit-frame-pointer \
    -fsanitize=address,undefined -fno-sanitize-recover=all \
    -I"$ROOT/include" \
    "$ROOT/src/c/assessment_output.c" \
    "$ROOT/tests/adapter_contract.c" \
    -o "$ROOT/build/adapter-contract-sanitized"

ASAN_OPTIONS=detect_leaks=1:halt_on_error=1 \
UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1 \
    "$ROOT/build/adapter-contract-sanitized"
printf 'PASS: maintained C adapter under AddressSanitizer and UndefinedBehaviorSanitizer.\n'
