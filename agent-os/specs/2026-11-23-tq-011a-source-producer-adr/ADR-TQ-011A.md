# ADR TQ-011A: authoritative TripleQuadUI report sources and producers

- **Status:** Proposed for independent Reviewer Integration acceptance
- **Decision date:** 2026-11-23
- **Planning base:** `8f99be2529ec7be4a17efb498719471a77fb82d8`
- **TripleQuadUI evidence baseline:** `26d3b174795384841b60eea987f97c7a711f8892`
- **Published Common.Reports evidence baseline:** `664a09a9427cf2ade7fc155a1844c6505890c2bc`
- **Recorded Common.DataService baseline:** `ca36e9aabb149da9ff6d02e6707bd3df77224b38`

## Context

The current analyzer starts collection synchronously from gRPC/UI state, creates a wrapping local sample number, records `Environment.MachineName`, saves a legacy scan object, and keeps annotations in mutable application objects. Those facts are not an atomic FDRS report source. The analyzer also receives an access token only for policy lookup; its UI session contains a username and token, not stable actor/session identities. The hardware client does expose a reconciled instrument serial. See [evidence-register.md](evidence-register.md).

The published FDRS baseline already owns atomic Sample Event allocation/start, terminal completion, interrupted-sample recovery, typed restart/session/annotation payloads, stable actor/session requirements, and DataService transactional semantics. The new D1 query contract and D2 provider are required dependencies, but as of this ADR they have no independently accepted publication SHA. Their dirty development files are deliberately not evidence for this decision.

## Decision

### 1. History is `ForwardOnlyAtCutover`

`T0` is the committed activation instant for one machine binding, reporting-zone binding, source version, and configuration revision. Only native FDRS records accepted at or after `T0` are reportable.

- A range whose derived UTC interval starts before `T0` returns local `HistoryUnavailable`; it never returns a partial page.
- An Event request for an ID not present in the activated FDRS partition receives published D1 `NotFound`, which the analyzer maps to local zero-value `HistoryUnavailable`. Legacy sample numbers are never translated.
- No legacy sample repository, file, UI cache, or fallback provider is queried.
- No import receipts are expected. Any preactivation FDRS event/import state for the target partition returns `MigrationIncomplete` and blocks activation.
- A later requirement for historical reporting requires a new migration ADR/story. It cannot be implemented as a dual read.

Rejected alternatives:

| Alternative | Reason rejected |
|---|---|
| Indefinite dual read | Cannot give one identity/order/availability model and permits divergent values. |
| Import current legacy sample metadata | Lacks stable user/session links, atomic FDRS IDs, trusted UTC provenance, restart/session lifecycle, and approved alarm semantics. |
| Translate local sample number on demand | The number wraps and is not allocated atomically with the FDRS start commit. |

### 2. Exact analyzer write boundary

TQ-011B adds `CoreLogicLayer/SubstanceAnalyzerCore.Service/Reporting/IAnalyzerReportSourceProducerV1.cs` with this internal interface and immutable local input records. Method names and meanings are frozen; implementation may not bypass them.

```csharp
internal interface IAnalyzerReportSourceProducerV1
{
    ValueTask<FdrsOperationResult<bool>> InitializeAsync(CancellationToken cancellationToken);
    ValueTask<FdrsOperationResult<AcceptedSample>> AcceptSampleAsync(
        TrustedSampleAcceptanceV1 acceptance, CancellationToken cancellationToken);
    ValueTask<FdrsOperationResult<CompletedSample>> CompleteSampleAsync(
        TrustedSampleCompletionV1 completion, CancellationToken cancellationToken);
    ValueTask<FdrsOperationResult<CompletedSample?>> RecoverInterruptedSampleAsync(
        DateTimeOffset observedUtc, string correlationId, CancellationToken cancellationToken);
    ValueTask<FdrsOperationResult<FdrsRecord>> RecordRestartStartedAsync(
        TrustedRestartStartedV1 value, CancellationToken cancellationToken);
    ValueTask<FdrsOperationResult<FdrsRecord>> RecordRestartCompletedAsync(
        TrustedRestartCompletedV1 value, CancellationToken cancellationToken);
    ValueTask<FdrsOperationResult<FdrsRecord>> RecordSessionStartedAsync(
        TrustedSessionStartedV1 value, CancellationToken cancellationToken);
    ValueTask<FdrsOperationResult<FdrsRecord>> RecordSessionAccessDecisionAsync(
        TrustedSessionAccessDecisionV1 value, CancellationToken cancellationToken);
    ValueTask<FdrsOperationResult<FdrsRecord>> RecordSessionEndedAsync(
        TrustedSessionEndedV1 value, CancellationToken cancellationToken);
    ValueTask<FdrsOperationResult<FdrsRecord>> AddEventAnnotationAsync(
        TrustedEventAnnotationV1 value, CancellationToken cancellationToken);
}
```

