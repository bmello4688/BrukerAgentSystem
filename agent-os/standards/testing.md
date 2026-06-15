# Testing Standard

## General

- Every feature agent owns the tests for its feature.
- Agents may run builds and tests freely.
- Prefer focused tests near the changed behavior.
- Run the smallest meaningful test first, then broaden when the change touches shared contracts.
- Record skipped tests and reasons in the handoff.
- Use the lightest test type that proves the behavior.

## Testing Architecture

TripleQuadUI should use layered testing:

- Unit tests for pure logic, mapping functions, validation, analysis helpers, and retry/failure handling.
- Project-level build checks for changed `.csproj` files.
- Integration tests for service behavior, gRPC/proto contracts, data services, logging, and cross-module behavior.
- Simulator validation when real hardware is unavailable and simulator behavior is relevant.
- Hardware/manual validation when behavior depends on real instruments, MS workstation integration, timing, calibration, or physical I/O.
- UI checks for user-facing analyzer workflows, accessibility, visible state, and long-running operations.
- Demo validation to show the story outcome in a human-understandable way.

## Behavior-Driven Development

BDD-style scenarios are useful when:

- Product Owner, stakeholder, Domain Analyst, User Experience, and Feature Engineer need a shared description of behavior.
- The workflow is safety-sensitive, business-critical, or easy to misunderstand.
- The scenario can double as acceptance documentation.
- The wording helps clarify examples, edge cases, states, and outcomes.

Do not use BDD for every low-level test. Unit tests, integration tests, and project builds can be clearer and cheaper for implementation detail.

## Common Commands

Use the most focused command that proves the change. Examples:

```powershell
dotnet build <path-to-project>.csproj
dotnet test <path-to-test-project>.csproj
dotnet build .\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx
```

Use `MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx` as the primary solution-level build entry point from the application Git repo root. Use broader solution-level validation when shared props, package versions, contracts, service hosts, hardware interfaces, or algorithm behavior changed.

## Cross-Project Changes

When a service, proto, hardware interface, model, or shared library change affects consumers, include:

- Contract summary.
- Compatibility impact.
- Producer-side tests or build.
- Consumer-side build or smoke check.
- Simulator or hardware validation status, when relevant.
