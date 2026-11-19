# SHR-030 Triad Review Request

Review `story.md` independently and return GO, CONDITIONAL GO, or NO-GO for contract readiness.

## Domain Analyst

- Reconcile every capability/role cell against authoritative Appendix C Table C-1 or identify the exact SME decision required.
- Confirm base-role, QA/Service bundle, least-privilege, revocation, and cross-operation semantics.

## User Experience

- Confirm visible/disabled/hidden behavior can be derived from the matrix without treating UI state as authorization.
- Confirm generation, view, export, print, settings, maintenance, and user-management operations are distinguishable for guidance and accessibility.

## Coordinator Architect

- Decide dedicated `CanExportReports`/`CanPrintReports` versus explicit conjunctions, append-only contract/versioning strategy, rolling-upgrade behavior, source ownership, and SHR-032 validation plan.
- Identify the authoritative Appendix C evidence package required before publication.

No User Management or product source may change in SHR-030. SHR-032 remains blocked until the matrix is approved and published.
