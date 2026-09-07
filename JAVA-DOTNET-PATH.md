# From the COBOL/C boundary to Java or .NET

Reviewed: **7 September 2026**.

## Recommendation: wrap first, replace only with evidence

This repository is the **preserve-and-integrate** stage of modernization.
Keep `src/cobol/statement_core.cob` as the rule owner and
`src/c/assessment_output.c` as the serialization adapter. Do not translate
`build/generated/statement_core.c` into Java or C#: it is compiler output.

The next two repositories provide the replacement stages:

| Stage | Example | What to learn |
| --- | --- | --- |
| Preserve the implementation | This repository | Explicit ABI, signed widths, ownership, and observable JSON |
| Replace a small behavior | [Demo 13 Java/.NET path](https://github.com/xavierxmorris/ghcp-demo-13-modernize-legacy-cobol-app/blob/main/docs/JAVA-DOTNET-MODERNIZATION.md) | Independent Java 25 and .NET 10 ports compared with one recorded COBOL oracle |
| Handle mainframe-shaped data | [CardDemo Java/.NET path](https://github.com/xavierxmorris/azure-mainframe-modernization-carddemo/blob/main/docs/java-dotnet-modernization.md) | Shared signed-overpunch fixtures, copybook traceability, and a read-only .NET application |

Choose .NET for the existing CardDemo application unless a JVM requirement
justifies a Java host. The two-language accounting lab is a comparison and
learning tool, not a recommendation to maintain duplicate production rules.

## Run the existing boundary example

```powershell
.\go.ps1 -Check
Get-Content .\build\result-native.json
Get-Content .\build\result-abi-probe.json
```

The first output is the fictional assessment contract; the second includes
signed values beyond the 32-bit range. Its exact expected values are in
`tests/expected-result.json` and `tests/expected-abi-probe.json`.

Do not call this Java/.NET parity: neither managed-language runtime participates
in the current ABI test. Demo 13 is the runnable language-replacement example.

## Design a managed-language boundary without moving the rule

For a later, separately scoped adapter:

| Current boundary value | Java boundary type | .NET boundary type | Rule |
| --- | --- | --- | --- |
| Signed 64-bit `net_cents` | `long` | `long` | Require an integer within the signed 64-bit range; never parse through `double` |
| Status | Validated string / explicit enum | Validated string / explicit enum | Decode the status returned by COBOL; do not recalculate it |
| Rule ID | String | String | Preserve as evidence, not a second calculation implementation |
| Fixed-width text | Explicitly decoded text | Explicitly decoded text | The C pointer/length ABI is not a portable wire representation |
| Failure | Non-success process/API result | Non-success process/API result | Do not manufacture a plausible assessment from missing or invalid output |

The emitted JSON is currently an **unversioned stdout contract**, not a network
service. Before publishing it, define a versioned envelope, framing, encoding,
limits, timeouts, and error semantics without changing COBOL rule ownership.
Use the target framework's JSON parser, not regular expressions.

The process ABI is native-endian and call-lifetime-bound. JNI, Java's foreign
function APIs, or .NET P/Invoke would require an additional reviewed FFI,
runtime, and lifetime contract; they are not automatic substitutes for the
serialized boundary. A Windows process also cannot directly execute the Linux
binary produced by this container.

Do not add a network service, database, or live mainframe connection to this
tiny demo. Put such a host in a separately scoped example with its own tests.

## A useful AI task

Paste this into Copilot from this repository's root:

```text
Read AGENTS.md, include/statement_bridge.h, the COBOL CALL site, the maintained
C adapter, and both expected JSON fixtures. Map every boundary field to Java
and .NET types. Identify byte order, lifetime, signedness, error, and encoding
assumptions. Keep all calculation/status decisions in COBOL.
Propose a versioned serialized boundary as a design, not an implementation.
Do not edit generated C, add a web service, or infer mainframe portability.
Run the existing check and distinguish its build-path evidence from semantic
parity. For an executable replacement example, refer to demo 13's shared oracle.
```

The [full setup guide](https://github.com/xavierxmorris/ghcp-demo-13-modernize-legacy-cobol-app/blob/main/docs/JAVA-DOTNET-MODERNIZATION.md)
covers Linux containers, JDK 25, .NET 10, Copilot roles, and optional upgrade
tooling. A normal Copilot session can help author a bounded implementation;
the [modernization product's documented Java/.NET upgrades](https://learn.microsoft.com/azure/developer/github-copilot-app-modernization/languages)
are not a documented COBOL translation service.
