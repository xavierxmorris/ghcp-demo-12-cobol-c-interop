# Prompts — use Copilot to modernise the boundary, not erase the source

These prompts are designed for GitHub Copilot Chat or Copilot CLI from the
repository root.

## Prompt 1 — explain the real compilation path

```text
Read src/cobol/statement_core.cob, src/c/assessment_output.c,
include/statement_bridge.h and scripts/build-and-test.sh.

Explain this repository to a mixed COBOL/C team. Separate:
1. maintained COBOL source,
2. maintained C integration code,
3. compiler-generated C,
4. native binaries and evidence.

For every claim, cite the file and relevant symbol or command. Do not describe
generated C as migrated source, and do not propose editing anything under build/.
Finish with the one command that proves both build paths have identical
observable output.
```

**Why it works:** it forces Copilot to map ownership before recommending a
language change.

## Prompt 2 — assess a Linux replatform without promising a rewrite

```text
Act as a legacy-modernisation engineer. Read AGENTS.md first, then inspect the
COBOL/C build and tests.

Produce a replatforming assessment with:
- what this example already proves,
- what it does not prove,
- the platform dependencies a real COBOL application would need inventoried,
- an incremental strangler-style sequence that keeps COBOL as the source of
  truth while adding explicit adapters,
- the evidence required at each step.

Call out dialect, copybooks, encoding, files, databases, transaction middleware,
batch/JCL, scheduler behaviour, observability and operational recovery.
Do not generate replacement C from the COBOL and do not claim equivalence that
the tests have not measured.
```

## Prompt 3 — make a rule change safely

```text
Add a second entirely synthetic scenario whose result is REFUND.

Keep the calculation and status decision in src/cobol/statement_core.cob.
Keep src/c/assessment_output.c adapter-only: it may validate and serialize, but
must not gain business values, thresholds or branching rules. Do not edit or
commit build/generated/statement_core.c; regenerate it.

Update the expected observable output and tests so both the normal COBOL build
and the generated-C build prove the new scenario. Run .\go.ps1 -Check and report
only results seen in command output.
```

**Load-bearing clauses:** *“adapter-only”*, *“regenerate it”* and *“both build
paths”*. Without them, a plausible implementation can put the new rule in the
wrong language or test only one path.

## Prompt 4 — review the ABI before expanding it

```text
Review the COBOL/C ABI declared by include/statement_bridge.h and used by
CALL "emit_assessment_json".

Identify every assumption about width, signedness, native endianness, lifetime,
text encoding, error reporting and process boundary. Then propose the smallest
change needed if this same result had to cross a process boundary.

Do not replace the in-process demo. Recommend a separate versioned serialized
contract for the cross-process case, and list the compatibility tests it needs.
```

## Prompt 5 — respond to the generated-C shortcut

```text
A stakeholder says: "GnuCOBOL already produced build/generated/statement_core.c.
Change the formula there and make that our new source."

Read the repo instructions and respond as the Legacy Modernizer. Do not make the
change. Explain exactly why it is unsafe, identify the correct source file,
name the tests that must change, and give a reviewable implementation sequence.
```

That last prompt is what `.\go.ps1 -Live` runs, with output isolated under
`workshop-live/`.
