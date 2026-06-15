# Validation Notes

## 2026-06-03 Simulator Sequence

Setup:
- Branch: `feature/confidence-check-swab-workflow`
- Launch path: `Launch All w/Simulator` / `MrmEtdMassSpecAnalyzer.MicroServices.Host`
- DHS Compound Detector simulator selections:
  - Detected substance: `Confidence Check`
  - Acquisition: `MRM`
- Active method observed by TripleQuadUI scan manager: `MRM.mth`

Important corrected settings:
- `Detector Can Analyze` is now true when the instrument wakes and starts MRM sampling.
- Baseline scan count is 10.
- Analysis scan count is 23.

Observed sequence from 17:46 run:
- Initial:
  - Hardware: `Sleeping`, power `Sleeping`, swab `OpenAndEmpty`
  - Core: `WaitingOnCompoundDetectorToBeReady`
  - Collector: `NotReady`
  - Scan manager: ready to analyze true, not sampling yet
- After wake:
  - Hardware: `Ready`, power `On`, swab `OpenAndEmpty`
  - Core: `VerifyCalibration`
  - Collector: `CollectingBaseline`
  - Baseline scans: 7 and increasing
  - Scan manager: `isSampling=True`, `readyAnalyze=True`, active `MRM.mth`
- After calibration/baseline ready:
  - Core: `VerifyCalibration`
  - Collector: `CollectingBaseline`
  - Baseline scans: 10
  - Analysis scans: 0
  - UI status should read as insert confidence-check swab.
- After insert confidence-check swab:
  - Hardware swab: `SwabNeedsToBeRemoved`
  - Core: `VerifyCalibration`
  - Collector: `CollectingSample`
  - Baseline scans retained for sample: 7
  - Analysis scans at +2s: 11
  - UI status should read as swab inserted / collecting sample.
- After analysis window:
  - Hardware swab: `SwabNeedsToBeRemoved`
  - Core: `VerifyCalibration`
  - Collector: `WaitingForSwabRemoval`
  - Analysis scans: 23
  - UI status should read remove swab.
- After remove swab:
  - Hardware swab: `OpenAndEmpty`
  - Core: `VerifyCalibration`
  - Collector: `CollectingBaseline`
  - Fault/info: `FailedCalibration`
  - Baseline resumes and reaches 10 again.
  - Host no longer crashes when the confidence-check result is failed.

Remaining mismatch:
- Repository metadata did not get created in the validation run:
  - `samplesBefore=0`
  - `samplesAfter=0`
  - `confidenceDelta=0`
- This means the runtime sequence now advances correctly, but the scan series persistence path still needs investigation.

## 2026-06-03 19:33 Status/UI Rerun

DHS-GUI comparison:
- DHS-GUI maps `AnalyzerState.VerifyCalibration` to top-line `Verifying...`.
- DHS-GUI keeps the confidence-check instructions in substatus:
  - MRM/full-scan mismatch: change active method to MRM mode.
  - Baseline not ready: waiting on baseline scans.
  - Verification ready: insert confidence-check swab.
  - Analysis running: running confidence check.
  - Waiting state: remove swab.
  - Failed verification: run diagnostics / re-run confidence check.
- No explicit three-trial verification limit was found in `LiveScanSeriesAnalyzer` or `SystemStatusSummaryViewModel`; failures re-enter `VerifyCalibration` through `FailedCalibration`.

Status mapping now expected in TripleQuadUI:
- Headline remains `Verify calibration` during verification, including baseline and failed-confidence-check retry states.
- Substatus shows the collector phase:
  - `Collecting baseline scan N`
  - `Insert confidence check swab`
  - `Collecting sample scan N of 23`
  - `Remove swab`
  - `Analyzing`
  - `Failed calibration`

Final service status sequence from the 19:33 run:
- Initial:
  - Hardware: `Sleeping`, power `Sleeping`, swab `OpenAndEmpty`
  - Core: `WaitingOnCompoundDetectorToBeReady`
  - Collector: `NotReady`
- After wake/calibrate:
  - Hardware: `Ready`, power `On`, swab `OpenAndEmpty`
  - Core: `VerifyCalibration`
  - Collector: `CollectingBaseline`
  - Baseline reached 10 before insert.
- After insert:
  - Hardware swab: `SwabNeedsToBeRemoved`
  - Core: `VerifyCalibration`
  - Collector: `CollectingSample`
  - Baseline retained for sample: 7
  - Analysis at +2s: 11
- At analysis window complete:
  - Core: `VerifyCalibration`
  - Collector: `WaitingForSwabRemoval`
  - Analysis scans: 23
