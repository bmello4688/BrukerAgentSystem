# RC Collection, Readiness, Recovery, And Persistence Plan

This document is local Agent OS planning material. Keep it outside the Bruker Detection TripleQuadUI Git repo.

## Triad Decision

BL-016 is development-ready as a split workflow story, not as one large branch.

Coordinator Architect, Domain Analyst, and User Experience agree to split the work so the first branch removes the current simulator/core blocker before broader workflow and recall work starts. The first slice is also the smallest route for the BL-015 service E2E blocker.

## Split

### BL-016A: Confidence-Check Recovery And Persistence Unblock

Branch: `feature/rc-confidence-check-recovery-persistence`

Goal: after confidence-check analysis, simulator swab removal must either advance the core/UI out of `WaitingForSwabRemoval` into cleardown/recovery/completion, or expose a clear recoverable fault such as swab removal not confirmed with an operator next action.

Scope:

- Fix or validate post-analysis simulator/core state propagation after `RemoveSampleAsync(false)` succeeds.
- Ensure the core observes the expected open/empty instrument state or fails into a recoverable operator-visible status.
- Persist the completed confidence-check sample data when the workflow completes.
- Preserve DHS-GUI-compatible semantics unless a defect is documented for review.
- Add minimal UI status/substatus text only where needed to make pass/fail/recovery visible.

Candidate source areas:

- `MrmEtdMassSpecAnalyzer/CoreLogicLayer/SubstanceAnalyzerCore.Service`
- `MrmEtdMassSpecAnalyzer/HardwareLayer/TripleQuadHardware.Service`
- `MrmEtdMassSpecAnalyzer/InstrumentCommunication.Service.Sim`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.MicroServices.Host`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer` only if UI status evidence requires it
- `Tests/EndToEnd/MrmEtdMassSpecAnalyzer.EndToEndTests`

Do not change algorithms, classifier thresholds, Python packages, substance library behavior, production service installation, or direct DataService ownership. DataService remains accessed through `SubstanceAnalyzerCore.Service`.

Acceptance evidence:

- Confidence-check sequence reaches analysis scans, remove-swab prompt, simulator remove, then leaves `WaitingForSwabRemoval`.
- If removal cannot be confirmed, UI/service exposes a clear recoverable state with cause and next action.
- Confidence-check pass/fail is visible to the reviewer/operator, not only logs.
- Completed confidence-check sample persistence is proven with metadata, confidence-check flag where applicable, detection output, and scan data.
- Evidence is labeled simulator-only RC validation.

Validation:

- Focused builds for touched core, hardware, simulator, microservice host, and UI projects.
- Focused tests for touched service layers.
- `RUN_BRUKER_SERVICE_E2E_TESTS=true dotnet test Tests\EndToEnd\MrmEtdMassSpecAnalyzer.EndToEndTests\MrmEtdMassSpecAnalyzer.EndToEndTests.csproj --filter "FullyQualifiedName~MicroServicesHarnessTests" --logger "console;verbosity=minimal"`
- Rerun the RC dev launch smoke if launch/runtime configuration changes.

### BL-016B: Login, Readiness, Normal Collection, And Persistence

Status: done. Reviewer Integration approved `feature/rc-normal-collection-readiness-persistence` at `8b386f8` on 2026-06-11; the approved changes were fast-forward merged into local `master`.

Recommended branch/worktree:

- `feature/rc-normal-collection-readiness-persistence`
- `C:\Git\Commercial\MrmETDSpec\worktrees\rc-normal-collection-readiness-persistence`

Scope:

- Login visibly gates the RC workflow.
- Simulator wake/readiness shows connecting/waking, waiting for instrument, verify calibration/confidence check required, and ready.
- Normal non-confidence sample collection completes through insert swab, baseline progress, analysis progress, cleardown/analyzing, remove swab, completion, and return to usable state.
- Persist normal simulator sample data with metadata, detection output, and scan data.

Acceptance evidence:

