# RC Algorithm And Embedded Python Proof

BL-015 shaping output from Product Owner on 2026-06-11. Keep this planning artifact outside the Bruker Detection `TripleQuadUI.git` repo.

## Stakeholder Goal

RC needs credible evidence that the algorithm stack and embedded Python path work for the operator workflows being demonstrated. The goal is proof, not algorithm redesign.

## Product Outcome

Before RC signoff, Brian and Reviewer Integration can see that:

- Python-backed algorithm code initializes and runs in the current Windows developer/demo environment.
- A simulator-created confidence-check sample can be classified, persisted, and re-analyzed with expected confidence-check detection output.
- Known algorithm/Python blockers are either fixed with focused validation or explicitly documented as RC blockers/deferred proof items.
- SME/manual parity review against the other application is completed or scheduled before final RC signoff.

## Current Findings

- Main solution includes `CommonLibraries/Algorithms/Algorithms.Python/Algorithms.Python.csproj`, `CommonLibraries/Algorithms/Python.Interop/Python.Interop.csproj`, and `InstallEmbeddedPython/InstallEmbeddedPython.csproj`.
- Standalone `CommonLibraries/Algorithms/Algorithms.sln` is not a reliable baseline because it references a missing `pythonnet/src/runtime/Python.Runtime.csproj` and older Python.Included projects with known build issues.
- Use the main solution and focused project builds as the proof baseline, not the standalone Algorithms solution.
- Python runtime setup is anchored by `Python.Interop.PythonInitializer`, which sets `python310.dll` and `python-3.10.0-embed-amd64`.
- Embedded Python dependency installation is anchored by `InstallEmbeddedPython/requirements.txt`, including numpy, pandas, scipy, scikit-learn, statsmodels, pmdarima, tensorflow, and related packages.
- Algorithm resources include `CommonLibraries/Algorithms/Bruker Analysis/Resources/SubstanceLibrary.json`; confidence-check substances are `2,4-DNT`, `Cocaine`, `RDX`, and `TNT`.
- Classification flows through `Bruker Analysis/Classification/BasicClassifier.cs`, `Algorithms.Python/Analyzer.cs`, and `CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleDataAnalyzer.cs`.
- Existing E2E tests in `Tests/EndToEnd/MrmEtdMassSpecAnalyzer.EndToEndTests/MicroServicesHarnessTests.cs` already exercise simulator-driven confidence-check pass/fail/recovery and re-analysis. They are gated by `RUN_BRUKER_SERVICE_E2E_TESTS=true` or `RUN_BRUKER_LIVE_INTEGRATION_TESTS=true`.
- Prior BL-006 validation exposed a Python classification failure path: `Algorithms.Python.Analyzer.GetScanSeriesAndBaselineForecastAsAPyList` hit a runtime binder/null reference before later confidence-check fixes. BL-015 should prove that the current merged `master` no longer silently degrades this path for the RC confidence-check proof.

## Prioritized Proof Lanes

### Lane 1: Build And Initialization Proof

Goal: show the algorithm/Python projects compile and embedded Python setup is reachable.

Validation commands from repo root:

```powershell
dotnet build "CommonLibraries\Algorithms\Algorithms.Python\Algorithms.Python.csproj" --no-restore
dotnet build "CommonLibraries\Algorithms\Python.Interop\Python.Interop.csproj" --no-restore
dotnet build "InstallEmbeddedPython\InstallEmbeddedPython.csproj" --no-restore
```

Optional if safe in the local environment:

```powershell
dotnet run --project "InstallEmbeddedPython\InstallEmbeddedPython.csproj"
```

Only run the installer command when Reviewer Integration accepts the local environment impact, because it may download/install Python packages.

### Lane 2: Simulator-Driven Algorithm Output Proof

Goal: prove the current RC path can produce confidence-check detection output through the service boundary.

Validation command from repo root:

```powershell
$env:RUN_BRUKER_SERVICE_E2E_TESTS="true"
dotnet test "Tests\EndToEnd\MrmEtdMassSpecAnalyzer.EndToEndTests\MrmEtdMassSpecAnalyzer.EndToEndTests.csproj" --filter "FullyQualifiedName~MicroServicesHarnessTests" --logger "console;verbosity=minimal"
```

Evidence to capture:

