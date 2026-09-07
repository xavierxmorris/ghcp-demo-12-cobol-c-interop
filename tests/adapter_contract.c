#include "statement_bridge.h"

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

int main(void)
{
    const char valid_status[STATEMENT_STATUS_WIDTH] = "PAYABLE ";
    const char invalid_status[STATEMENT_STATUS_WIDTH] = "PAY$BLE ";
    const char valid_rule[STATEMENT_RULE_WIDTH] = "TEST-BR-01";
    const char invalid_rule[STATEMENT_RULE_WIDTH] = "TEST_BR_01";
    const char blank_status[STATEMENT_STATUS_WIDTH] = "        ";
    const char blank_rule[STATEMENT_RULE_WIDTH] = "          ";
    const int32_t correct_length = STATEMENT_STATUS_WIDTH;
    const int32_t wrong_length = STATEMENT_STATUS_WIDTH - 1;
    const int32_t rule_length = STATEMENT_RULE_WIDTH;
    const int32_t wrong_rule_length = STATEMENT_RULE_WIDTH - 1;
    const int32_t zero_length = 0;
    const int32_t negative_length = -1;
    const int32_t excessive_length = INT32_MAX;
    const int64_t net_cents = 0;

    const struct {
        const char *name;
        const char *status;
        const int32_t *status_length;
        const char *rule;
        const int32_t *rule_length;
        const int64_t *amount;
    } cases[] = {
        {"null status", NULL, &correct_length, valid_rule, &rule_length, &net_cents},
        {"short status", valid_status, &wrong_length, valid_rule, &rule_length, &net_cents},
        {"invalid status text", invalid_status, &correct_length, valid_rule, &rule_length, &net_cents},
        {"null rule", valid_status, &correct_length, NULL, &rule_length, &net_cents},
        {"short rule", valid_status, &correct_length, valid_rule, &wrong_rule_length, &net_cents},
        {"invalid rule text", valid_status, &correct_length, invalid_rule, &rule_length, &net_cents},
        {"null status length", valid_status, NULL, valid_rule, &rule_length, &net_cents},
        {"null rule length", valid_status, &correct_length, valid_rule, NULL, &net_cents},
        {"null amount", valid_status, &correct_length, valid_rule, &rule_length, NULL},
        {"blank status", blank_status, &correct_length, valid_rule, &rule_length, &net_cents},
        {"blank rule", valid_status, &correct_length, blank_rule, &rule_length, &net_cents},
        {"zero status length", valid_status, &zero_length, valid_rule, &rule_length, &net_cents},
        {"negative rule length", valid_status, &correct_length, valid_rule, &negative_length, &net_cents},
        {"excessive status length", valid_status, &excessive_length, valid_rule, &rule_length, &net_cents},
        {"excessive rule length", valid_status, &correct_length, valid_rule, &excessive_length, &net_cents}
    };
    const size_t count = sizeof cases / sizeof cases[0];

    for (size_t index = 0; index < count; index++) {
        if (emit_assessment_json(
                cases[index].status,
                cases[index].status_length,
                cases[index].rule,
                cases[index].rule_length,
                cases[index].amount
            ) != 2) {
            fprintf(stderr, "FAIL: %s\n", cases[index].name);
            return 1;
        }
    }

    printf("PASS: %zu invalid-input adapter contracts.\n", count);
    return 0;
}
