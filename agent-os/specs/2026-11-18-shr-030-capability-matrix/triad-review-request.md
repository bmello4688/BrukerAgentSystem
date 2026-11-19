# SHR-030 Triad Review Request

Review `story.md` and the regenerated v1 artifacts independently and return GO, CONDITIONAL GO, or NO-GO for remediation acceptance.

The remediation preserves all 39 SHR-014A operation IDs/ordinals and the 2,340-row matrix. It adds a required target-scope policy per row and explicit presentation/target fixtures. No product or User Management source changed.

## Domain Analyst

- Reconcile every capability/role cell against authoritative Appendix C Table C-1 or identify the exact SME decision required.
- Confirm base-role, QA/Service bundle, least-privilege, revocation, and cross-operation semantics.
- Confirm Supervisor managed-user authority is restricted to Operator targets, cannot change roles or specialist bundles, and Administrator safeguards are explicit.

## User Experience

- Confirm visible/disabled/hidden behavior can be derived from the matrix without treating UI state as authorization.
- Confirm generation, view, export, print, settings, maintenance, and user-management operations are distinguishable for guidance and accessibility.
- Confirm export/print/settings/SSI denial retains an otherwise authorized report, while report-content access or session/policy loss removes it.

## Coordinator Architect

- Decide dedicated `CanExportReports`/`CanPrintReports` versus explicit conjunctions, append-only contract/versioning strategy, rolling-upgrade behavior, source ownership, and SHR-032 validation plan.
- Identify the authoritative Appendix C evidence package required before publication.
- Confirm target-scope enforcement composes with capability enforcement without adding an ambiguous target dimension.

No User Management or product source may change in SHR-030. SHR-032 remains blocked until the matrix is approved and published.