- Microservice host starts and exposes core, hardware, and simulator ports.
- Simulator exposes `Confidence Check` substance and accepts MRM scan type.
- Confidence-check cycle persists a new confidence-check sample.
- `ReAnalyzeCollectedSample` returns `IsConfidenceCheck=true`.
- Passing confidence-check result reports `PassedConfidenceCheck=true` and `DetectionResultOverview="Confidence Check: Passed"`.
- Failing confidence-check path returns or remains in a clear failed calibration state.
- Algorithm/Python exceptions are surfaced in logs and do not silently report a false pass.

### Lane 3: Fixture Or Known-Data Proof

Goal: provide a non-live proof using a known data file if one exists or can be safely added.

Current known candidates:

- `CommonLibraries/DataService/DataService.Tests/Scans.json`
- `CommonLibraries/DataService/DataService.Tests/SamplesMetadata.json`
- Simulator resource data under `HardwareLayer/Msws/Hardware.Instrument.MrmEtd.Communication.Service.Sim/Resources/`
- Existing confidence-check sample data produced by the E2E simulator path.

Acceptance can be met either by:

- adding a focused test around a known fixture that produces expected substance/confidence-check output, or
- documenting that no stable checked-in fixture exists yet and treating simulator-driven E2E proof as the RC proof for BL-015.

If a new fixture is added, keep it small, sanitized, deterministic, and free of customer data.

### Lane 4: SME/Parity Review

Goal: schedule or complete a manual parity review against the other application.

Evidence needed:

- Which other application/path was compared.
- Which substance or confidence-check scenario was reviewed.
- Whether output is equivalent enough for RC signoff.
- Any differences explicitly accepted by Product Owner/SME.

## Acceptance Criteria

- Focused builds for `Algorithms.Python`, `Python.Interop`, and `InstallEmbeddedPython` pass or blockers are documented.
- Python initialization/package setup assumptions are documented, including whether installer execution was run or skipped.
- Simulator-driven confidence-check proof passes through service-level E2E tests or a reviewed blocker is documented.
- At least one path proves `ReAnalyzeCollectedSample` returns confidence-check detection output from a persisted sample, or explains why that proof must move to BL-016/BL-019.
- Known fixture/data proof is either implemented or explicitly deferred with rationale.
- Algorithm/Python exceptions are observable in logs/test failures and do not silently downgrade detection workflows.
- SME/manual parity review is completed or scheduled before BL-019 final signoff.

## Triad Review Decision

Coordinator Architect, Domain Analyst, and User Experience triad review completed on 2026-06-11. BL-015 is development-ready as an evidence-first proof story after the following expectations were folded into the handoff.

- Domain posture: focused builds plus simulator E2E are the primary RC proof; fixture proof is optional/deferred unless a small sanitized deterministic test is clearly available; SME parity remains required before final RC signoff.
- UX posture: no separate UX implementation story is needed before development. Service/E2E proof is sufficient for RC only if paired with operator/reviewer-visible evidence for confidence-check state, pass/fail outcome, re-analysis, and failure visibility.
- Coordinator decision: hand to Feature Engineering as proof-first work on `feature/rc-algorithm-python-proof`. Do not change algorithm behavior, classifier thresholds, substance library content, models, or Python package/runtime versions unless a failing proof exposes a reviewed defect.
- Split trigger: if proof exposes ambiguous or incorrect confidence-check UI wording/status, split a narrow UI/status wording fix from BL-015. Suggested wording target is `Confidence Check Passed` or `Confidence Check Failed` with a clear next action such as rerun confidence check or run diagnostics.

Required operator/reviewer-visible evidence for the Feature Engineer handoff:

- Confidence-check mode is visibly active before sample insertion.
- Simulator is configured for MRM and a confidence-check substance.
- Persisted sample is marked as a confidence check.
- Re-analysis result includes `IsConfidenceCheck=true`, `PassedConfidenceCheck=true`, and `DetectionResultOverview="Confidence Check: Passed"` for a passing path.
- Failed confidence-check path leaves the workflow in a visible failed calibration or confidence-check-required state.
- Python initialization/classification exceptions appear in logs or test output and cannot silently become a passing confidence check or ordinary no-threat workflow.
- SME/parity artifact names the compared application/path, substance/scenario, expected versus actual outcome, accepted differences, and Product Owner/SME signoff or scheduled review date.

## Non-Goals

- No model retraining.
- No algorithm behavior changes unless a defect is found and explicitly reviewed.
- No package/runtime upgrades unless needed to make the RC proof run and approved by Reviewer Integration.
- No broad Python packaging redesign.
- No real hardware signoff as an RC blocker.
- No report generation or substance library management workflow.

