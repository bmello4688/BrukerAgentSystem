# Conference-Check Swab Workflow Investigation Notes

## Terminology

- Brian used "conference check"; current and legacy code use "confidence check".
- Treat these as the same domain workflow unless Brian says otherwise.

## Legacy DHS-GUI Behavior To Preserve

- After calibration completes, the analyzer enters a verification state and asks for a confidence-check swab.
- Once baseline is ready and the swab clamp closes with a swab, DHS-GUI automatically starts analysis.
- While waiting, operator status is an insert-swab message. During collection, status is a running-confidence-check message.
- Collection progress is scan-count based during analysis. Cleardown is a separate indeterminate phase.
- Completion waits for swab removal, clears down, classifies, saves the scan series, and records confidence-check metadata and pass/fail.

## Current TripleQuadUI Findings

- `SampleCollectionService` publishes instrument status, collector state, scan data, sample metadata, and sample-collected streams.
- `SampleCollector` can move from baseline collection to sample collection when baseline is ready and `SwabClampState.ClosedWithSwab` is observed, but only if `startAnalysis` has been set.
- `SampleCollectionManager.SetConfidenceCheck()` and `StartAnalysis()` only take effect while management state is `SampleCollecting`.
- During `VerifyCalibration`, the manager sets `IsRunningConfidenceCheck = true`, but there is no clear path that starts collection automatically when the confidence-check swab is inserted.
- `AppModel` can show "Running confidence check" in `VerifyCalibration` based only on `IsRunningConfidenceCheck`, which may be too early before analysis has started.
- `CollectSamplesForSubstanceTrainingModel` subscribes to scan data directly, so graphs can display simulator scans even when the collection workflow never enters active sample collection.
- `SampleCollectorState` has an `IsClearingDown` field in the service contract, but the service snapshot currently does not appear to set it.
- Current persistence/classification appears to preserve `DidConfidenceCheckPass`, but `ScanSeries.IsConfidenceCheck` should be checked and set before saving.

## Working Hypothesis

The simulator and scan-data path are probably functioning, but the confidence-check swab workflow is blocked at the management/collector state boundary:

- the UI sees scan data because the active scan stream is independent;
- the status/progress workflow does not advance because `VerifyCalibration` does not trigger sample collection on swab closure;
- persistence may not occur because the completed sample workflow event is not raised for the confidence-check run.

## Likely Fix Shape

- Treat `SwabClampState.ClosedWithSwab` as the stable boundary for inserted-swab behavior.
- In the verification workflow, preserve the confidence-check flag and start analysis automatically when baseline is ready and the swab closes.
- Keep normal sample collection behavior unchanged unless a shared state-machine path can safely cover both.
- Publish accurate collector snapshots, including `IsClearingDown`.
- Make status text semantic: waiting for confidence check swab before collection, running confidence check only during active collection.
- Persist confidence-check metadata before saving, including pass/fail.

## Candidate Files

- `CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleCollectionManager.cs`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleCollector.cs`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/Services/SampleCollectionService.cs`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/Protos/sampleCollectionService.proto`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/Presentation/Models/AppModel.cs`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/Presentation/Models/CollectSamplesForSubstanceTrainingModel.cs`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleDataAnalyzer.cs`

## 2026-06-03 Sequence Validation Snapshot

Runner:

- Branch: `feature/confidence-check-swab-workflow`
- Host: `MrmEtdMassSpecAnalyzer.MicroServices.Host`
- Ports: core `7042`, hardware `7043`, simulator control `7044`
- Driver: gRPC wake/calibrate, simulator `InsertSample`, simulator `RemoveSample`
- Start: `2026-06-03T15:28:56.9043720-04:00`
- End: `2026-06-03T15:29:31.4875559-04:00`

Observed sequence:

- Initial: hardware `Sleeping`, instrument `Connected/Sleeping`, swab `OpenAndEmpty`; core system status `WaitingOnCompoundDetectorToBeReady/Success`, substatus `Sleeping/Information`, collection `WaitingOnCompoundDetectorToBeReady`, collector `NotReady`.
- After wake: hardware `Ready`, instrument `Connected/On`, swab `OpenAndEmpty`; core system status `VerifyCalibration/Success`, substatus `CollectingBaseline/Success`, collection `VerifyCalibration`, collector `CollectingBaseline`, confidence `True`, baseline `5`.
- Before insert: hardware still `Ready`, swab `OpenAndEmpty`; core still `VerifyCalibration/Success`, substatus `CollectingBaseline/Success`, collector `CollectingBaseline`, confidence `True`, baseline `5`.
- After `InsertSample=True`: hardware swab changed to `SwabNeedsToBeRemoved`; core top-level status stayed `VerifyCalibration/Success`, substatus changed to `WaitingForSwabRemoval/Success`, collection stayed `VerifyCalibration`, collector `WaitingForSwabRemoval`, confidence `True`, baseline `2`, analysis `5`, cleardown `0`.
- After `RemoveSample=True`: hardware swab returned to `OpenAndEmpty`; core top-level status stayed `VerifyCalibration/Success`, substatus changed to `ClearingDown/Success`, collection stayed `VerifyCalibration`, collector `ClearingDown`, confidence `True`, baseline `2`, analysis `5`, cleardown `1`, `IsClearingDown=True`.
- At +18 seconds after removal: hardware still `Ready/OpenAndEmpty`; core still `VerifyCalibration/Success`, substatus `ClearingDown/Success`, collector `ClearingDown`, cleardown `1`, `IsClearingDown=True`.
- Persistence: metadata count remained `0`; confidence metadata count remained `0`; confidence delta `0`.