- Operator cannot enter the RC workflow before login.
- Startup/wake/readiness path reaches a clear ready state after confidence-check readiness has passed.
- Normal non-confidence sample path uses simulator MRM data, inserts swab, collects baseline/analysis scans, prompts for removal, leaves waiting-for-removal, completes, and returns to a usable state.
- Persisted normal sample metadata can be listed and includes sample id/sample number/timestamps or equivalent identifying metadata.
- Persisted normal sample scan data can be loaded enough to prove the sample is graphable/reanalysis-ready.
- Detection output is visible enough for RC reviewer evidence, or no-detection/blank behavior is explicitly documented as expected for the chosen simulator substance.
- Evidence is labeled simulator-only RC validation.

Validation:

```powershell
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.MicroServices.Host\MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj" --no-restore
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.csproj" -f net10.0-desktop --no-restore
$env:RUN_BRUKER_SERVICE_E2E_TESTS="true"
dotnet test "Tests\EndToEnd\MrmEtdMassSpecAnalyzer.EndToEndTests\MrmEtdMassSpecAnalyzer.EndToEndTests.csproj" --filter "FullyQualifiedName~MicroServicesHarnessTests" --logger "console;verbosity=minimal"
powershell -ExecutionPolicy Bypass -File "scripts\launch-rc-dev.ps1" -NoBuild -StopAfterReady -StartupTimeoutSeconds 90
```

Reviewer focus:

- Do not regress BL-016A confidence-check recovery/persistence.
- Do not introduce direct UI/simulator DataService access; persistence remains behind `SubstanceAnalyzerCore.Service`.
- Keep broad history clear/export/filtering in BL-018.

### BL-016C: Fault Recovery And Minimal Recall

Status: released to Feature Engineering after BL-016B was merged into local `master` at `8b386f8`.

Recommended branch/worktree:

- `feature/rc-fault-recovery-minimal-recall`
- `C:\Git\Commercial\MrmETDSpec\worktrees\rc-fault-recovery-minimal-recall`

Scope:

- Failed calibration, confidence-check retry, not-ready, and recovery-to-usable states show cause and next action.
- A just-created simulator sample can be selected, recalled, graph-loaded, and reanalyzed enough to prove persistence.
- Broad history clear/export/archive migration/filtering remains BL-018.

Acceptance evidence:

- Failed calibration/confidence-check failure shows a clear cause and next action.
- Operator can retry confidence check and recover to a usable ready/collection state through simulator validation.
- Not-ready or fault state shows operator-facing status text and does not leave the workflow ambiguous.
- A simulator-created sample from the current RC flow can be selected/recalled.
- Recall path loads enough scan data for graph display or equivalent proof.
- Reanalysis of the recalled sample returns a meaningful result or documented expected no-detection output.
- Evidence is labeled simulator-only RC validation.

Validation:

```powershell
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.MicroServices.Host\MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj" --no-restore
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.csproj" -f net10.0-desktop --no-restore
$env:RUN_BRUKER_SERVICE_E2E_TESTS="true"
dotnet test "Tests\EndToEnd\MrmEtdMassSpecAnalyzer.EndToEndTests\MrmEtdMassSpecAnalyzer.EndToEndTests.csproj" --filter "FullyQualifiedName~MicroServicesHarnessTests" --logger "console;verbosity=minimal"
```

Reviewer focus:

- Minimal recall only; do not implement broad history clear/export/archive migration here.
- Preserve DHS-GUI-compatible recovery semantics unless a defect is documented for owner review.
- Ensure any UI wording/status change gives a next action and does not hide hardware/simulator fault state.

## Reviewer Integration Focus

- Confirm BL-016A did not mask the remove-swab timeout by only extending timeouts.
- Confirm hardware-facing semantics are preserved or the defect is documented.
- Confirm simulator-only evidence is clearly separated from hardware/manual validation.
- Confirm no direct UI/simulator DataService launch/access path was introduced.

## Risks

- `WaitingForSwabRemoval` may be in simulator state propagation, core collector state machine, hardware service status translation, or E2E harness timing; Feature Engineering should diagnose before changing UI wording.
- UI work may be required if service completion is correct but operator evidence is not visible.
- Persistence proof may expose DataService/repository gaps; keep changes behind the core service boundary.

## BL-016A Feature Engineering Evidence - 2026-06-11

