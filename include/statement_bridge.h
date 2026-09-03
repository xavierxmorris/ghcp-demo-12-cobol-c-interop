#ifndef STATEMENT_BRIDGE_H
#define STATEMENT_BRIDGE_H

#include <stdint.h>

/*
 * Same-process ABI:
 * - status and rule are 8-bit, space-padded, non-NUL COBOL fields
 * - lengths and net_cents are native-endian signed integers
 * - every pointer remains valid for the duration of the call
 * - return codes: 0 success, 2 invalid ABI value, 3 output failure
 */
enum {
    STATEMENT_STATUS_WIDTH = 8,
    STATEMENT_RULE_WIDTH = 10
};

int emit_assessment_json(
    const char *status,
    const int32_t *status_length,
    const char *rule,
    const int32_t *rule_length,
    const int64_t *net_cents
);

#endif
