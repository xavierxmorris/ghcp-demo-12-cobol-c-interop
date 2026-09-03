# ghcp-demo-12 — COBOL and C, with the boundary made explicit

> **Difficulty:** ⭐⭐⭐<br>
> **Audience:** COBOL developers, C developers, modernisation leads, architects<br>
> **Length:** 90-second presenter track or a 15-minute hands-on exercise<br>
> **Prerequisite:** Docker Desktop for the container build; GnuCOBOL + GCC for a native Linux run

```powershell
.\go.ps1           # build, prove both paths, then run the presenter track
.\go.ps1 -Check    # build and test only
.\go.ps1 -Manual   # presenter controls each beat
```

> ### This is a fictional ATO-style demonstration
> **Activity Statement Bridge is made up.** It is not affiliated with, endorsed
> by, or representative of the Australian Taxation Office. The inputs, rule,
> result and service name are synthetic. This is not tax advice and it does not
> implement an ATO calculation.

## The one idea

> GnuCOBOL translating COBOL into C is a **compiler implementation detail**.
> It is not a reason to replace the maintained COBOL source with generated C.

This demo keeps that distinction visible:

1. [`src/cobol/statement_core.cob`](./src/cobol/statement_core.cob) owns the
   fictional calculation and status decision.
2. [`src/c/assessment_output.c`](./src/c/assessment_output.c) is deliberately
   thin maintained C. It validates the ABI values and emits JSON. This adapter
   is an intentionally designed integration seam, not a consequence of
   GnuCOBOL generating C.
3. `cobc -C` writes compiler-generated C under `build/generated/`.
4. The test builds once from COBOL and once from that generated C. Both binaries
   must emit the same result.
5. An ABI probe sends `+5,000,000,000` and `-5,000,000,000` cents from COBOL to
   C, proving the signed 64-bit path beyond the 32-bit range.
6. A narrow regression guard rejects the shipped rule ID and calculation values
   if they appear in maintained C, and rejects generated C outside `build/`.

## What the demo proves

**Build time:**

```text
src/cobol/statement_core.cob
        |
        +-- cobc -C --> build/generated/statement_core.c + companion headers
                              |
                              +-- C compiler --> translated COBOL object

src/c/assessment_output.c -- gcc --> maintained adapter object

translated COBOL object + maintained adapter object + libcob
        |
        +-- linker --> build/statement-core
```

**Runtime:**

```text
COBOL statement core
        |
        +-- CALL "emit_assessment_json" through the reviewed ABI
                |
                +--> maintained C adapter --> JSON
```

The normal executable and a second executable compiled from
`build/generated/statement_core.c` both produce:

```json
{"demo":"fictional-activity-statement-bridge","status":"PAYABLE","net_cents":1450000,"rule":"DEMO-BR-01"}
```

That equality is a build-pipeline smoke test for this synthetic behaviour. Both
paths still use the GnuCOBOL/C toolchain; they are not independent
implementations and therefore do not prove semantic equivalence by themselves.
It is also **not** a general claim that an arbitrary mainframe estate can move
to Linux unchanged.

## Why the maintained C is different from the generated C

| Maintained C adapter | Generated C |
| --- | --- |
| Human-designed integration boundary | Compiler output |
| Reviewed ABI in `include/statement_bridge.h`; status, rule ID and value all come from COBOL | Contains GnuCOBOL runtime internals |
| No calculation constants or thresholds | Contains translated COBOL constants |
| Tested directly for invalid pointers, widths and text | Re-created on every build |
| Committed | Ignored under `build/` |

The generated file even records the compiler version, build command, source
path and generation time. Hand-editing it would create an unreviewable fork
that disappears at the next compile.

## Where GitHub Copilot fits

This is a GitHub Copilot demo about **guarded modernisation**, not automatic
language conversion:

- [`.github/copilot-instructions.md`](./.github/copilot-instructions.md) defines
  source ownership and the non-negotiable boundary.
- [`AGENTS.md`](./AGENTS.md) gives coding agents the short operational contract.
- [`.github/agents/legacy-modernizer.agent.md`](./.github/agents/legacy-modernizer.agent.md)
  provides a project-scoped **Legacy Modernizer** agent.
- [`.github/prompts/replatform-without-rewrite.prompt.md`](./.github/prompts/replatform-without-rewrite.prompt.md)
  is a reusable assessment prompt.
- [`PROMPTS.md`](./PROMPTS.md) contains the copy-paste workshop prompts.