Status mismatch evidence:

- Hardware/instrument state did observe swab insertion/removal through the simulator control path.
- SubstanceAnalyzerCore did not publish a changing top-level collection state; `CollectionState` remained `VerifyCalibration` across baseline, sample collection, waiting for removal, and cleardown.
- Core substatus followed collector details, but the user-facing system status can read as still verifying calibration even when the instrument is waiting for swab removal or clearing down.
- Cleardown did not complete in this run; the collector remained `ClearingDown` with one cleardown scan and no persisted confidence-check sample.

Next suspected gap:

- Verify why cleardown scan accumulation/completion stalls after swab removal in confidence-check verification.
- Confirm whether `VerifyCalibration` should remain the top-level `CollectionState` while collector substate changes, or whether system status should map collector substates more explicitly during verification so UI status matches instrument behavior.

## 2026-06-03 Corrected DHS Simulator Substance Rerun

Simulator setup:

- DHS `CompoundDetectorVersion2Simulator.exe` launched.
- Detected-substance combo was first found on `Blank`.
- Corrected detected substance to `Confidence Check`.
- Corrected scan type to `MRM`.
- UIAutomation confirmation after setting: detected substance `Confidence Check`, scan type `MRM`, quad `Q1`.

Runner:

- Host: `MrmEtdMassSpecAnalyzer.MicroServices.Host`
- Ports: core `7042`, hardware `7043`, simulator control `7044`
- Driver: gRPC wake/calibrate, simulator `InsertSample`, simulator `RemoveSample`
- Start: `2026-06-03T16:43:39.7192896-04:00`
- End: `2026-06-03T16:44:13.2248068-04:00`

Observed sequence after correcting detected substance:

- Initial: hardware `Sleeping`, instrument `Connected/Sleeping`, swab `OpenAndEmpty`; core system status `WaitingOnCompoundDetectorToBeReady/Success`, substatus `Sleeping/Information`, collection `WaitingOnCompoundDetectorToBeReady`, collector `NotReady`.
- After wake: hardware `Ready`, instrument `Connected/On`, swab `OpenAndEmpty`; core system status `VerifyCalibration/Success`, substatus `CollectingBaseline/Success`, collection `VerifyCalibration`, collector `CollectingBaseline`, confidence `True`, baseline `5`.
- Before insert: hardware reported `Calibrating`, swab `OpenAndEmpty`; core still `VerifyCalibration/Success`, substatus `NotReady/Success`, collector `NotReady`, confidence `True`, baseline `5`.
- After `InsertSample=True`: hardware swab changed to `SwabNeedsToBeRemoved`; core top-level status stayed `VerifyCalibration/Success`, substatus became `WaitingForSwabRemoval/Success`, collection stayed `VerifyCalibration`, collector `WaitingForSwabRemoval`, confidence `True`, baseline `2`, analysis `5`, cleardown `0`.
- After `RemoveSample=True`: hardware swab returned to `OpenAndEmpty`; core top-level status stayed `VerifyCalibration/Success`, substatus changed to `ClearingDown/Success`, collection stayed `VerifyCalibration`, collector `ClearingDown`, confidence `True`, baseline `2`, analysis `5`, cleardown `1`, `IsClearingDown=True`.
- At +18 seconds after removal: hardware still `Ready/OpenAndEmpty`; core still `VerifyCalibration/Success`, substatus `ClearingDown/Success`, collector `ClearingDown`, cleardown `1`, `IsClearingDown=True`.
- Persistence: metadata count remained `0`; confidence metadata count remained `0`; confidence delta `0`.

Corrected-run conclusion:

- The earlier concern was valid: the DHS simulator detected-substance dropdown was on `Blank` before this rerun.
- After explicitly setting detected substance to `Confidence Check` and scan type to `MRM`, the workflow still stalled in the same place.
- Remaining issue is therefore not only the selected detected-substance signal; confidence-check cleardown/completion/persistence still needs investigation in the TripleQuadUI core workflow.