## Blockers And Risks

- Standalone Algorithms solution is not a valid gate for BL-015 until its missing/legacy Python projects are addressed.
- Embedded Python installer may have network/package side effects; run only with reviewer-approved local environment assumptions.
- TensorFlow/scientific package installation may be slow or brittle; if needed, treat as a packaging/runtime blocker, not an algorithm correctness failure.
- Algorithm semantics are SME-sensitive. Avoid changing classifiers, thresholds, or substance library contents without explicit SME/Product Owner review.
- Simulator proof depends on BL-014 launch posture and current service E2E gating environment variables.

## Recommended Branch And Role Mix

Recommended branch:

- `feature/rc-algorithm-python-proof`

Recommended role sequence:

1. Domain Analyst: verify expected confidence-check algorithm semantics and parity target.
2. Coordinator Architect: decide whether proof is test-only, doc-only, or requires a small fixture/test change.
3. Feature Engineer: run/add focused proof and capture evidence.
4. Reviewer Integration: reproduce focused builds/E2E proof and confirm no algorithm behavior drift.
5. Bruker SME/Product Owner: approve parity evidence or documented deferral.

## Suggested Handoff

Start with evidence-only work. If all proof commands pass, do not change product code. If proof fails, isolate whether the failure is Python initialization/package setup, Python codec/fixture shape, simulator E2E orchestration, or classifier semantics before making changes.

## Feature Engineering Evidence - 2026-06-11

Worktree and branch:

- `C:\Git\Commercial\MrmETDSpec\worktrees\rc-algorithm-python-proof`
- `feature/rc-algorithm-python-proof`
- Baseline local RC `master` commit: `d716ddc`

Implementation delta:

- Fixed invalid JSON in `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.MicroServices.Host/Properties/launchSettings.json` by removing the trailing comma after the `environmentVariables` object. This was required before `dotnet run --project ... --no-build` could apply launch settings and start the backend host from the E2E harness.
- No algorithm, model, threshold, substance-library, embedded Python runtime, or Python package changes were made.

Environment setup notes:

- Submodules in the BL-015 worktree were populated from the local RC checkout because internal remote access was not available in the isolated worktree.
- `dotnet restore "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx"` passed. Existing BL-013 allowlisted transitive vulnerability warnings remain for `SharpCompress`, `Snappier`, and `Tmds.DBus.Protocol`.
- `dotnet run --project "InstallEmbeddedPython\InstallEmbeddedPython.csproj"` was not run. Installer/package side effects remain skipped pending Reviewer Integration approval.

Python initialization/package assumptions:

- `Python.Interop.PythonInitializer` sets `Runtime.Runtime.PythonDLL = "python310.dll"` and `Installer.InstallDirectory = "python-3.10.0-embed-amd64"`.
- Setup calls `Installer.SetupPython()`, optionally enables Python logging, attempts pip setup, and installs only modules explicitly passed to `SetupPythonEnvironmentAsync`.
- Requirements remain the current pinned `InstallEmbeddedPython/requirements.txt` set, including numpy, pandas, scipy, scikit-learn, statsmodels, pmdarima, and tensorflow.

Focused build results:

```powershell
dotnet build "CommonLibraries\Algorithms\Python.Interop\Python.Interop.csproj" --no-restore
# Passed: 0 warnings, 0 errors

dotnet build "InstallEmbeddedPython\InstallEmbeddedPython.csproj" --no-restore
# Passed: 0 warnings, 0 errors

dotnet build "CommonLibraries\Algorithms\Algorithms.Python\Algorithms.Python.csproj" --no-restore
# Passed: 227 warnings, 0 errors
```

The first parallel attempt hit a transient shared-output lock on `Common.dll`; after `dotnet build-server shutdown`, the sequential focused builds passed.

Backend/service evidence:

- `dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.MicroServices.Host\MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj" --no-restore` passed with existing warning debt and no errors.
- Direct backend probe after the launchSettings fix opened:
  - core service: `0.0.0.0:7042`
  - hardware service: `0.0.0.0:7043`
  - simulator comms/control service: `127.0.0.1:7044`
- Startup logs showed `SubstanceLibrary.json` and `Classifier.json` loading from `C:\ProgramData\Bruker\MRM-ETD`, 61 classifier substances copied to the substance library memory object, and the simulator generating MRM scan data for 61 compounds with 3 confidence-check substances.
- Simulator service logs showed `Instrument simulator gRPC service listening on http://127.0.0.1:7044`.

