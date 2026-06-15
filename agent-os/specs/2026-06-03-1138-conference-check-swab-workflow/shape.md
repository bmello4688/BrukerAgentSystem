# Conference-Check Swab Workflow Shape

## Product Goal

When a simulator-inserted swab is marked as a conference check, TripleQuadUI should behave like the operator-facing collection workflow is underway: status messages should update, the Uno UI should show collection progress, and the collected sample should be persisted to the scan series repository/database for later recall.

## Current Context

- Application starts up, starts procedure flow, and enters sleep mode.
- Login wakes the app/instrument.
- Instrument readiness attempts begin and calibration occurs.
- Calibration verification requires a conference check.
- Brian is using the DHS-GUI Compound Analyzer 2 simulator under `C:\Git\DHS-GUI`, connected to the instrument service as the simulator.
- Simulator data appears in the current Uno UI collection/substance-training area.
- Swab inserted messages are not being relayed to system status.
- The workflow UI does not show expected collection state: progress bar, timing, scan progress, and operator feedback.
- The desired end state is a collected sample saved in the scan series repository/database and recallable later.

## Primary User

Operator/tester validating analyzer readiness and conference-check collection behavior through the simulator.

## Legacy Behavior To Compare

Use `C:\Git\DHS-GUI` to inspect the Compound Analyzer 2 simulator workflow and the old application behavior around:

- sleep/wake
- ready/calibration flow
- conference-check swab insertion
- swab-inserted status messages
- sample collection progress
- timing/scan-progress display
- scan-series persistence and recall

## Affected Areas To Investigate

- Instrument service and simulator message handling.
- System status aggregation/relay.
- Uno UI collection/substance-training view models and bindings.
- Collection workflow orchestration.
- Scan series repository/database persistence and recall path.
- Any relevant gRPC/proto contracts, appsettings, launch profiles, generated code, or shared models.

## Acceptance Criteria

- Simulator conference-check swab insertion is detected.
- System status includes the expected swab inserted and collection-state messages.
- Uno collection workflow starts when the conference-check swab is inserted.
- Progress bar and timing/scan indicators update during collection.
- Collection completion is reflected in system status and UI.
- Collected sample is stored in the scan series repository/database.
- Stored scan series/sample can be recalled later.
- Simulator validation evidence is recorded; real-hardware validation is called out separately.

## Non-Goals

- Do not change real hardware behavior unless a bug is clearly documented and approved.
- Do not redesign the full collection UI unless required to restore expected workflow behavior.
- Do not change scan-series schema unless investigation proves persistence cannot work without it.

## Open Questions

1. What exact status message text/states should appear when a conference-check swab is inserted?
2. What should the progress bar measure: elapsed time, scan count, acquisition steps, or another domain concept?
3. Where should the completed conference-check sample appear for recall?
4. Should conference-check samples be stored differently from ordinary samples?
5. Is the DHS-GUI behavior expected to be matched exactly, or are UI improvements allowed if status/persistence semantics are preserved?