Branch/worktree:

- `feature/rc-confidence-check-recovery-persistence`
- Baseline local RC `master` commit: `d716ddc`

Implementation summary:

- Fixed hardware-facing swab-clamp state translation in `HardwareLayer/Msws/Hardware.Instrument.MrmEtd/DesorberDeviceManager.cs`.
  - Device-status changes now re-evaluate swab clamp state, not only generic system-status changes.
  - `ClosedWithSwab` now recovers to `OpenAndEmpty` when the swab-present hardware bit is false and scanning/must-remove warnings are cleared. This covers the simulator/core race where `RemoveSampleAsync(false)` can clear the swab before the service observes the intermediate `SwabNeedsToBeRemoved` state.
- Fixed invalid JSON in `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.MicroServices.Host/Properties/launchSettings.json` by removing the trailing comma after `environmentVariables`. This is required for `dotnet run --project ... --no-build` launch paths used by the E2E harness.
- Strengthened `Tests/EndToEnd/MrmEtdMassSpecAnalyzer.EndToEndTests/MicroServicesHarnessTests.cs` to prove persisted confidence-check sample id, sample number, stored analysis scan count, graphable scan data, and reanalysis output.

Boundary notes:

- No algorithm, classifier threshold, Python package/runtime, substance library, production service installation, direct DataService access, broad history, export, archive, or UI workflow changes.
- DataService remains accessed behind `SubstanceAnalyzerCore.Service`.
- Evidence is simulator-only RC validation.

Validation results:

```powershell
dotnet restore "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx"
# Passed with existing BL-013 allowlisted package warnings.

dotnet build "HardwareLayer\Msws\Hardware.Instrument.MrmEtd\Hardware.Instrument.MrmEtd.csproj" --no-restore
# Passed: 0 warnings, 0 errors.

dotnet build "HardwareLayer\Msws\Hardware.Instrument.MrmEtd.Communication.Service.Sim\Hardware.Instrument.MrmEtd.Communication.Service.Sim.csproj" --no-restore
# Passed: 0 warnings, 0 errors.

dotnet build "CoreLogicLayer\SubstanceAnalyzerCore.Service\SubstanceAnalyzerCore.Service.csproj" --no-restore
# Passed: 0 warnings, 0 errors.

dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.MicroServices.Host\MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj" --no-restore
# Passed: 577 warnings, 0 errors.

dotnet test "Tests\Integration\InstrumentCommunication.Service.Sim.IntegrationTests\InstrumentCommunication.Service.Sim.IntegrationTests.csproj" --no-restore --logger "console;verbosity=minimal"
# Passed: 1/1.

dotnet test "Tests\Integration\InstrumentCommunication.Service.IntegrationTests\InstrumentCommunication.Service.IntegrationTests.csproj" --no-restore --logger "console;verbosity=minimal"
# Passed: 1/1.

dotnet test "Tests\Integration\TripleQuadHardware.Service.IntegrationTests\TripleQuadHardware.Service.IntegrationTests.csproj" --no-restore --logger "console;verbosity=minimal"
# Passed: 6/6.

dotnet test "Tests\Integration\SubstanceAnalyzerCore.Service.IntegrationTests\SubstanceAnalyzerCore.Service.IntegrationTests.csproj" --no-restore --logger "console;verbosity=minimal"
# Passed: 6/6.

$env:RUN_BRUKER_SERVICE_E2E_TESTS="true"
dotnet test "Tests\EndToEnd\MrmEtdMassSpecAnalyzer.EndToEndTests\MrmEtdMassSpecAnalyzer.EndToEndTests.csproj" --filter "FullyQualifiedName~MicroServicesHarnessTests" --logger "console;verbosity=minimal"
# Passed after fix: 6/6. A prior rerun produced one simulator confidence-check classification miss before passing on rerun; Reviewer Integration should note E2E simulator variability separately from the original stuck WaitingForSwabRemoval blocker.

powershell -ExecutionPolicy Bypass -File "scripts\launch-rc-dev.ps1" -NoBuild -StopAfterReady -StartupTimeoutSeconds 90
# Passed: core 7042, hardware 7043, simulator 7044 reached and released.
```