E2E proof results:

```powershell
$env:RUN_BRUKER_SERVICE_E2E_TESTS="true"
dotnet test "Tests\EndToEnd\MrmEtdMassSpecAnalyzer.EndToEndTests\MrmEtdMassSpecAnalyzer.EndToEndTests.csproj" --filter "FullyQualifiedName~MicroServicesHarnessTests" --logger "console;verbosity=minimal"
```

First run before the launchSettings fix failed 4/6 tests because the simulator control service never opened on `http://localhost:7044/`.

After the launchSettings fix and backend host build, the E2E lane reached the simulator/service proof path but remained blocked:

- Run 1 after fix: 5 passed, 1 failed. Failure: `SimulatorBackedInstrumentRecoversWhenConfidenceCheckPassesAfterFailure` timed out waiting for collector state to leave `WaitingForSwabRemoval`.
- Rerun: 5 passed, 1 failed. Failure: `SimulatorBackedInstrumentStaysNotReadyWhenConfidenceCheckFails` timed out at the same shared helper wait.
- Last observed state in both failures: `CollectionState=VerifyCalibration`, `CollectorState=WaitingForSwabRemoval`, `ReadyToCollectSample=True`, `IsRunningConfidenceCheck=True`, `IsInFaultMode=False`, `LatestFault=None`, `BaselineScans=7`, `AnalysisScans=23/23`.
- Simulator log evidence from passing cycles showed swab state transitions from `ClosedWithSwab` to `SwabNeedsToBeRemoved` to `OpenAndEmpty`. In the failing cycle, the log stopped after `OpenAndEmpty` to `ClosedWithSwab`, indicating the remaining blocker is the simulator/core post-analysis swab-removal/recovery state transition.

Evidence satisfied so far:

- Focused algorithm/Python/installer builds pass without changing algorithm or Python package behavior.
- Backend host can expose core, hardware, and simulator runtime ports after the launch profile JSON fix.
- Simulator starts in MRM-backed mode, loads resource data, and reports confidence-check substance setup.
- Algorithm/Python exceptions and service startup failures are visible in build/test/log output; failures did not silently become a pass or normal no-threat path.

Evidence still blocked:

- Full `MicroServicesHarnessTests` green run.
- Persisted confidence-check sample re-analysis proof for `IsConfidenceCheck=true`, `PassedConfidenceCheck=true`, and `DetectionResultOverview="Confidence Check: Passed"` is not yet captured from a passing `SimulatorBackedInstrumentRecoversWhenConfidenceCheckPassesAfterFailure` run.
- Final failed-confidence-check visible state remains inconclusive in the repeated run because the shared helper times out before the expected failed calibration state assertion.
- SME/manual parity artifact remains required before BL-019 final signoff.

Next recommended action:

- Reviewer Integration should reproduce the BL-015 branch with the launchSettings fix, then isolate the post-analysis `WaitingForSwabRemoval` timeout. Treat this as simulator/service E2E orchestration or recovery-state behavior until proven otherwise; do not change classifier semantics, thresholds, substance library content, or Python package/runtime versions without review.

## Coordinator Decision - 2026-06-11 13:03 EDT

BL-015 remains blocked pending Reviewer Integration triage. Current evidence does not point to an algorithm, classifier, model, substance-library, embedded Python runtime, or Python package failure:

- focused `Python.Interop`, `InstallEmbeddedPython`, and `Algorithms.Python` builds pass;
- backend host can expose core, hardware, and simulator ports after the launch settings JSON fix;
- E2E reaches simulator/service confidence-check flow and repeatedly passes 5 of 6 tests;
- the remaining failure is a shared post-analysis `WaitingForSwabRemoval` timeout in confidence-check recovery/failure paths.

Coordinator routing:

- Send the branch to Reviewer Integration to reproduce and isolate the timeout.
- Treat the blocker as simulator/core collection-recovery workflow until proven otherwise.
- Do not continue Feature Engineering changes in algorithm/Python areas unless Reviewer Integration identifies a specific BL-015 defect.
- If Reviewer Integration confirms this is collection/recovery behavior rather than algorithm/Python proof, split or route the fix into BL-016 while keeping BL-015 as partial proof evidence plus documented blocker.

## Reviewer Integration Triage - 2026-06-11

