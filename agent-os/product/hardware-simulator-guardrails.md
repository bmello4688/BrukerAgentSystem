# TripleQuadUI Hardware And Simulator Guardrails

This is the BL-004 local reference. It defines how feature work should handle hardware, simulator, instrument, and MS workstation behavior. Keep this file outside the Bruker Detection Git repo.

## Hardware-Facing Areas

- `HardwareLayer/TripleQuadHardwareInstrument`
  - Shared instrument and hardware models.
  - Proto contracts: `Protos/instrumentCommon.proto`, `Protos/instrumentHardware.proto`.
- `HardwareLayer/TripleQuadHardware.Client`
  - App-facing gRPC client for instrument state and commands.
- `HardwareLayer/TripleQuadHardware.Service`
  - Higher-level hardware service.
  - Proto contract: `Protos/tripleQuadHardware.proto`.
  - Entry points: `Program.cs`, `ServiceHost.cs`, `TripleQuadHardwareService`, `TripleQuadHardwareBackgroundService`.
- `HardwareLayer/Hardware.Interface.Desorber`
  - Desorber interface boundary.
- `HardwareLayer/Msws/Hardware.Interface.MsWorkstation`
  - MS workstation integration, settings, sensor/readback integration.
- `HardwareLayer/Msws/Hardware.Instrument.MrmEtd`
  - Instrument implementation that composes desorber, MS workstation, and communication client.
- `HardwareLayer/Msws/Hardware.Instrument.MrmEtd.Communication.Service`
  - Instrument communication service.
  - Proto contract: `Protos/instrumentCommunicator.proto`.
- `CommonLibraries/Services/MsWorkstationLog`
  - MS workstation log service/client.
  - Proto contract: `MsWorkstationLog.proto`.

## Simulator Areas

- `HardwareLayer/Msws/Hardware.Instrument.MrmEtd.Communication.Service.Sim`
  - Simulator service and simulator-control service.
  - Proto contract: `Services/instrumentSimulator.proto`.
  - Resources: `Resources/fullscan-data.json`, `Resources/DefaultSensorReadbacks.json`.
- `HardwareLayer/Simulator.App`
  - Windows simulator UI app.
- `Tests/Integration/InstrumentCommunication.Service.Sim.IntegrationTests`
  - Simulator service integration tests.
- `Tests/EndToEnd/MrmEtdMassSpecAnalyzer.EndToEndTests`
  - Cross-boundary E2E tests that reference simulator, core, hardware, and UI contracts.

## Service Contracts And Configuration Hotspots

Coordinate any changes to:

- `sampleCollectionService.proto`
- `tripleQuadHardware.proto`
- `instrumentCommon.proto`
- `instrumentHardware.proto`
- `instrumentCommunicator.proto`
- `instrumentSimulator.proto`
- `samples_grpc.proto`
- `samples_grpc_data.proto`
- `MsWorkstationLog.proto`
- All checked-in `appsettings*.json`.
- All checked-in `Properties/launchSettings.json`.
- `ServiceHost.cs` files for core, hardware, instrument communication, simulator, DataService, and MsWorkstationLog.
- Generated code under `bin/`, `obj/`, protobuf output, NuGet-generated props/targets, and static-web-asset props must not be edited directly.

## Owner Review Required

Require explicit owner, Product Owner, Coordinator Architect, or SME review before changing:

- Instrument wake, sleep, startup, shutdown, calibration, or readiness semantics.
- Swab clamp state semantics or insert/remove workflow behavior.
- Sensor/readback names, units, limits, or readiness thresholds.
- CID pressure/readback mapping, especially `CIDV_RB_PRESSURE` vs `CIDV_RB_PRES_MBAR` style naming.
- Desorber commands, door behavior, automatic/manual behavior, or safety interlocks.
- MS workstation file paths, log collection, command/write behavior, or hardware communication assumptions.
- Proto contracts consumed across UI, service, simulator, and test projects.
- Data persistence format for collected samples or archived scans.
- Algorithm or ML behavior that affects detection decisions.

## Simulator Versus Real Hardware Validation

Always label validation as one of:

- Build-only: compile/test validation with no runtime service path.
- Unit/integration local: services tested in process or with local test infrastructure.
- Simulator validation: simulator service/app drives instrument-like behavior.
- Real hardware/manual validation: actual instrument or analyzer hardware involved.

Simulator validation can prove service/UI orchestration and expected state transitions, but it does not prove:

- Real sensor values are correct.
- Real pressure/readback ranges are correct.
- Desorber hardware timing and safety interlocks are correct.
- MS workstation behavior matches deployed instrument behavior.
- Physical swab handling and operator timing are correct.

Real hardware/manual validation should be requested for stories that change hardware semantics, readiness thresholds, desorber behavior, calibration, pressure handling, or MS workstation integration.

## Known Failure Modes To Consider

- Readiness limits can come from different config roots; a simulator value can fail one limit set and pass another.
- Pressure/readback names can be easy to confuse, for example setting one CID pressure field while readiness checks another.
- Swab insert/remove may update simulator UI while TripleQuadUI state remains in baseline, verify-calibration, or not-ready states.
- Late subscribers need initial state hydration for active alarms/status; otherwise UI can miss already-active backend state.
- Core, hardware, simulator, and UI service startup order can cause false failures if clients connect before services are listening.
- DataService integration scaffold currently has a skipped test that exits nonzero because zero tests ran.
- Standalone Algorithms solution currently has Python-related blockers; do not use it as the main hardware/simulator validation gate.
- Generated local artifacts such as compressed sample/archive files can appear after tests; they should be ignored or cleaned according to repo policy, not committed.

## Guardrails For Feature Stories

- Compare DHS-GUI behavior when requirements touch instrument, status, swab, readiness, alarm, history, or data-management semantics.
- Prefer simulator validation before real hardware validation when the story can be exercised safely in simulator.
- Preserve separation between service contracts and UI wording; UI-only wording changes should not alter service semantics.
- Keep local Agent OS planning references out of `source/TripleQuadUI`.
- Include claimed files, branch/worktree, validation, and next action on the status board for any app repo implementation work.
- If a story changes shared contracts, package versions, appsettings, service hosts, or shared data models, route through Coordinator Architect and Reviewer Integration.

## Minimum Validation By Change Type

- UI-only status/alarm copy/layout: focused UI build plus simulator smoke when stateful.
- Core sample collection/status behavior: core service tests plus simulator validation.
- Hardware service/client behavior: hardware service tests plus simulator or real hardware validation depending on semantics.
- Simulator behavior: simulator service tests plus at least one consuming service/UI path.
- Proto contract changes: regenerate/build clients, run affected service/client tests, and verify E2E contract consumers.
- Data/archive changes: DataService tests plus recall/export/clear workflow smoke.
- Python/algorithm changes: focused algorithm/Python build or documented blocker, plus Domain Analyst/SME review for detection semantics.

## Follow-Up Stories

- BL-009 should use these guardrails when defining dev launch profiles and production Windows Service posture.
- BL-010 should define embedded Python/algorithm-specific guardrails.
- BL-011 and BL-012 should use these guardrails for data/history validation and simulator-vs-hardware separation.
