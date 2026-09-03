#include "statement_bridge.h"

#include <inttypes.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

static int copy_token(
    char *destination,
    size_t destination_size,
    const char *source,
    int32_t source_size
)
{
    size_t end = (size_t)source_size;

    if (source_size <= 0 || (size_t)source_size >= destination_size) {
        return 2;
    }

    memcpy(destination, source, (size_t)source_size);
    while (end > 0 && destination[end - 1] == ' ') {
        end--;
    }
    destination[end] = '\0';

    if (end == 0) {
        return 2;
    }

    for (size_t index = 0; index < end; index++) {
        const char character = destination[index];
        const int uppercase = character >= 'A' && character <= 'Z';
        const int digit = character >= '0' && character <= '9';
        if (!uppercase && !digit && character != '-') {
            return 2;
        }
    }

    return 0;
}

int emit_assessment_json(
    const char *status,
    const int32_t *status_length,
    const char *rule,
    const int32_t *rule_length,
    const int64_t *net_cents
)
{
    char clean_status[STATEMENT_STATUS_WIDTH + 1];
    char clean_rule[STATEMENT_RULE_WIDTH + 1];

    if (
        status == NULL ||
        status_length == NULL ||
        rule == NULL ||
        rule_length == NULL ||
        net_cents == NULL
    ) {
        return 2;
    }
    if (
        *status_length != STATEMENT_STATUS_WIDTH ||
        *rule_length != STATEMENT_RULE_WIDTH
    ) {
        return 2;
    }
    if (
        copy_token(
            clean_status,
            sizeof clean_status,
            status,
            *status_length
        ) != 0
    ) {
        return 2;
    }
    if (
        copy_token(
            clean_rule,
            sizeof clean_rule,
            rule,
            *rule_length
        ) != 0
    ) {
        return 2;
    }

    if (printf(
            "{\"demo\":\"fictional-activity-statement-bridge\","
            "\"status\":\"%s\","
            "\"net_cents\":%" PRId64 ","
            "\"rule\":\"%s\"}\n",
            clean_status,
            *net_cents,
            clean_rule
        ) < 0) {
        return 3;
    }

    return fflush(stdout) == 0 ? 0 : 3;
}
