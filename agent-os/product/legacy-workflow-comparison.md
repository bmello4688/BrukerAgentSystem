# TripleQuadUI Legacy Workflow Comparison

This is the BL-003 local reference. It compares major DHS-GUI operator workflows under `C:\Git\DHS-GUI\Applications\CompoundAnalyzer` to likely TripleQuadUI areas. Keep this file outside the Bruker Detection Git repo.

## Legacy Surface

Primary legacy app area:

- `Applications/CompoundAnalyzer/DE-SCION`
- Legacy solution: `Applications/CompoundAnalyzer/CompoundAnalyzer.sln`

Important legacy view/model areas:

- `MainViewModel`, `MainWindowContentViewModel`, `MainCommandPanelViewModel`
- `LoginViewModel`, `UserManagementViewModel`
- `LiveModeViewModel`, `DetectingViewModel`, `SystemStatusSummaryViewModel`
- `HistoryScansViewModel`, `HistoryScanViewModel`, `DataManagementViewModel`
- `OptionsViewModel`, `SubstanceLibraryOptionsViewModel`, `AlarmOptionsViewModel`, `PrintOptionsViewModel`
- `DeviceStatusViewModel`, `DesorberStatusViewModel`, `MaintenanceViewModel`, `SensorValuesViewModel`
- `ReportsViewModel`, `ReportSelectorViewModel`

The legacy app is centered around `LiveScanSeriesAnalyzer`, `HistoricScanSeriesAnalyzer`, `CompoundDetectorFactory`, `ICompoundDetector`, `UserSecurityManager`, `MsWorkstationLogClient`, and reporting/user-management services.

## Workflow Map

### Login And User Access

Legacy:

- App starts at login, then swaps to the main shell after successful login.
- `UserSecurityManager` controls roles and access.
- Main command panels update access policy after login.
- User management, two-factor auth, password reset, and logoff are visible workflow concerns.

TripleQuadUI:

- Current likely areas: `Presentation/LoginPage.xaml`, `LoginModel`, `AppPage`, `MainModel`, `AppModel`, navigator routes, and any future identity service/client work.

Notes:

- Access gating affects live/history/report/maintenance/data-management availability.
- Future stories should not treat login as only a screen transition; it drives operator permissions.

### Instrument Wake, Sleep, Status, And Readiness

Legacy:

- Main shell gets a compound detector from `CompoundDetectorFactory`.
- Wake/activity flows call `KeepAwakeOrWakeUp`.
- `SystemStatusSummaryViewModel` maps compound-detector and analyzer state to operator status text.
- Readiness includes instrument states, sensors, fault mode, calibration state, and maintenance alerts.

TripleQuadUI:

- Current likely areas: `TripleQuadHardware.Client`, `TripleQuadHardware.Service`, `HardwareLayer/Msws`, `SubstanceAnalyzerCore.Service`, `AppModel`, `SystemStatusPanel`, and `MainPageNavigatorPanel`.

Hardware-sensitive:

- Yes. Wake/sleep, startup/shutdown, readiness, sensor range, fault mode, and calibration behavior should preserve DHS-GUI-compatible semantics unless a story explicitly authorizes a change.

### Live Sample Collection And Confidence Check

Legacy:

- `LiveModeViewModel` and `DetectingViewModel` expose start/stop analysis commands.
- `LiveScanSeriesAnalyzer` tracks analyzer state, baseline, analysis, cleardown, confidence check, scan counts, durations, and swab-removal state.
- Confidence check is a first-class mode that changes status/substatus expectations.
- Operator feedback includes progress, durations, "Insert swab", "Remove swab", ready/not-ready, and fault messages.

TripleQuadUI:

- Current likely areas: `CollectSamplesPage`, `CollectSamplesModel`, `CollectSamplesForSubstanceTrainingPage`, `CollectSamplesForSubstanceTrainingModel`, `LineGraph2DModel`, `SubstanceAnalyzerCore.Client`, `SubstanceAnalyzerCore.Service`, `SampleCollectionManager`, `SampleCollector`.

Hardware-sensitive:

- Yes. Swab state, baseline readiness, confidence check, cleardown, pressure/readiness checks, and sample persistence should be validated with simulator separately from real hardware.

Follow-up:

- BL-006 already covered the conference-check swab workflow and was reported complete.
- BL-011 should compare archived recall enough to preserve sample/scan continuity after collection.

