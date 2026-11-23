# TQ-011A operations runbooks

All runbooks use closed outcomes from [outcomes.md](outcomes.md). Support logs contain only closed codes and a redacted correlation reference.

## A. Predeployment/readiness runbook

1. Record the accepted TQ-011A planning SHA and independent Reviewer Integration GO.
2. Record independently published SHR-011D1 and SHR-011D3 SHAs, then the SHR-011D2 SHA descended from both. Verify D3's typed activation modes/reasons, CBE-v1 vectors, closed operation/phase catalog, exact control interface/provider/collections, activation-interval behavior, and conformance commands.
3. Record the trusted identity/session bridge SHA and tests proving stable `UserId`/`SessionId`, denied-attempt behavior, lifecycle ordering, and token/display-name exclusion.
4. Record the owner/SME-approved alarm mapping version and tests for every analyzer terminal state/code/strength, including unknown values.
5. Record the configuration-manifest producer version, exact TQ-011B product SHA, Reports gitlink containing D1/D2/D3, unchanged DataService gitlink, and any separately accepted Services gitlink. Verify source name `triplequadui.substance-analyzer-core` and running assembly informational version.
6. Name the TripleQuadUI product release owner responsible for cutover/rollback. An unassigned role is not sufficient.
7. Confirm binaries deploy with `ReportsV1` readiness disabled by default. No product report query or sample producer may self-enable merely because a service responds.
8. Run the focused and solution validation in [implementation-handoff.md](implementation-handoff.md). Stop on any failure.

## B. Forward-only cutover runbook

1. Announce maintenance; disable report query admission and new sample admission.
2. Wait for existing D2 snapshot leases to complete or expire. Do not force a cursor onto a new snapshot.
3. Require no active sample and no active granted session. If shutdown interrupted a sample, run recovery first and require its terminal `Failure` before session end.
4. Start the exact compatible host/analyzer with readiness `Disabled`. At actual `StartAsync` entry capture one startup-attempt UUID and one trusted restart occurrence; preserve the exact seven-fraction UTC value and do not create a draft yet. This value will be generation-1 T0 and the restart-start occurrence.
5. Initialize SHR-011D3 and FDRS schemas/capabilities before any activation read, machine-partition draft, or query.
6. Validate, in order:
   - accepted D1/D2 versions and exact provider registration;
   - hardware health is `Serving`, then observe a subsequent `DevicesChanged`-applied snapshot with `ConnectionState.Connected`; validate serial and compute `tq-machine-v1` ID;
   - `ReportsV1:ReportingZoneId`; compute `tq-zone-v1` fingerprint;
   - injected trusted clock and logical UTC boundary;
   - trusted session bridge, configuration revision, authoritative source component/version, approved alarm map;
   - no mixed writer/query/source/config version.
7. Read only FDRS/control metadata for the derived target partition. Require zero Event aggregates, imports/import receipts, pending/accepted operations, active Event, and prior activation/migration marker. Any unexpected state is `MigrationIncomplete`; stop without changing it.
8. Call SHR-011D3 `TransitionActivationAsync` with `Mode = Initial`, `Reason = ForwardOnlyCutover`, and `ActivatedUtc =` the exact step-4 restart occurrence. Its one transaction re-proves empty state, creates generation 1/pointer, and commits that captured value as T0; transaction wall-clock time never replaces it. Record no raw serial, zone bytes, or configuration values.
9. Create the first allowed operation with kind `RestartStarted` and logical ID `restart/<startup-attempt UUID>/started`; its draft `OccurredUtc` must equal T0 exactly. Append it, resolve its receipt, and assert no row/operation occurrence is before T0. Then enable writers while keeping queries disabled. Run synthetic producer probes only in an approved qualification partition/environment; production activation uses non-mutating checks unless separately approved.
10. Reconcile with runbook C and run D1/D2 empty/exact machine/zone/cursor conformance probes.
11. Journal/append restart completion. Enable query readiness only after its accepted receipt and zero discrepancy. Record only version SHAs, closed pass/fail codes, aggregate counts, T0, generation, and named owner.

Generation-1 `T0` is exactly the captured restart occurrence, never activation transaction wall-clock time; the first restart-start occurs exactly at T0 and no product record may precede it. T0 is never moved backward or silently recreated. A failed transition remains non-ready until an owner-reviewed exact retry or typed rollback.

## C. Reconciliation runbook

Run at startup, before first query admission after a dependency interruption, and before/after rollback.

1. Disable query admission and new sample starts.
2. Initialize SHR-011D3 and repository capabilities/schema, then load the one active generation/pointer.
3. Verify the post-health connected machine ID, zone fingerprint, authoritative source/config/D1/D2/D3 versions match the active interval.
4. Read every pending SHR-011D3 operation in deterministic order and resolve its repository receipt using the exact CBE-v1 draft fingerprint. Temporary inability is `SourceUnavailable/RetryWhenReady`; reused operation/correlation identity with different canonical bytes is `IdentityCollision/ContactSupport`; missing/corrupt receipt evidence is `SourceGap/ContactSupport`.
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
8. Compare durable checkpoint `(activation generation, partition version, high-water Event ID, pending/accepted operation set)` to the store. Never use time, filename, sample number, or in-memory state as a checkpoint.
9. Run a D1 snapshot probe at the activation boundary and verify stable paging/order/cursor binding without logging values.
10. Enable only if all discrepancy counts are zero. Otherwise preserve data and escalate with the closed guidance code.

