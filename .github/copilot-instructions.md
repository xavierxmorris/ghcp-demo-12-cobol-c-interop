# Copilot instructions

This repository demonstrates safe COBOL replatforming with GnuCOBOL and an
explicit maintained C adapter.

## Source ownership

- `src/cobol/statement_core.cob` is the source of truth for the fictional
  calculation and status.
- `src/c/assessment_output.c` is an integration adapter. It may validate the ABI
  and serialize output; it must not own or duplicate business rules.
- `build/generated/*.c` is compiler output. Never edit, review as maintained
  source, or commit it.

If asked to change generated C, refuse that implementation and redirect the
change to the COBOL source plus tests.

## Interoperability contract

The in-process ABI is declared in `include/statement_bridge.h` and mirrored by
the COBOL `CALL "emit_assessment_json"`.

Any ABI change must update all four surfaces in one change:

1. COBOL linkage/call site
2. C header
3. C implementation
4. adapter and integration tests

Do not add casts to hide a width or signedness mismatch. Do not pass pointers to
temporary storage whose lifetime is unclear.

## Safety and scope

- This is fictional and not affiliated with the ATO.
- Use synthetic values only. Never add real ABNs, TFNs, taxpayer data,
  credentials, connection strings or production extracts.
- Do not add a database, network service or mainframe dependency to make the
  sample look more realistic.
- Do not claim that this example proves a full application is portable.

## Verification

```powershell
.\go.ps1 -Check
```

The check must:

- compile the maintained C adapter with warnings as errors,
- generate C with `cobc -C`,
- build from COBOL plus C,
- build from generated C plus the same C adapter,
- compare both observable results,
- run signed 64-bit values from COBOL through the ABI,
- run the narrow source-ownership regression guard.

Never report a line count, hash, version or result that was not emitted by the
current run.