The high-value Copilot task is not *"translate this COBOL to C."* GnuCOBOL
already does that. It is:

> Map the rule ownership, make the C boundary explicit, generate tests around
> observable behaviour, and identify platform dependencies before changing the
> language.

## Run it

### Windows: version-controlled container build

```powershell
.\go.ps1 -Check
```

The runner builds the toolchain image, bind-mounts the repository, generates C,
builds both executables and runs all checks. Live evidence is written to:

```text
build/evidence.txt
build/result-native.json
build/result-generated.json
build/result-abi-probe.json
build/generated/statement_core.c
```

### Linux: installed toolchain

With `cobc`, `gcc` and Bash on `PATH`:

```bash
bash scripts/build-and-test.sh
```

### Presenter and workshop modes

| Command | Purpose |
| --- | --- |
| `.\go.ps1` | Build, then run the timed 90-second track. |
| `.\go.ps1 -Manual` | Advance each beat with Enter. |
| `.\go.ps1 -NoBrowser` | Keep the entire presentation in the terminal instead of opening VS Code. |
| `.\go.ps1 -Check` | Build and test, CI-style. |
| `.\go.ps1 -Live` | Run the generated-C guardrail challenge inside an isolated copy under `workshop-live/`; hashes verify the source tree stayed unchanged. |

## Toolchain and current sources

Checked **3 September 2026**:

| Item | Version/date used or observed | Source |
| --- | --- | --- |
| Current release named by the GnuCOBOL project | **GnuCOBOL 3.2**, released **28 July 2023** | <https://gnucobol.sourceforge.io/> |
| Demo compiler | **GnuCOBOL 3.1.2.0**, Ubuntu package `gnucobol3 3.1.2-5.1ubuntu1` | <https://packages.ubuntu.com/noble/gnucobol3> |
| Compiler guide | GnuCOBOL manuals and 3.2 guides | <https://gnucobol.sourceforge.io/guides.html> |
| C interaction reference | Project-hosted GnuCOBOL C-Interaction guide | <https://svn.code.sf.net/p/gnucobol/code/external-doc/GnuCOBOL_C_Interaction.pdf> |
| Container base | Ubuntu 24.04, pinned by digest in `Dockerfile` | <https://hub.docker.com/_/ubuntu> |

The base image digest and GnuCOBOL package are pinned. Ubuntu's package
repositories and the `gcc` dependency remain mutable, so the exact GCC version
is captured in every run rather than described as immutable. The container uses
Ubuntu 24.04's supported package instead of building 3.2 from source during
every workshop.

## Honesty notes

- GnuCOBOL really does translate COBOL to C and invoke a C toolchain. Debian's
  [package description](https://packages.debian.org/bookworm/gnucobol3) states
  this directly, and `cobc -C` makes the artifact visible.
- This tiny program has no indexed files, EBCDIC conversion, database, CICS,
  JCL, vendor extensions or external copybook estate. Those are often the
  difficult parts of a real replatform.
- The equivalence check covers the shipped synthetic case and the adapter
  contract. It does not prove semantic equivalence for an unseen application.
- The same-process ABI is explicit: 8-bit validated text, fixed space-padded
  widths, native-endian signed 32/64-bit integers, call-lifetime pointers and
  integer return codes. The probe covers positive and negative values beyond
  the 32-bit range. A cross-process or cross-platform API should still use a
  versioned serialized contract instead.
- Generated C is useful for inspection, debugging and understanding the
  toolchain. It is still not the maintained source.
- The regression guard catches the shipped values moving into `src/c/`; it
  cannot prove architectural ownership by itself. Review plus behavioural tests
  remain necessary.

## Repository layout

| Path | Purpose |
| --- | --- |
| `src/cobol/statement_core.cob` | Fictional business calculation and status |
| `src/c/assessment_output.c` | Maintained JSON adapter |
| `include/statement_bridge.h` | Explicit COBOL/C ABI |
| `tests/adapter_contract.c` | Invalid-input checks for the C boundary |
| `tests/abi_probe.cob` | Signed 64-bit COBOL-to-C probe |
| `tests/expected-result.json` | Observable integration result |
| `scripts/build-and-test.sh` | Generate, build, compare and run the regression guard |
| `go.ps1` | One-command Windows runner and presenter track |
| [`iteration/reference-run.txt`](./iteration/reference-run.txt) | Captured reference evidence |

Presenter wording is in [`RUN-SHEET.md`](./RUN-SHEET.md).