Observed proof:

- Confidence-check sequence now leaves `WaitingForSwabRemoval`; simulator logs include `ClosedWithSwab` or `SwabNeedsToBeRemoved` transitions to `OpenAndEmpty`.
- Passing confidence-check recovery reaches `SampleCollecting` with success status.
- Failed confidence-check path reaches visible failed calibration state.
- Persisted confidence-check sample is found via metadata with `IsConfidenceCheck=true`.
- Persisted confidence-check sample exposes scan data through `GetCollectedSampleScanData`.
- `ReAnalyzeCollectedSample` returns `IsConfidenceCheck=true`, `PassedConfidenceCheck=true`, and `DetectionResultOverview="Confidence Check: Passed"` for the passing path.

## BL-016A Reviewer Integration Result - 2026-06-11

Reviewer Integration pre-merge review reproduced the confidence-check recovery/persistence validation on branch `feature/rc-confidence-check-recovery-persistence`, commit `01c5e2d`.

Findings:

- No blocking code findings.
- The branch is committed and clean in the review worktree.
- App repo secrecy/doc placement check is clean.
- DataService access remains behind `SubstanceAnalyzerCore.Service`; no direct UI or simulator DataService path was introduced.
- The hardware-facing swab-clamp translation change is acceptable as a documented simulator/core recovery bug fix: simulator `RemoveSwab` clears `SWB_DETECT_inner`, scanning, scanning-started, and must-remove status bits; `DesorberDeviceManager` now recomputes clamp state on device-status changes and can advance `ClosedWithSwab` to `OpenAndEmpty` when all swab/scanning/remove indicators are clear.
- This is simulator-only RC validation. Real hardware/manual confirmation remains separate.

Reviewer validation:

```powershell
dotnet restore "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx"
dotnet build "HardwareLayer\Msws\Hardware.Instrument.MrmEtd\Hardware.Instrument.MrmEtd.csproj" --no-restore
dotnet build "HardwareLayer\Msws\Hardware.Instrument.MrmEtd.Communication.Service.Sim\Hardware.Instrument.MrmEtd.Communication.Service.Sim.csproj" --no-restore
dotnet build "CoreLogicLayer\SubstanceAnalyzerCore.Service\SubstanceAnalyzerCore.Service.csproj" --no-restore
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.MicroServices.Host\MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj" --no-restore
dotnet test "Tests\Integration\InstrumentCommunication.Service.Sim.IntegrationTests\InstrumentCommunication.Service.Sim.IntegrationTests.csproj" --no-restore --logger "console;verbosity=minimal"
dotnet test "Tests\Integration\InstrumentCommunication.Service.IntegrationTests\InstrumentCommunication.Service.IntegrationTests.csproj" --no-restore --logger "console;verbosity=minimal"
dotnet test "Tests\Integration\TripleQuadHardware.Service.IntegrationTests\TripleQuadHardware.Service.IntegrationTests.csproj" --no-restore --logger "console;verbosity=minimal"
dotnet test "Tests\Integration\SubstanceAnalyzerCore.Service.IntegrationTests\SubstanceAnalyzerCore.Service.IntegrationTests.csproj" --no-restore --logger "console;verbosity=minimal"
$env:RUN_BRUKER_SERVICE_E2E_TESTS="true"
dotnet test "Tests\EndToEnd\MrmEtdMassSpecAnalyzer.EndToEndTests\MrmEtdMassSpecAnalyzer.EndToEndTests.csproj" --filter "FullyQualifiedName~MicroServicesHarnessTests" --logger "console;verbosity=minimal"
powershell -ExecutionPolicy Bypass -File "scripts\launch-rc-dev.ps1" -NoBuild -StopAfterReady -StartupTimeoutSeconds 90
```

Reviewer observed:

- Restore passed with known BL-013 package warnings.
- Focused builds passed with `0 Error(s)`. Warning counts varied by build/incremental state and remain existing warning debt.
- Integration tests passed: simulator comms `1/1`, instrument comms `1/1`, hardware service `6/6`, core service `6/6`.
- `MicroServicesHarnessTests` passed `6/6`; the previous `WaitingForSwabRemoval` timeout did not reproduce.
- RC launch smoke reached ports `7042`, `7043`, and `7044`, then released them cleanly.