- After remove:
  - Hardware swab: `OpenAndEmpty`
  - Core status: `VerifyCalibration/Warning`
  - Collector: `CollectingBaseline`
  - Fault/info: `FailedCalibration`
  - Baseline restarts and reaches 10 again.

Remaining mismatch:
- Persistence still did not surface through collected sample metadata:
  - `samplesBefore=0`
  - `samplesAfter=0`
  - `confidenceDelta=0`
- Next investigation target: `SampleCollectionManager.OnSampleCollected` / `SampleDataAnalyzer.SaveSample` / samples repository metadata refresh or save failure logging.

Fixes applied during validation:
- In-process simulator now exposes working insert/remove sample gRPC controls backed by the shared simulator context.
- Simulated swab removal now opens the clamp and publishes `OpenAndEmpty`.
- Verify-calibration state now allows failed and passed verification result triggers instead of crashing on `FailedCalibration`.
- Collector cleardown exit is synchronous and guarded so cleardown completion is not pinned by async state-machine exit behavior.
- Scan callback ignores blank initial scan snapshots and logs processing errors instead of killing the callback.
- Application settings normalize legacy persisted scan counts from 5/5 to baseline 10 and analysis 23.

## 2026-06-03 21:02 Save Path Rerun

Issue found:
- `SampleCollectionManager.OnSampleCollected` raised the public `SampleCollected` event before classification and save.
- That allowed the notification path to block the collector before `SampleDataAnalyzer.SaveSample` ran.
- When classification threw, `ScanSeries.IsConfidenceCheck` and `ScanSeries.Classification` were not guaranteed before repository conversion, so confidence-check metadata could be missing or the repository conversion could fail.
- Failed-calibration reentry could start a second collection from the same insert/remove cycle because the baseline state had not required a fresh open-clamp observation before accepting another inserted-swab state.

Fixes applied:
- Internal classification/save now happens before the manager-level `SampleCollected` notification.
- Confidence-check identity is assigned before classifier execution.
- A default empty `Classification` is assigned before classifier execution so failed classification does not prevent repository conversion.
- `CollectingBaseline` clears stale start/stop flags and requires an observed open clamp before auto-starting a swab-driven collection.
- `CollectingBaseline` ignores stale `CleardownFinished` triggers.

Validated service sequence:
- Before insert:
  - Core: `VerifyCalibration/Success`
  - Collector: `CollectingBaseline`
  - Baseline: 10
  - Metadata: 0
- After insert:
  - Hardware swab: `SwabNeedsToBeRemoved`
  - Core: `VerifyCalibration/Success`
  - Collector: `CollectingSample`
  - Analysis scans: 12 at +2s
- At analysis window:
  - Collector: `WaitingForSwabRemoval`
  - Analysis scans: 23
- After remove:
  - Hardware swab: `OpenAndEmpty`
  - Core: `VerifyCalibration/Warning`
  - Collector: `CollectingBaseline`
  - Fault/info: `FailedCalibration`
  - Metadata: 1
  - Confidence metadata: 1
  - Last saved sample: `sample=1017058`, `scanType=MRM`, `detected=0`

Current result:
- One insert/remove cycle now creates exactly one confidence-check metadata row:
  - `samplesAfter=1`
  - `confidenceDelta=1`
- The UI/core status stream now follows the expected failed-verification retry shape:
  - baseline collection
  - insert swab
  - collecting sample
  - remove swab
  - failed calibration
  - baseline ready for another verification attempt

Remaining issue:
- The simulator run still logs `Classify error` from `Algorithms.Python.Analyzer.GetScanSeriesAndBaselineForecastAsAPyList`: `RuntimeBinderException: Cannot perform runtime binding on a null reference`.
- Because classifier output is unavailable, `DidConfidenceCheckPass=False` and the verification correctly returns to `FailedCalibration`.

## 2026-06-03 21:17 Confidence-Check Classifier Rerun

Additional fixes applied:
- The in-process simulator control API now exposes scan type and substance selection.
- The test runner selects `MRM` and `Confidence Check` before inserting the swab.
- The simulator confidence-check substance list now comes directly from `SubstanceLibrary.ConfidenceCheck`, matching DHS-GUI.
- Classification now supplies default annotation/classification objects before calling Python, and Python codec failures throw a useful exception instead of passing a null object into the analyzer.

Validated end-to-end sequence:
- Initial:
  - Hardware: `Sleeping`, swab `OpenAndEmpty`
  - Core: `WaitingOnCompoundDetectorToBeReady`
  - Collector: `NotReady`
- After wake:
  - Hardware: `Ready`, power `On`, `readyVerify=True`
  - Core: `VerifyCalibration/Success`
  - Sub status: `CollectingBaseline/Success`
  - Collector: `CollectingBaseline`
  - Baseline: 9