`AnalyzerReportSourceProducerV1` is the sole implementation. It captures the activated machine, `SourceComponent`, configuration revision, and `TimeProvider`; callers cannot override those fields. The local `Trusted*V1` records contain only typed domain values needed by the corresponding method. They reject default/unknown enum values, non-UTC timestamps, inconsistent event correlation, absent stable actor/session IDs, and unapproved alarm codes before repository access. They contain no username, token, path, exception, UI model, or provider type.

Exact repository delegation:

| Facade method | Published API/payload |
|---|---|
| `InitializeAsync` | `IFdrsRepository.InitializeAsync` |
| `AcceptSampleAsync` | construct `StartSampleCommand`; call `IFdrsRepository.StartSampleAsync` |
| `CompleteSampleAsync` | construct `CompleteSampleCommand`; call `IFdrsRepository.CompleteSampleAsync` |
| `RecoverInterruptedSampleAsync` | construct `RecoverSampleCommand`; call `IFdrsRepository.RecoverInterruptedSampleAsync` |
| restart start/end | `FdrsRecordDraft` with `SoftwareRestartStartedPayload` / `SoftwareRestartCompletedPayload`; `AppendRecordAsync` |
| session start/decision/end | `FdrsRecordDraft` with `SessionStartedPayload` / `SessionAccessDecisionPayload` / `SessionEndedPayload`; `AppendRecordAsync` |
| annotation | `FdrsRecordDraft` with `EventAnnotationAddedPayload(EventAnnotation)`; `AppendRecordAsync` |

Every append uses a deterministic operation correlation ID and retries with the identical draft. A new correlation for the same logical operation is prohibited. The returned FDRS receipt/result is the only acceptance evidence.

#### Exact hook ownership

- **Sample acceptance:** refactor the `SampleCollector` `BeginCollecting -> CollectingSample` transition so the analyzer asynchronously calls `AcceptSampleAsync` after it has a stable actor/session/configuration and after device insertion is detected, but before `CreateNewScanSeries`, acquisition, or a visible accepted state. A non-accepted/ambiguous result prevents acquisition. The current `StartAnalysis` RPC is intent, not Event start.
- **Terminal result:** refactor `SampleCollectionManager.OnSampleCollected` from `async void` into an awaited workflow. After classification and approved alarm mapping, call `CompleteSampleAsync` once for the accepted ID/correlation. `Clear`, `Alarm`, and `Failure` are the only terminal values. Legacy scan persistence may provide an opaque retained-data ID but is not the report commit.
- **Crash recovery:** startup calls `RecoverInterruptedSampleAsync` before session recovery or writer readiness. It closes the same Event ID as `Failure`.
- **Restart:** `MicroServicesHostedService` creates one restart correlation when startup/restart is requested and passes it into the analyzer `ServiceHost`; the analyzer background lifecycle calls the typed start method before report initialization and completion only after storage, hardware identity, session bridge, algorithm warmup, and reconciliation succeed or are known to have failed.
- **Sessions:** only a separately published trusted UserManagement bridge may call the three session methods. Denied attempts have a stable user identity/attempt correlation but no fabricated session ID. Events join sessions only by exact `SessionId`.
- **Annotations:** only an explicit authorized report-annotation command may call `AddEventAnnotationAsync` after the target Event is committed. Existing `AnnotationData` is not serialized into FDRS; until such a command exists, D1 `event.annotation = Unknown` with no value is the sole mapping.
- **Alarm reasons:** only the owner/SME-approved mapper may create `AlarmReason(EncodedCode, Strength)`. Detection/display names, compounds, quantities, peaks, scores, and free text are prohibited. Because published FDRS requires at least one reason for `Alarm`, writer readiness remains disabled until that mapper is published and configured.