## BL-016B Feature Engineering Evidence - 2026-06-11

Branch/worktree:

- `feature/rc-normal-collection-readiness-persistence`
- `C:\Git\Commercial\MrmETDSpec\worktrees\rc-normal-collection-readiness-persistence`
- Baseline local RC `master` commit: `01c5e2d`

Implementation summary:

- Added a simulator-only normal collection proof to `Tests/EndToEnd/MrmEtdMassSpecAnalyzer.EndToEndTests/MicroServicesHarnessTests.cs`.
  - The new test wakes the simulator-backed instrument, passes confidence-check readiness first, confirms the collector is ready for normal collection, switches to the normal `Blank` simulator substance where available, inserts the swab, observes baseline and analysis progress, stops analysis, removes the swab, confirms the collector leaves `WaitingForSwabRemoval`, and returns to a ready usable collection state.
  - The test proves normal sample persistence through `SubstanceAnalyzerCore.Service` by listing newly persisted metadata, verifying id/sample number/timestamp/display name, loading persisted scan data with analysis scans and graphable series, and reanalyzing the persisted sample.
- Generalized the collected-sample metadata timeout message so failures distinguish confidence-check and normal persisted sample counts.

Boundary notes:

- No algorithm, classifier threshold, Python package/runtime, substance library, production service installation, launch configuration, direct DataService access, broad history, export, archive, or UI source changes.
- DataService remains accessed behind `SubstanceAnalyzerCore.Service`.
- Login gate/readiness UI evidence is code/build evidence for this slice: `AppPage` defaults to `Login`, `LoginPage` exposes the login form/button, and `AppModel` already maps connecting/waiting/verify-calibration/ready/collection/remove-swab states. This branch did not change those surfaces.
- Evidence is simulator-only RC validation.

Validation results:

```powershell
dotnet build "Tests\EndToEnd\MrmEtdMassSpecAnalyzer.EndToEndTests\MrmEtdMassSpecAnalyzer.EndToEndTests.csproj" --no-restore
# Passed: 0 warnings, 0 errors.

dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.MicroServices.Host\MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj" --no-restore
# Passed: 577 warnings, 0 errors.

$env:RUN_BRUKER_SERVICE_E2E_TESTS="true"
dotnet test "Tests\EndToEnd\MrmEtdMassSpecAnalyzer.EndToEndTests\MrmEtdMassSpecAnalyzer.EndToEndTests.csproj" --no-build --filter "FullyQualifiedName~MicroServicesHarnessTests" --logger "console;verbosity=minimal"
# Passed: 7/7.

dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.csproj" -f net10.0-desktop --no-restore
# Passed: 43 warnings, 0 errors. Includes known BL-013 vulnerability warnings for SharpCompress, Snappier, and Tmds.DBus.Protocol plus existing nullability warnings.
```

Observed proof:

- Confidence-check readiness still passes before normal collection and BL-016A recovery remains covered in the same harness run.
- Normal simulator MRM collection reaches ready, inserts a swab, collects baseline and analysis scans, enters remove-swab handling, accepts simulator removal, leaves `WaitingForSwabRemoval`, and returns to ready `SampleCollecting`.
- Persisted normal sample metadata is found with `IsConfidenceCheck=false`, id, sample number, timestamp, and display name.
- Persisted normal sample scan data exposes analysis scans and graphable time/spectrum data.
- `ReAnalyzeCollectedSample` returns `IsConfidenceCheck=false` with a non-empty `DetectionResultOverview`.

Notes:

- An initial attempted E2E run before building the microservice host in the fresh worktree failed with simulator port `7044` unavailable because the harness launches the host with `dotnet run --no-build`. After building the host, the required gated harness passed.
- RC dev launch smoke was not rerun for BL-016B because no runtime/launch configuration changed.

## BL-016C Feature Engineering Evidence - 2026-06-11

Branch/worktree:

