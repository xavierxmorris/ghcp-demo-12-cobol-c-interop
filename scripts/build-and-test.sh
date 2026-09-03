#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build"
GENERATED_DIR="$BUILD_DIR/generated"
COBOL_SOURCE="$ROOT/src/cobol/statement_core.cob"
C_SOURCE="$ROOT/src/c/assessment_output.c"
C_OBJECT="$BUILD_DIR/assessment_output.o"
EXPECTED="$ROOT/tests/expected-result.json"
NORMALIZED_EXPECTED="$BUILD_DIR/expected-result.json"
ABI_EXPECTED="$ROOT/tests/expected-abi-probe.json"
NORMALIZED_ABI_EXPECTED="$BUILD_DIR/expected-abi-probe.json"
NATIVE_BINARY="$BUILD_DIR/statement-core"
GENERATED_BINARY="$BUILD_DIR/statement-core-from-generated"
ABI_BINARY="$BUILD_DIR/abi-probe"
NATIVE_RESULT="$BUILD_DIR/result-native.json"
GENERATED_RESULT="$BUILD_DIR/result-generated.json"
ABI_RESULT="$BUILD_DIR/result-abi-probe.json"
COBC_STDERR="$BUILD_DIR/cobc.stderr"

rm -rf "$BUILD_DIR"
mkdir -p "$GENERATED_DIR"

run_cobc() {
    : > "$COBC_STDERR"
    if ! cobc "$@" 2> "$COBC_STDERR"; then
        cat "$COBC_STDERR" >&2
        return 1
    fi

    # Ubuntu 24.04 supplies _FORTIFY_SOURCE=3 while this GnuCOBOL package also
    # supplies =2. Preserve every other compiler diagnostic.
    sed \
        -e '/^<command-line>: warning: "_FORTIFY_SOURCE" redefined$/d' \
        -e '/^<command-line>: note: this is the location of the previous definition$/d' \
        "$COBC_STDERR" >&2
}

printf 'Toolchain\n'
cobc --version | sed -n '1p;/^C version/p'
gcc --version | sed -n '1p'
printf '\n'

printf '1/7 Compile and test the maintained C adapter\n'
gcc \
    -std=c11 \
    -pedantic \
    -Wall \
    -Wextra \
    -Werror \
    -I"$ROOT/include" \
    "$C_SOURCE" \
    "$ROOT/tests/adapter_contract.c" \
    -o "$BUILD_DIR/adapter-contract"
"$BUILD_DIR/adapter-contract"

gcc \
    -std=c11 \
    -pedantic \
    -Wall \
    -Wextra \
    -Werror \
    -I"$ROOT/include" \
    -c "$C_SOURCE" \
    -o "$C_OBJECT"

printf '2/7 Generate C from the COBOL source\n'
run_cobc \
    -x \
    -C \
    -free \
    -Wall \
    -o "$GENERATED_DIR/statement_core.c" \
    "$COBOL_SOURCE"

test -s "$GENERATED_DIR/statement_core.c"
grep -q 'libcob.h' "$GENERATED_DIR/statement_core.c"

printf '3/7 Build normally from COBOL plus the maintained C object\n'
run_cobc \
    -x \
    -free \
    -Wall \
    -o "$NATIVE_BINARY" \
    "$COBOL_SOURCE" \
    "$C_OBJECT"

printf '4/7 Build a second binary from the generated C artifact\n'
run_cobc \
    -x \
    -o "$GENERATED_BINARY" \
    "$GENERATED_DIR/statement_core.c" \
    "$C_OBJECT"

printf '5/7 Prove signed 64-bit values across the COBOL/C ABI\n'
run_cobc \
    -x \
    -free \
    -Wall \
    -o "$ABI_BINARY" \
    "$ROOT/tests/abi_probe.cob" \
    "$C_OBJECT"
"$ABI_BINARY" > "$ABI_RESULT"
tr -d '\r' < "$ABI_EXPECTED" > "$NORMALIZED_ABI_EXPECTED"
cmp "$NORMALIZED_ABI_EXPECTED" "$ABI_RESULT"

printf '6/7 Run both binaries and compare their observable result\n'
"$NATIVE_BINARY" > "$NATIVE_RESULT"
"$GENERATED_BINARY" > "$GENERATED_RESULT"
tr -d '\r' < "$EXPECTED" > "$NORMALIZED_EXPECTED"
cmp "$NORMALIZED_EXPECTED" "$NATIVE_RESULT"
cmp "$NORMALIZED_EXPECTED" "$GENERATED_RESULT"
cmp "$NATIVE_RESULT" "$GENERATED_RESULT"

printf '7/7 Run the source-ownership regression guard\n'
bash "$ROOT/scripts/repo-contract.sh"

{
    printf 'compiler=%s\n' "$(cobc --version | sed -n '1p')"
    printf 'configured_c_compiler=%s\n' "$(cobc --version | sed -n '/^C version/p')"
    printf 'gcc=%s\n' "$(gcc --version | sed -n '1p')"
    printf 'source_cobol_lines=%s\n' "$(wc -l < "$COBOL_SOURCE" | tr -d ' ')"
    printf 'generated_c_lines=%s\n' "$(wc -l < "$GENERATED_DIR/statement_core.c" | tr -d ' ')"
    printf 'generated_c_sha256=%s\n' "$(sha256sum "$GENERATED_DIR/statement_core.c" | cut -d' ' -f1)"
    printf 'result_sha256=%s\n' "$(sha256sum "$NATIVE_RESULT" | cut -d' ' -f1)"
    printf 'abi_probe_sha256=%s\n' "$(sha256sum "$ABI_RESULT" | cut -d' ' -f1)"
} > "$BUILD_DIR/evidence.txt"

printf '\nPASS: COBOL source and generated C produced identical results.\n'
printf 'PASS: the ABI preserved signed 64-bit values above and below 32-bit range.\n'
printf 'Result: '
cat "$NATIVE_RESULT"
printf 'Evidence: %s\n' "$BUILD_DIR/evidence.txt"