- After calibrate / baseline ready:
  - Core: `VerifyCalibration/Success`
  - Sub status: `CollectingBaseline/Success`
  - Collector: `CollectingBaseline`
  - Baseline: 10
- Simulator setup:
  - `GetSubstances`: count 63, includes `Confidence Check`
  - `SetScanType MRM=True`
  - `SetSubstance Confidence Check=True`
- After insert:
  - Hardware swab: `SwabNeedsToBeRemoved`
  - Core: `VerifyCalibration/Success`
  - Sub status: `CollectingSample/Success`
  - Collector: `CollectingSample`
  - Analysis scans: 12 at +2s
- At analysis window complete:
  - Collector: `WaitingForSwabRemoval`
  - Analysis scans: 23
- After remove:
  - Hardware swab: `OpenAndEmpty`
  - Hardware calibration: `NoCalibrationNeeded`
  - Core: `SampleCollecting/Success`
  - Sub status: `CollectingBaseline/Success`
  - Collector: `CollectingBaseline`
  - Confidence check mode: false
  - Baseline restarted and reached 10

Saved sample result:
- One confidence-check row persisted:
  - `sample=1017060`
  - `scanType=MRM`
  - `detected=4`
  - `confidenceDelta=1`
- Host logs:
  - `Classify finished`
  - `Saving sample #1017060. IsConfidenceCheck=True, DidConfidenceCheckPass=True.`
  - `Saved sample #1017060.`

Current result:
- End-to-end simulator-driven confidence-check verification now passes and persists data.
- The status stream follows the expected successful-verification path into normal sample collection after the swab is removed.
- Live workflow still mirrors DHS-GUI by moving the last 3 baseline scans into analysis during save/classification; the UI/status reaches baseline-ready at 10 before swab insertion, while the saved scan series logs `BaselineScans=7` and `AnalysisScans=23`.

## 2026-06-03 21:50 Status Miss/Stale-State Rerun

Issue found:
- The system status UI combined separate instrument-status and collector-state streams, but its heartbeat only fetched current state while both cached values were null.
- If a stream missed, lagged, or reconnected around a swab transition, the UI could keep stale substatus text such as insert-swab even though the collector had moved into collecting sample or waiting-for-removal.
- Scan-data changes updated graph/alert feeds but did not explicitly publish collector-state/instrument-status changes, so scan-count/status text could lag until another state event arrived.
- After a passing confidence check, a transient `NeedToCalibrate` condition could be recorded before the verified hardware snapshot settled. That stale fault was not cleared, leaving the system in `VerifyCalibration/Warning` even after `DidConfidenceCheckPass=True`.
- `BaseDeviceManager.Verified()` changed calibration state and ready-to-verify state but did not raise `DevicesChanged`, so subscribers could keep old calibration snapshots.

Fixes applied:
- `SampleCollectionService` now publishes instrument and collector status changes on scan-data updates.
- `AppModel` heartbeat now continuously reconciles current instrument status and collector state while the service is available, instead of only during startup/no-data.
- Normal sample-collection ready text now reports `Ready` / `Insert swab to start analysis` when baseline is complete.
- `SampleCollectionManager` now awaits `Verified()` before transitioning out of verify calibration.
- `NeedToCalibrate` clears when the hardware no longer needs calibration.
- In `SampleCollecting`, ready-to-verify is handled before need-to-calibrate so transient combined states do not plant a stale calibration fault.
- `BaseDeviceManager.Verified()` now raises `DevicesChanged`.

Validated rerun:
- Before insert:
  - Core: `VerifyCalibration/Success`
  - Collector: `CollectingBaseline`
  - Ready: true
  - Baseline: 10
- After insert:
  - Hardware swab: `SwabNeedsToBeRemoved`
  - Core: `VerifyCalibration/Success`
  - Collector: `CollectingSample`
  - Analysis scans: 11 at +2s
- At analysis window complete:
  - Collector: `WaitingForSwabRemoval`
  - Analysis scans: 23
- After remove:
  - Hardware calibration: `NoCalibrationNeeded`
  - `needCal=False`
  - `readyVerify=False`
  - Core: `SampleCollecting/Success`
  - Collector: `CollectingBaseline`
  - Fault: `None`
  - Confidence check mode: false
  - Baseline reached 10 again
- Saved result:
  - `sample=1017062`
  - `scanType=MRM`
  - `detected=4`
  - `confidenceDelta=1`

Current result:
- The passing sequence no longer leaves stale verify-calibration or need-to-calibrate status after removal.
- The service and UI model are less dependent on catching a single transition event; missed/late subscription events should be corrected by scan-status publication and the UI heartbeat.
