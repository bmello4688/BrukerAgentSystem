# Story Sizing Standard

Story points estimate delivery effort for AI-agent-heavy TripleQuadUI work. Points should reflect human elapsed time, token/context cost, code surface area, testing burden, integration risk, safety/security risk, hardware availability, and uncertainty.

## Scale

- 1 point: small, localized, low-risk edit with clear validation.
- 2 points: modest change in one project with focused build/test validation.
- 3 points: multi-file or cross-project change with moderate contract or test impact.
- 5 points: shared service, UI workflow, hardware/simulator, data model, or algorithm change with meaningful integration risk.
- 8 points: broad cross-project feature, unclear domain behavior, generated contracts, or hardware validation complexity.
- 13 points: too large for direct implementation; split into discovery, contract, implementation, and validation stories.

## Raise The Size For

- changes to shared props, package versions, proto contracts, generated code, appsettings, or hardware interfaces
- real hardware or internal service dependency
- unclear domain behavior
- algorithm or data-model correctness risk
- UI plus service plus hardware coordination
- limited local validation options

## Lower The Size For

- isolated tests, docs, or small fixes
- existing examples in the same project
- simulator-only behavior with clear expected output
- no shared contract impact