Reproduced from branch `feature/rc-algorithm-python-proof` with the uncommitted `launchSettings.json` trailing-comma fix applied.

- `Python.Interop`, `InstallEmbeddedPython`, and `Algorithms.Python` focused builds passed with `0 Warning(s)` and `0 Error(s)` in the review run.
- `MrmEtdMassSpecAnalyzer.MicroServices.Host` focused build passed with `0 Warning(s)` and `0 Error(s)` in the review run.
- Embedded Python installer execution remained skipped to avoid package/environment side effects.
- Gated `MicroServicesHarnessTests` reproduced the blocker: `4` passed, `2` failed.
- Failed tests were `SimulatorBackedInstrumentWakesAndPassesConfidenceCheckBeforeReady` and `SimulatorBackedInstrumentRecoversWhenConfidenceCheckPassesAfterFailure`.
- Both failures timed out in `RunConfidenceCheckCycleAsync` waiting for collector state to leave `WaitingForSwabRemoval` after simulator swab removal. Last state: `CollectionState=VerifyCalibration`, `CollectorState=WaitingForSwabRemoval`, `ReadyToCollectSample=True`, `IsRunningConfidenceCheck=True`, `IsInFaultMode=False`, `LatestFault=None`, `BaselineScans=7`, `AnalysisScans=23/23`.
- Test log search did not show Python, classifier, substance-library, or re-analysis exceptions behind the timeout.
- A follow-up reviewer run temporarily stopped immediately after the simulator removal path. It confirmed `RemoveSampleAsync(false)` is reached after `CanRemoveSwab` is true, returns `True`, and the immediate `GetInstrumentStatusAsync` / `GetSensorValuesAsync` polls complete. The remaining failure is after those calls, when the core collector still times out waiting to leave `WaitingForSwabRemoval`.

Reviewer classification:

- The reproduced blocker is most likely simulator/core collection-recovery behavior around post-analysis swab removal state propagation after a successful simulator remove call, not an algorithm/classifier/model/substance-library/Python package/runtime failure.
- BL-015 can keep partial proof for focused algorithm/Python buildability and visible E2E failure behavior, but it cannot claim full simulator-driven confidence-check proof until the swab-removal recovery blocker is resolved or explicitly deferred by Product Owner.
- The smallest split/fix scope belongs in BL-016: investigate `RunConfidenceCheckCycleAsync` swab removal, simulator clamp-state update, `SampleCollector` handling of `WaitingForSwabRemoval`, and whether polling `GetInstrumentStatusAsync` / `GetSensorValuesAsync` should reliably deliver `OpenAndEmpty` to the core collector after `RemoveSampleAsync`.

## Completion - 2026-06-11

BL-015 is complete after BL-016A removed the shared `WaitingForSwabRemoval` blocker and Reviewer Integration reproduced the simulator confidence-check proof on branch `feature/rc-confidence-check-recovery-persistence`, commit `01c5e2d`.

Completion evidence:

- Focused algorithm/Python builds passed:
  - `CommonLibraries\Algorithms\Python.Interop\Python.Interop.csproj`
  - `InstallEmbeddedPython\InstallEmbeddedPython.csproj`
  - `CommonLibraries\Algorithms\Algorithms.Python\Algorithms.Python.csproj`
- Embedded Python installer execution remains intentionally skipped to avoid local package/environment side effects; package setup assumptions are documented above.
- BL-016A `MicroServicesHarnessTests` passed `6/6` after the swab-removal recovery fix.
- Persisted confidence-check proof was captured through service E2E:
  - persisted sample metadata has `IsConfidenceCheck=true`;
  - persisted sample scan data is retrievable through `GetCollectedSampleScanData`;
  - `ReAnalyzeCollectedSample` returns `IsConfidenceCheck=true`;
  - passing path returns `PassedConfidenceCheck=true`;
  - passing path returns `DetectionResultOverview="Confidence Check: Passed"`.
- The reproduced blocker was classified as simulator/core collection-recovery behavior, not algorithm, classifier, model, substance-library, Python runtime, or Python package failure.
- Fixture proof is deferred for RC because the simulator-driven E2E path now provides the required proof. Add a small sanitized fixture later only if Reviewer Integration or SME requires a non-live algorithm fixture.
- SME/manual parity remains scheduled as a BL-019 final signoff input, not a blocker for closing BL-015 proof work.

Product Owner decision: close BL-015 as done and carry remaining SME parity evidence into BL-019 final RC signoff.
