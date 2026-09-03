# Run sheet — keep the COBOL, make the C boundary deliberate

**Length:** 1:25 of scripted beats inside a 90-second slot.<br>
**Command:** `.\go.ps1` or `.\go.ps1 -Manual`.

> **Say this first:** “This is a fictional ATO-style example. It is not an ATO
> service, the amounts are synthetic, and the calculation is invented.”

## 0:00 — The misconception

Open `src/cobol/statement_core.cob`.

> “GnuCOBOL translates COBOL into C. That fact often turns into a proposal:
> ‘Great, then the generated C is our modernised source.’ It is not.”

Point at `COMPUTE NET-CENTS` and the following `EVALUATE`.

> “This COBOL is still the source of truth. The rule reads like the business
> decision. That is the asset we preserve while moving the runtime.”

## 0:17 — The maintained C boundary

Open `src/c/assessment_output.c` and `include/statement_bridge.h`.

> “There is C in the architecture, but it is C we designed. The fixed ABI
> carries status, rule ID, their widths and signed 64-bit cents. The adapter
> validates them and emits JSON. It contains none of the calculation values.”

Point at `copy_token`, the null checks and the function signature.

> “That boundary is small enough to review, test and replace.”

## 0:35 — Show the compiler artifact

Open `build/generated/statement_core.c`.

> “Now here is the other C. The live evidence tells us exactly how many lines
> were generated from how many lines of COBOL. It begins by naming cobc, the
> source path, the command and the generation time, then drops immediately into
> libcob runtime structures.”

> “Useful for inspection? Yes. Something a team should hand-maintain? No.”

Quote only `source_cobol_lines` and `generated_c_lines` from the live
`build/evidence.txt`.

## 0:53 — Prove both paths

Show the terminal output from `.\go.ps1 -Check`.

> “The test builds the normal executable from COBOL plus our C adapter. Then it
> builds a second executable from the generated C plus the same adapter.”

Point at the identical JSON and the contract pass:

> “Both paths produce the same observable result. A separate COBOL probe sends
> plus and minus five billion cents across the ABI, beyond 32-bit range. And the
> narrow guard catches these shipped rule values if they migrate into maintained C.”

## 1:10 — The GitHub Copilot moment

Open `.github/copilot-instructions.md` or run `.\go.ps1 -Live`.

> “Copilot gets the same architectural contract: generated C is disposable,
> COBOL owns the rule, C owns integration, and every change proves behaviour
> before and after.”

Close with:

> “The modernisation question is not ‘Can AI rewrite this language?’ It is
> ‘Can we expose the rule safely, prove it, and move one dependency at a time?’”

## If somebody asks the hard questions

| Question | Short answer |
| --- | --- |
| “Why use GnuCOBOL 3.1.2 when 3.2 is current?” | The demo pins Ubuntu 24.04's packaged compiler for a repeatable workshop image. The README names both versions and the reason. |
| “Does generated C mean we can drop COBOL skills?” | No. Generated C preserves compiler mechanics, not business readability or maintainability. |
| “Does this prove a mainframe app will run on Linux?” | No. It proves this small, dependency-free example. Real work is usually in dialect, data encoding, files, middleware, jobs and operational semantics. |
| “Why not put the formula in C?” | Then two languages could silently own one rule. The narrow source guard detects these shipped values moving into C; architectural review and behavioural tests remain necessary for broader duplication. |
| “Could C call COBOL instead?” | Yes. GnuCOBOL exposes a runtime API for C hosts. This demo keeps one direction so the source-ownership lesson stays visible. |
| “Is COMP-5 portable over a network?” | No. It is a same-process native ABI here. Use a versioned serialized message across process or platform boundaries. |
