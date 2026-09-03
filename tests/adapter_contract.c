#include "statement_bridge.h"

#include <stddef.h>
#include <stdint.h>

int main(void)
{
    const char valid_status[STATEMENT_STATUS_WIDTH] = "PAYABLE ";
    const char invalid_status[STATEMENT_STATUS_WIDTH] = "PAY$BLE ";
    const char valid_rule[STATEMENT_RULE_WIDTH] = "TEST-BR-01";
    const char invalid_rule[STATEMENT_RULE_WIDTH] = "TEST_BR_01";
    const int32_t correct_length = STATEMENT_STATUS_WIDTH;
    const int32_t wrong_length = STATEMENT_STATUS_WIDTH - 1;
    const int32_t rule_length = STATEMENT_RULE_WIDTH;
    const int32_t wrong_rule_length = STATEMENT_RULE_WIDTH - 1;
    const int64_t net_cents = 0;

    if (
        emit_assessment_json(
            NULL,
            &correct_length,
            valid_rule,
            &rule_length,
            &net_cents
        ) != 2
    ) {
        return 1;
    }
    if (
        emit_assessment_json(
            valid_status,
            &wrong_length,
            valid_rule,
            &rule_length,
            &net_cents
        ) != 2
    ) {
        return 2;
    }
    if (
        emit_assessment_json(
            invalid_status,
            &correct_length,
            valid_rule,
            &rule_length,
            &net_cents
        ) != 2
    ) {
        return 3;
    }
    if (
        emit_assessment_json(
            valid_status,
            &correct_length,
            NULL,
            &rule_length,
            &net_cents
        ) != 2
    ) {
        return 4;
    }
    if (
        emit_assessment_json(
            valid_status,
            &correct_length,
            valid_rule,
            &wrong_rule_length,
            &net_cents
        ) != 2
    ) {
        return 5;
    }
    if (
        emit_assessment_json(
            valid_status,
            &correct_length,
            invalid_rule,
            &rule_length,
            &net_cents
        ) != 2
    ) {
        return 6;
    }

    return 0;
}