### 3. Exact query boundary

The required shared API is the independently published `Reports.ReportSources.Contracts.IFdrsReportSourceQuery`, separate from `IFdrsRepository`, with these D1 operations:

```csharp
Task<ReportSourceQueryResultV1> QueryEquipmentAsync(
    EquipmentReportSourceRequestV1 request,
    ReportSourcePageRequestV1 page,
    CancellationToken cancellationToken);
Task<ReportSourceQueryResultV1> QueryEventAsync(
    EventReportSourceRequestV1 request,
    ReportSourcePageRequestV1 page,
    CancellationToken cancellationToken);
Task<ReportSourceQueryResultV1> QueryUserAsync(
    UserReportSourceRequestV1 request,
    ReportSourcePageRequestV1 page,
    CancellationToken cancellationToken);
```

These names/signatures are the frozen integration target, not a claim that the current dirty D1 worktree is published. Before TQ-011B starts, Reviewer Integration must record the accepted D1 SHA and confirm these exact public symbols. A published mismatch requires an ADR amendment.

The D2 provider class is frozen as `Reports.Persistence.DataService.DataServiceFdrsReportSourceQuery` in project `Reports.Persistence.DataService`. It implements only `IFdrsReportSourceQuery`, uses `ITransactionalDocumentStore`/published FDRS collections internally, and is registered in `SubstanceAnalyzerCore.Service.ServiceHost`. Product code depends only on the interface. D2 publication must confirm this exact class/project; a mismatch requires review.

The analyzer exposes an in-process `AnalyzerReportSourceQueryFacadeV1` to future report orchestration. It injects `IFdrsReportSourceQuery`, the activation binding, and readiness gate; supplies the exact machine/zone; maps D1 results to [outcomes.md](outcomes.md); and returns D1 immutable pages unchanged. It does not add a Kestrel/HTTP/gRPC endpoint, cast the provider, use a service locator, or access storage collections.

### 4. Machine identity

Authoritative input is `InstrumentManagerClient.DeviceSnapshot.SerialNumber` after the hardware client reports a connected reconciled snapshot. `Environment.MachineName`, UI labels, legacy sample metadata, and workstation timestamps are prohibited.

The exact mapping is `MachineId = "tq." + lowercaseHex(SHA256(UTF8(NFC(serial))))`. The source serial must be nonempty, have no leading/trailing whitespace or control characters, and contain at most 128 Unicode scalars before hashing. There is no case folding. The activation record stores only the derived controlled ID and algorithm version `tq-machine-v1`, not the raw serial.

- invalid/empty/unreconciled serial: `IdentityInvalid` or `SourceUnavailable`; writers/queries disabled;
- a second distinct serial observed in one activation attempt or duplicate activation binding: `IdentityCollision`;
- derived ID different from the committed activation binding after `T0`: `MachineMismatch`; disable immediately, do not merge partitions;
- instrument replacement: owner-reviewed new activation/T0/partition. Existing records are preserved under the old identity.

### 5. Reporting zone and trusted time

TQ-011B adds one deployment setting, `ReportsV1:ReportingZoneId`, read only by the analyzer. Empty/unknown IDs return `ZoneInvalid`. Resolve with `TimeZoneInfo.FindSystemTimeZoneById` at activation. The OS/.NET time-zone database owns rules.

