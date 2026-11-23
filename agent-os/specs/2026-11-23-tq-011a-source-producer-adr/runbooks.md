# TQ-011A operations runbooks

All runbooks use closed outcomes from [outcomes.md](outcomes.md). Support logs contain only closed codes and a redacted correlation reference.

## A. Predeployment/readiness runbook

1. Record the accepted TQ-011A planning SHA and independent Reviewer Integration GO.
2. Record independently published SHR-011D1 and SHR-011D2 SHAs. Verify the exact interface/provider symbols in the ADR and run their conformance commands.
3. Record the trusted identity/session bridge SHA and tests proving stable `UserId`/`SessionId`, denied-attempt behavior, lifecycle ordering, and token/display-name exclusion.
4. Record the owner/SME-approved alarm mapping version and tests for every analyzer terminal state/code/strength, including unknown values.
5. Record the configuration-manifest producer version, exact TQ-011B product SHA, Reports gitlink, unchanged DataService gitlink, and any separately accepted Services gitlink.
6. Name the TripleQuadUI product release owner responsible for cutover/rollback. An unassigned role is not sufficient.
7. Confirm binaries deploy with `ReportsV1` readiness disabled by default. No product report query or sample producer may self-enable merely because a service responds.
8. Run the focused and solution validation in [implementation-handoff.md](implementation-handoff.md). Stop on any failure.

## B. Forward-only cutover runbook

1. Announce maintenance; disable report query admission and new sample admission.
2. Wait for existing D2 snapshot leases to complete or expire. Do not force a cursor onto a new snapshot.
3. Require no active sample and no active granted session. If shutdown interrupted a sample, run recovery first and require its terminal `Failure` before session end.
4. Start the exact compatible host/analyzer with readiness `Disabled`.
5. Validate, in order:
   - accepted D1/D2 versions and exact provider registration;
   - reconciled connected hardware serial; compute `tq-machine-v1` ID;
   - `ReportsV1:ReportingZoneId`; compute `tq-zone-v1` fingerprint;
   - injected trusted clock and logical UTC boundary;
   - FDRS store capability/schema initialization;
   - trusted session bridge, configuration revision, source component/version, approved alarm map;
   - no mixed writer/query/source/config version.
6. Read only FDRS metadata for the derived target partition. Require zero Event aggregates, zero imports/import receipts, zero active Event, and no prior activation/migration marker. Any unexpected state is `MigrationIncomplete`; stop without changing it.
7. Commit one activation record containing `T0` (trusted UTC), machine mapping version/ID, zone ID/fingerprint/version, writer/query/source/config versions, and no raw serial/config values.
8. Enable writers while keeping queries disabled. Run deterministic synthetic producer probes only in the approved qualification partition/environment; production activation uses non-mutating capability/reconciliation checks unless a separately approved qualification procedure permits records.
9. Reconcile with the thresholds in runbook C. Run D1/D2 empty/exact machine/zone/cursor conformance probes.
10. Enable query readiness only when every result is exact and zero discrepancy. Record only version SHAs, closed pass/fail codes, aggregate counts, `T0`, and named owner.

`T0` is never moved backward or silently recreated. A failed activation remains non-ready until an owner-reviewed retry or rollback.

## C. Reconciliation runbook

Run at startup, before first query admission after a dependency interruption, and before/after rollback.

1. Disable query admission and new sample starts.
2. Initialize repository capabilities/schema and load the committed activation binding.
3. Verify current machine ID, zone fingerprint, source/config/D1/D2 versions match activation.
4. Resolve every deterministic start/append receipt. If a receipt cannot be resolved, return `SourceUnavailable`; if evidence conflicts, return `SourceGap`.
5. If one Event is active, call `RecoverInterruptedSampleAsync` once. Require the same ID/correlation terminal `Failure`. More than one active Event or state/aggregate disagreement is `SourceGap`.
6. Only after sample recovery, append recovery session termination/incomplete evidence using the trusted bridge. Never fabricate a session end time from process start.
7. Validate the native post-`T0` sequence and aggregate sanitized counts:
   - duplicate/reused identities = 0;
   - unexpected ID gaps = 0;
   - missing/duplicate/conflicting terminals = 0;
   - orphan/inconsistent session links = 0;
   - incomplete/conflicting restart pairs eligible as values = 0;
   - unknown code/version/mapping = 0;
   - machine/zone/config/source mismatch = 0;
   - unresolved receipts = 0.
