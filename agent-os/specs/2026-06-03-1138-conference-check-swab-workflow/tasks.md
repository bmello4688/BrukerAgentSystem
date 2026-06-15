# Conference-Check Swab Workflow Tasks

## Discovery

- [x] Compare DHS-GUI conference-check swab workflow.
- [x] Identify current simulator-to-instrument-service message path at the swab-clamp boundary.
- [x] Identify current system status event pipeline.
- [x] Identify current Uno collection/substance-training UI state model.
- [x] Identify scan series repository/database persistence and recall path in full.
- [x] Record investigation notes.

## Build Baseline

- [x] Confirm focused project builds for likely touched projects.
- [x] Confirm solution build command for `MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx`.

## Implementation

- [x] Allow confidence-check verification to start collection when baseline is ready and the swab closes.
- [x] Publish waiting/running confidence-check status at the correct workflow phase.
- [x] Connect collection workflow state to Uno UI progress/timing indicators.
- [x] Publish cleardown state in sample collector snapshots.
- [x] Ensure completion event persists collected confidence-check sample to scan series repository/database with confidence-check metadata.
- [x] Ensure recall path can retrieve the saved sample/scan series.

## Review

- [x] Verify simulator validation.
- [x] Document real-hardware validation gap or result.
- [x] Verify no local tooling/planning references are introduced into the Bruker repo.

## Completion Note

- 2026-06-08: Brian reported BL-006 complete; Product Owner reconciled remaining checklist items to done based on that owner report.
