---
mode: agent
description: Assess a COBOL workload for incremental Linux replatforming without treating generated C as source.
---

Read `AGENTS.md`, `.github/copilot-instructions.md`, the COBOL/C sources and the
build script.

Assess this workload for incremental Linux replatforming:

1. Map each business decision to its maintained source.
2. Map each platform dependency and interoperability boundary.
3. Separate what the current executable tests prove from what remains unknown.
4. Propose the smallest first migration slice with rollback and equivalence
   evidence.
5. Identify the ABI, encoding, numeric and operational assumptions that need
   explicit tests.

Do not edit or recommend maintaining `build/generated/*.c`. Do not rewrite the
COBOL into C. Prefer adapters around stable COBOL capability, then replace a
component only when behavioural evidence makes that change reviewable.