## D. Restart runbook

1. At actual `StartAsync` entry, host creates one startup-attempt UUID and captures `OccurredUtc` from the injected `TimeProvider`; it passes both to analyzer startup. These values are not yet an FDRS draft. If no activation exists, this exact occurrence is the only legal generation-1 T0 candidate.
2. Set readiness `Disabled`; construct source name/version; initialize SHR-011D3 then FDRS schema. No collection/report request is admitted.
3. Await hardware `Serving` plus a subsequent connected applied snapshot; derive machine. Resolve zone/config/contract versions and read the matching active activation. Initial cutover commits `TransitionActivationAsync(Initial, ForwardOnlyCutover)` with `StartupAttemptId` from step 1 and `ActivatedUtc = RestartOccurredUtc =` the step-1 occurrence; ordinary restart cannot create a generation.
4. Resolve all pending operation/receipt rows, recover active sample, then recover session. No new draft is created before this finishes.
5. If a previous restart-start has no completion, journal/append its controlled failed completion only if the published mapping permits it. Otherwise `UnknownMapping` and stop.
6. Create/read the current `RestartStarted` operation using logical ID `restart/<startup-attempt UUID>/started`, exact host-captured occurrence, binding, and source; require `OccurredUtc == T0` for generation 1 and `OccurredUtc >= T0` otherwise, then append and journal its accepted receipt.
7. Wait for UserManagement bridge, approved configuration/alarm mapping, provider, and algorithm warmup; run reconciliation.
8. Journal/append restart-completed `Succeeded`, or `Failed` with an approved controlled code when persistence is available.
9. Enable writers, then queries, only after the successful completion receipt and exact reconciliation. On failure remain disabled.

The lifecycle hosted service is the sole restart dispatcher. Repeated callbacks read/retry the same SHR-011D3 operation; they do not create duplicate restart attempts.

## E. Machine, zone, source, contract, or configuration change runbook

1. On machine or zone mismatch, atomically disable and return `MachineMismatch`/`ZoneInvalid`. On a valid new configuration/source/contract version, disable with `SourceUnavailable/RetryWhenReady` pending owner decision. Persisted interval mismatch is `SourceGap`.
2. Preserve every record, activation generation, and operation row. Do not rewrite UTC, move records, merge machine partitions, or edit the pointer outside SHR-011D3.
3. Named release owner records an approval reference and confirms the hardware replacement, rule update, compatible source/contract release, or canonical configuration revision.
4. Replacement machine: call typed `Initial/MachineReplacement` in the new MachineId partition. Same machine: call typed `Successor` with the closed reason matching the changed field family, `ReplacesActivationId` equal to current, and T0 strictly after the prior T0 and last committed boundary. The transaction supersedes the prior generation and installs the successor. A multi-family compatible release uses only `CompatibleReleaseChanged`.
5. Exact redeploy with identical binding fields reuses the current generation/T0. It must not create a generation.
6. Run full reconciliation across activation intervals. Existing records remain governed by the interval in which they occurred. No automatic acceptance is permitted.

## F. Rollback runbook

1. Named release owner disables query readiness and sample admission, then stops analyzer services.
2. Reconcile and determine whether `T0` exists and whether any post-`T0` write was accepted.
3. If no T0 exists, revert the TQ-011B commit and gitlinks as recorded. If T0 exists with proven zero accepted/pending writes in the current interval, do not delete/edit it: call `TransitionActivationAsync` with `Mode = Rollback`, `Reason = ZeroWriteRollback`, current `ReplacesActivationId`, and named compatible `RollbackTargetActivationId`. The transaction closes current as `RolledBack` and copies the target binding into a new active generation at a new T0, or writes nothing and remains disabled. Revert binaries only if they read the retained history.
4. If any write exists: do not deploy an incompatible baseline. Preserve FDRS data; select the last compatible producer/provider version or a reviewed roll-forward; validate contract compatibility and reconcile; enable only after zero discrepancies.
5. Never delete FDRS/control data, reset Event high-water state, remove/edit an activation marker, move T0 backward, alter interval bindings, or re-enable legacy reads.
6. Record exact deployed/reverted SHAs, activation generation/new T0 where applicable, closed reason, aggregate write count, validation outcome, and named owner. Do not record source values.

## G. Support/disclosure runbook

1. Collect local outcome, guidance code, component/version, readiness transition, aggregate integrity/volume counters, and redacted support correlation only.
2. Do not collect or transmit record contents, IDs, machine/user/session identities, annotations, alarm codes, cursor bytes, tokens, raw serial, paths, endpoints, provider/schema details, or exception text through ordinary support channels.
3. Authorized source inspection, if required, follows the existing security/audit procedure on the company-approved system and is outside this runbook.
4. Export/print gets only the authorized report projection and never diagnostic expansion.
