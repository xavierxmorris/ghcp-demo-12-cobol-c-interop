# AGENTS.md

Fictional COBOL/C interoperability demo. Nothing here is an ATO service or tax
logic; all values are synthetic.

## Architecture

```text
COBOL business rule -> explicit C ABI -> JSON adapter
        |
        +-> GnuCOBOL-generated C under build/ (artifact, never source)
```

## Commands

```powershell
.\go.ps1 -Check
```

On Linux with GnuCOBOL and GCC installed:

```bash
bash scripts/build-and-test.sh
```

## Rules

1. `src/cobol/statement_core.cob` owns calculations and status decisions.
2. `src/c/assessment_output.c` validates and serializes only. No business
   thresholds, formula constants or duplicated decisions.
3. Never edit or commit anything under `build/`.
4. ABI changes update the COBOL call, `include/statement_bridge.h`, C adapter
   and tests together.
5. Use synthetic data only. Never add real taxpayer identifiers or records.
6. Run both build paths, the signed 64-bit ABI probe and the regression guard
   before finishing.
7. Report only versions, counts and results observed in command output.