8. Compare durable checkpoint `(partition version, high-water Event ID, accepted receipt set)` to the store. Never use time, filename, sample number, or in-memory state as a checkpoint.
9. Run a D1 snapshot probe at the activation boundary and verify stable paging/order/cursor binding without logging values.
10. Enable only if all discrepancy counts are zero. Otherwise preserve data and escalate with the closed guidance code.

## D. Restart runbook

1. Host creates one restart correlation at restart request receipt and passes it to analyzer startup.
2. Set readiness `Disabled`; no collection/report request is admitted.
3. If a previous restart-start has no completion, append its controlled failed completion only if the published mapping unambiguously permits it. Otherwise `UnknownMapping` and stop.
4. Append the current restart-start with trusted UTC and the deterministic correlation.
5. Initialize storage; bind machine/zone; resolve receipts; recover sample then session; wait for hardware, UserManagement bridge, configuration, approved alarm mapper, and algorithm warmup.
6. Run reconciliation. If successful, append restart-completed `Succeeded`; otherwise append `Failed` with the approved controlled code when persistence is available.
7. Enable writers, then queries, only after the successful completion receipt and exact reconciliation. On failure remain disabled.

Repeated restart callbacks retry the same correlation/draft. They do not create duplicate restart attempts.

## E. Machine or zone change runbook

1. On current derived machine ID or zone fingerprint mismatch, atomically disable writers/queries and return `MachineMismatch` or `ZoneInvalid`.
2. Preserve all records and the original activation binding. Do not rewrite UTC, move records, or merge machine partitions.
3. Confirm hardware replacement or OS time-zone rule update through the named release owner.
4. For a replacement instrument, create a separately approved new activation/T0/partition. For a rule update, perform an owner-reviewed reactivation decision that explicitly states treatment of existing UTC records.
5. Run full cutover/reconciliation. No automatic acceptance of the new value is permitted.

## F. Rollback runbook

1. Named release owner disables query readiness and sample admission, then stops analyzer services.
2. Reconcile and determine whether `T0` exists and whether any post-`T0` write was accepted.
3. If no `T0`, or `T0` with a proven zero accepted writes: revert the TQ-011B commit and `CommonLibraries/Reports` gitlink to the recorded preimplementation SHA; revert a Services gitlink only if TQ-011B advanced it; leave DataService unchanged. Restart with reports disabled and verify the product baseline.
4. If any write exists: do not deploy an incompatible baseline. Preserve FDRS data; select the last compatible producer/provider version or a reviewed roll-forward; validate contract compatibility and reconcile; enable only after zero discrepancies.
5. Never delete FDRS data, reset Event high-water state, remove an activation marker to disguise history, alter machine/zone binding, or re-enable legacy reads.
6. Record the exact deployed/reverted SHAs, closed reason, aggregate write count, validation outcome, and named owner. Do not record source values.

## G. Support/disclosure runbook

1. Collect local outcome, guidance code, component/version, readiness transition, aggregate integrity/volume counters, and redacted support correlation only.
2. Do not collect or transmit record contents, IDs, machine/user/session identities, annotations, alarm codes, cursor bytes, tokens, raw serial, paths, endpoints, provider/schema details, or exception text through ordinary support channels.
3. Authorized source inspection, if required, follows the existing security/audit procedure on the company-approved system and is outside this runbook.
4. Export/print gets only the authorized report projection and never diagnostic expansion.
