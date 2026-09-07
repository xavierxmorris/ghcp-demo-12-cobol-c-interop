# Workshop: design the boundary instead of adopting generated code

**Audience:** COBOL/C developers and modernization architects.
**Time:** 60 minutes after toolchain setup.
**Outcome:** an explainable ABI contract and evidence that both build paths
exercise it. The fictional statement calculation is not tax advice.

## 1. Establish source ownership - 8 minutes

| Artifact | Owner/responsibility | Maintained? |
| --- | --- | --- |
| [statement_core.cob](src/cobol/statement_core.cob) | Calculation, status, rule identifier | Yes |
| [statement_bridge.h](include/statement_bridge.h) | Reviewed same-process ABI | Yes |
| [assessment_output.c](src/c/assessment_output.c) | Validate representation and serialize | Yes |
| `build/generated/statement_core.c` | Compiler output | No |
| [expected-result.json](tests/expected-result.json) | Independent observable example | Yes, reviewed expectation |

```text
Map the calculation and output path. Distinguish maintained C from generated C.
Identify every artifact that must change together if the ABI changes.
Do not modify generated files, business rules, or deployment settings.
```

The two executables are not independent reimplementations: both use the same
GnuCOBOL toolchain and maintained adapter. Equality is valuable build evidence,
not proof that an entire mainframe application can move unchanged.

## 2. Decode the ABI field by field - 12 minutes

Read the header and the COBOL `CALL` together:

| Value | COBOL representation | C representation | Review question |
| --- | --- | --- | --- |
| Status | `PIC X(8)` | `const char *` plus width | Space-padded, not NUL-terminated |
| Status length | `PIC S9(9) COMP-5` | `const int32_t *` | Signed native integer passed by reference |
| Rule | `PIC X(10)` | `const char *` plus width | Same fixed-field lifetime constraint |
| Rule length | `PIC S9(9) COMP-5` | `const int32_t *` | Exact expected width |
| Net cents | `PIC S9(18) COMP-5` | `const int64_t *` | Preserve sign and values beyond 32-bit range |
| Return code | Returned integer | `int` | 0 success, 2 invalid value, 3 output failure |

The adapter trims trailing padding into its own NUL-terminated buffers and
accepts a restricted token alphabet before serialization. It does not calculate
the business outcome or own the PAYABLE/REFUND threshold.

Pointers must remain valid for the call. Null/width checks do not prove that
an arbitrary non-null pointer is safe, correctly allocated, or alive.
Native-endian in-process data is not a cross-machine wire format.

**Checkpoint:** explain why changing only a C type or adding a cast is not a
complete repair for a width mismatch.

## 3. Run both build paths - 12 minutes

On Windows with Docker Desktop running:

```powershell
.\go.ps1 -Check
```

Or, inside Linux with GnuCOBOL and GCC installed:

```bash
bash scripts/build-and-test.sh
```

The build script recreates `build/`. Do not put maintained work there.
The expected sequence is adapter checks, C generation, normal build,
generated-C build, signed ABI probe, output comparisons, and ownership guard.
Read all diagnostics, not only the final success line.

Inspect these new run artifacts:

| Path | Evidence |
| --- | --- |
| `build/result-native.json` | Normal build's observable output |
| `build/result-generated.json` | Generated-C build's observable output |
| `build/result-abi-probe.json` | Positive and negative large signed values |
| `build/evidence.txt` | Actual compiler/GCC versions and hashes |
| `build/generated/` | Regenerated compiler artifacts |

The expected fictional result is `net_cents: 1450000` with status `PAYABLE`.
Calculate `(800000 - 320000) + 710000 + 260000` independently.
Do not copy the program's answer into the expectation to create agreement.

## 4. Exercise negative and large-value cases - 12 minutes

Read [adapter_contract.c](tests/adapter_contract.c) and
[abi_probe.cob](tests/abi_probe.cob).

| Case | Expected behavior |
| --- | --- |
| Null status/rule | Invalid-ABI return code, no success-shaped JSON |
| Wrong field width | Reject rather than read a different representation |
| Invalid token character | Reject |
| +5,000,000,000 cents | Positive value survives the COBOL/C boundary |
| -5,000,000,000 cents | Negative value survives; no unsigned conversion |

The current adapter test is deliberately narrow. Propose missing cases such as
other null pointer arguments, blank tokens, or output-write failure, stating
which are feasible to test with the existing harness.

```text
Add one missing adapter-contract test using the existing C test harness.
Keep business calculations in COBOL. If the test exposes a defect, fix only
the adapter representation/error behavior. Run the full two-path check.
```

For a failure drill, alter an expected width **only in an exercise-owned test**
and confirm the invalid-value path. Restore the test afterward. Never corrupt
a generated file and then present the resulting build as maintained-source work.

## 5. Challenge the tempting shortcut - 8 minutes

```text
A stakeholder asks to edit build/generated/statement_core.c and maintain it
instead of COBOL. Explain why that is the wrong source boundary. Identify
the correct source, ABI surfaces, and tests for a legitimate change.
Do not implement the generated-C edit.
```

The shipped `-Live` runner demonstrates this challenge in a copied workspace
and compares source hashes, but it grants all tools. A copied directory and
instructions are not a security sandbox. For normal learning, use an
interactive approval-based session in a disposable clone.

The source-ownership guard checks recognizable shipped values/patterns. It
cannot prove that every future business decision stays out of C; human review
and behavior tests are still required.

## 6. Handoff and production assessment - 8 minutes

Keep the ABI table, compiler/build versions, three outputs, test logs, and
the generated-artifact explanation. Separate the claims:

| Claim | Evidence available here |
| --- | --- |
| Both build paths emit the shipped result | Direct output comparisons |
| This signed 64-bit boundary works | The positive/negative probe |
| All business behavior is preserved | Not established by one synthetic calculation |
| Arbitrary mainframe applications are portable | Not established |

A real assessment must inventory encodings, packed decimals, indexed files,
copybooks, calling conventions, transaction monitors, databases, jobs, and
platform dependencies. Those are extension questions, not features to add
casually to this tiny sample.

## Troubleshooting and reset

If `cobc` is unavailable on Windows, use the container path rather than
assuming it is a native compiler setup. If Docker is unreachable, fix that
prerequisite before claiming compilation. Preserve full compiler diagnostics;
do not add casts or suppress warnings to make the output green.

Rebuilding recreates `build/` from source. Keep new evidence separately if
needed and never commit generated C.

## Current sources

Checked **2026-09-07**:
[GnuCOBOL project](https://gnucobol.sourceforge.io/) lists **3.2**, released
**2023-07-28**, as the latest stable release. The demo intentionally uses its
pinned Ubuntu **3.1.2** package; report the actual run's GCC version separately.
See the README's [toolchain sources](README.md#toolchain-and-current-sources).