- `feature/rc-fault-recovery-minimal-recall`
- `C:\Git\Commercial\MrmETDSpec\worktrees\rc-fault-recovery-minimal-recall`
- Baseline local RC `master` commit: `8b386f8`

Implementation summary:

- Strengthened simulator-only fault/recovery assertions in `Tests/EndToEnd/MrmEtdMassSpecAnalyzer.EndToEndTests/MicroServicesHarnessTests.cs`.
  - Failed confidence-check calibration now asserts the actionable retry state explicitly: `CollectionState=VerifyCalibration`, `CollectorState=CollectingBaseline`, `LatestFault=FailedCalibration`, `IsInFaultMode=true`, `IsRunningConfidenceCheck=true`, and `ReadyToCollectSample=true`.
  - Retry/recovery path still changes to the passing confidence-check substance, reruns confidence check, and returns to usable `SampleCollecting` with success service status.
  - Recall proof now reselects the persisted sample by id from metadata before graph-loading scan data and reanalyzing it, for both confidence-check and normal persisted samples.
  - E2E collector-state polling was extended from 25 seconds to 45 seconds to tolerate simulator cleardown-to-ready timing variance observed during validation; no production timeout or runtime behavior changed.

Boundary notes:

- No production source behavior changes.
- No algorithm, classifier threshold, Python package/runtime, substance library, hardware-facing semantics, production service installation, launch configuration, direct DataService access, broad history, export, archive, or UI source changes.
- DataService remains accessed behind `SubstanceAnalyzerCore.Service`.
- Operator-facing text evidence is code/build evidence for this slice: `AppModel` maps `FailedCalibration` plus `VerifyCalibration` into `Verify calibration`, `Failed calibration`, and `Run diagnostics or rerun confidence check`; the service E2E proves the underlying collector state that drives that UI mapping.
- Evidence is simulator-only RC validation.

Validation results:

```powershell
dotnet restore "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx"
# Passed with known BL-013 package warnings.

dotnet build "Tests\EndToEnd\MrmEtdMassSpecAnalyzer.EndToEndTests\MrmEtdMassSpecAnalyzer.EndToEndTests.csproj" --no-restore
# Passed: 0 warnings, 0 errors.

dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.MicroServices.Host\MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj" --no-restore
# Passed: 577 warnings, 0 errors.

$env:RUN_BRUKER_SERVICE_E2E_TESTS="true"
dotnet test "Tests\EndToEnd\MrmEtdMassSpecAnalyzer.EndToEndTests\MrmEtdMassSpecAnalyzer.EndToEndTests.csproj" --no-build --filter "FullyQualifiedName~MicroServicesHarnessTests" --logger "console;verbosity=minimal"
# Passed: 7/7.

dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.csproj" -f net10.0-desktop --no-restore
# Passed: 43 warnings, 0 errors. Includes known BL-013 vulnerability warnings for SharpCompress, Snappier, and Tmds.DBus.Protocol plus existing nullability warnings.
```

Observed proof:

- Failed confidence-check path reaches a clear service fault state with `LatestFault=FailedCalibration` while ready for the next confidence-check swab.
- The retry path reruns confidence check with the passing simulator substance and recovers to usable `SampleCollecting`.
- Just-created confidence-check and normal simulator samples can be reselected from persisted metadata by id.
- Recalled samples expose analysis scan data and graphable time/spectrum series through `GetCollectedSampleScanData`.
- Recalled samples can be reanalyzed through `ReAnalyzeCollectedSample`; confidence-check reanalysis preserves `IsConfidenceCheck=true`, and normal reanalysis preserves `IsConfidenceCheck=false` with a non-empty `DetectionResultOverview`.

Notes:

- An initial attempted E2E run before building the microservice host in the fresh worktree failed with simulator port `7044` unavailable because the harness launches the host with `dotnet run --no-build`. After building the host, the gated harness ran.
- A later harness run exposed over-strict raw `InstrumentStatus` assertions: the service reports `VerifyCalibration/Success` plus `CollectingBaseline/Success` while the collector state carries `IsInFaultMode=true` and `LatestFault=FailedCalibration`; the Uno `AppModel` uses the collector state for the operator warning/next-action text. Assertions were adjusted to the existing contract.