### Substance Alerts And Alarm Controls

Legacy:

- `SystemStatusSummaryViewModel` and `SubstanceAlertViewModel` expose active alert state, detected substances, audible alarm state, mute, and clear.
- Alarm states include none, disabled, on, and muted.
- Legacy UI used flashing/alarm controls that BL-007 intentionally refined in TripleQuadUI.

TripleQuadUI:

- Current likely areas: `SystemAlarmControl.xaml`, `SystemStatusPanel.xaml`, `SubstanceAlertPage`, `AppModel`, `SubstanceAnalyzerCore.Service`, alarm/audible state mapping.

Safety-sensitive:

- Yes. UI must not imply an alarm is resolved when only audio is muted.

Follow-up:

- BL-007 is done; future alarm work should cite its wording and non-goals.

### History And Archived Scan Recall

Legacy:

- `HistoryScansViewModel` and `HistoryScanViewModel` load historical scan series.
- History has alarm/non-alarm filters, sample number sorting, and selected-scan detail.
- Legacy data service/client code supports sample metadata and scan data conversion.

TripleQuadUI:

- Current likely areas: `CollectedSamplesAnalysisPage`, `CollectedSamplesAnalysisModel`, `CollectedSampleListControl`, `DataService.Service`, `DataService.Clients`, `SamplesRepoGrpcClient`, scan repository implementations, archived scan paths.

Persistence-sensitive:

- Yes. Archived recall must preserve metadata, scan data, detections, confidence-check flags, and graph display without corrupting active collection state.

Follow-up:

- BL-011 is the first data/history implementation candidate and should depend on this workflow comparison.

### Data Management: Clear And Export History

Legacy:

- `DataManagementViewModel` exposes `ExportHistoryScansCommand` and `ClearAllHistoryScansCommand`.
- Export requires USB drive availability and user access-policy permissions.
- Clear history asks for confirmation before deleting all history data.

TripleQuadUI:

- Current likely areas: future data-management UI, `DataService.Service`, `DataService.Clients`, repository delete/export paths, removable-media integration if export-to-USB remains required.

Destructive/sensitive:

- Yes. Clearing history should be gated by permissions, confirmation, and explicit scope.

Follow-up:

- BL-012 should preserve or intentionally improve this behavior after BL-011 clarifies recall and storage expectations.

### Options And Substance Library

Legacy:

- Options include alarm options, print options, substance library options, classifier settings, and desorber options.
- Substance library options can add/remove substances and edit substance options.
- Print options include auto-print detections.

TripleQuadUI:

- Current likely areas are partial or not clearly implemented: substance selection/training, `LineGraph2DModel` substance filters, algorithm resources, appsettings, and future options UI.

Hardware/algorithm-sensitive:

- Substance library and classifier settings can affect detection behavior; Domain Analyst and SME review may be required.

### Device, Desorber, Sensor, And Maintenance Workflows

Legacy:

- Device status shows sensors and maintenance instructions.
- Desorber status includes door/system status and manual/automatic door commands.
- Maintenance view is access-gated.
- Sensor out-of-range conditions feed status/substatus.

TripleQuadUI:

- Current likely areas: `HardwareLayer/Hardware.Interface.Desorber`, `TripleQuadHardwareInstrument`, `TripleQuadHardware.Service`, `HardwareLayer/Msws`, `SystemStatusPanel`, future instrument/maintenance pages.

Hardware-sensitive:

- Yes. Manual desorber commands, sensor ranges, and maintenance states require owner/SME review and simulator/real hardware validation separation.

### Reports

Legacy:

- Reports include sample summary, history events, user summary, daily history events, equipment summary, show/print/export-to-USB.

TripleQuadUI:

- Current need is unconfirmed. Brian ranked report generation lowest.

Follow-up:

- Keep report generation parked until product need is confirmed.

## Candidate Story Links

- BL-008: build reliability gate.
- BL-009: Windows runtime and launch profiles.
- BL-010: embedded Python and algorithm/ML infrastructure.
- BL-011: archived scan recall.
- BL-012: clear/export history operations.

## Summary

The legacy workflows most important to preserve are login/access gating, live collection/confidence check, status/alarm clarity, hardware readiness/maintenance, archived scan recall, and controlled history clear/export. Reports are explicitly low priority. Hardware/instrument-sensitive behavior should be compared against DHS-GUI before semantic changes are made.