The activation record binds a `tq-zone-v1` SHA-256 fingerprint of an invariant serialization of: zone ID, base UTC offset ticks, `SupportsDaylightSavingTime`, and every adjustment rule ordered by start/end date with daylight delta and both transition definitions. The current fingerprint must match on every startup and before admitting a first query page. A rule change disables readiness until an owner-controlled reactivation decision; stored UTC is never rewritten.

All producer instants come from injected `TimeProvider.GetUtcNow()` or from the FDRS repository's monotonic logical boundary. `DateTime.Now`, `DateTimeOffset.Now`, scan-local timestamps, UI time, and instrument workstation time are not authoritative. A non-UTC/default timestamp, clock rollback that cannot be reconciled by the persistence logical boundary, or inconsistent boundary is `SourceGap` and disables writers.

### 6. Atomicity and snapshot visibility

- Event ID allocation, start record, aggregate, high-water mark, active Event, actor/session, and configuration revision commit in one `StartSampleAsync` transaction.
- Terminal record and aggregate closure commit in one `CompleteSampleAsync`/recovery transaction for the same Event ID/correlation.
- Report visibility begins only after terminal commit. Raw scan save success/failure cannot create or remove a report Event.
- Each restart/session/annotation record is one idempotent append. Queries expose only a valid completed restart pair. A missing/conflicting pair is `SourceGap`, not a partial restart.
- D1/D2 first-page admission creates an immutable commit-watermark snapshot; paging reads that view only. Provider row/work/lease/cursor rules govern publication.
- Cancellation after a commit is accepted cannot turn that accepted write into `Canceled`. The producer resolves the deterministic receipt without honoring request cancellation, then reports the accepted result.
- Ambiguous acceptance blocks all later starts for that machine until receipt resolution or recovery proves one result. It never allocates a replacement correlation/ID.

### 7. Cutover and mixed-version behavior

The exact cutover is in [runbooks.md](runbooks.md). In summary: deploy compatible binaries with both writers and queries disabled; drain queries; quiesce submissions; require no active sample/session; validate all publication and identity/zone/clock/storage/mapping gates; prove the partition has no legacy/import state; commit `T0`; enable writers; run reconciliation/conformance probes; then enable queries.

Writer source version, D1/D2 contract version, activation identity/zone fingerprint, and configuration revision must match. Any mixed version returns `SourceUnavailable` and disables both sides. Query-first activation is prohibited.

### 8. Restart/reconciliation

At startup readiness is disabled. Initialize schema/capabilities, bind identity/zone, resolve append receipts, recover an active sample as `Failure`, then recover the owning session as `Incomplete`/recovery only after that terminal Event. Close any prior uncompleted restart attempt with the controlled failure code allowed by the published mapping, append the new restart start, wait for dependencies and algorithm warmup, reconcile, append restart completion, then enable.

The durable checkpoint is the last accepted machine partition version/high-water Event ID plus deterministic append-receipt correlations. Time, filename, local sample number, enum ordinal, or in-memory counters are not checkpoints. Pass threshold is exact: zero duplicate IDs, zero discontinuities within committed native IDs, zero conflicting terminals, zero orphaned session links, zero machine/zone/config mismatches, and every ambiguous receipt resolved. Any nonzero count is a non-ready outcome.

### 9. Rollback

- **Before `T0`:** stop services; revert the TQ-011B product commit and Reports gitlink; remove only unused additive configuration. No FDRS records exist.
- **After `T0` with zero accepted writes:** same rollback after a zero-write reconciliation proof.
- **After any accepted write:** never deploy a binary that cannot preserve/read the written schema. Disable report readiness and sample admission, preserve records, and either roll forward a compatible fix or deploy the last compatible producer/provider set. No delete, rewrite, ID reset, legacy fallback, or zone reinterpretation is permitted.
- The named TripleQuadUI product release owner in the deployment record makes the rollback call. Deployment is blocked if that person is not recorded before `T0`.

## Consequences

The decision creates a single trustworthy source and simple fail-closed support model, but it intentionally provides no pre-cutover history. TQ-011B cannot start from this ADR alone: D1/D2 publication, a trusted session bridge, approved alarm mapping, triad confirmation, and an accepted ADR SHA are mandatory gates.
