# ADR TQ-011A: authoritative TripleQuadUI report sources and producers

- **Status:** Proposed for independent Reviewer Integration acceptance
- **Decision date:** 2026-11-23
- **Planning base:** `8f99be2529ec7be4a17efb498719471a77fb82d8`
- **TripleQuadUI evidence baseline:** `26d3b174795384841b60eea987f97c7a711f8892`
- **Published Common.Reports evidence baseline:** `664a09a9427cf2ade7fc155a1844c6505890c2bc`
- **Recorded Common.DataService baseline:** `ca36e9aabb149da9ff6d02e6707bd3df77224b38`

## Context

The current analyzer starts collection synchronously from gRPC/UI state, creates a wrapping local sample number, records `Environment.MachineName`, saves a legacy scan object, and keeps annotations in mutable application objects. Those facts are not an atomic FDRS report source. The analyzer also receives an access token only for policy lookup; its UI session contains a username and token, not stable actor/session identities. The hardware client exposes health plus event/retrieval-applied serial and connection state, but no reconciliation/provenance flag. See [evidence-register.md](evidence-register.md).

The published FDRS baseline already owns atomic Sample Event allocation/start, terminal completion, interrupted-sample recovery, typed restart/session/annotation payloads, stable actor/session requirements, and DataService transactional semantics. It does **not** publish durable activation/T0 binding or product-operation-journal APIs. [SHR-011D3](../2026-11-23-shr-011d3-report-source-control-store/story.md) is therefore a contract-first prerequisite; TQ-011B may not invent analyzer-local storage. The D1 query contract and D2 provider are also required dependencies, but as of this ADR none of D1/D2/D3 has an independently accepted publication SHA. Dirty development files are deliberately not evidence for this decision.

## Decision

### 1. History is `ForwardOnlyAtCutover`

`T0` is the committed `ActivatedUtc` of one immutable activation generation: machine binding, reporting-zone binding, source/writer/query versions, and configuration revision. For generation 1 it equals, byte-for-byte, the trusted restart `OccurredUtc` captured at the actual host `StartAsync` entry; the later activation transaction makes that captured value authoritative and the first restart-start record occurs exactly at T0. Generation 1 T0 is therefore the earliest reportable occurrence, with no pre-T0 product record. An authorized successor T0 begins a new interval without erasing the prior one. Only native FDRS records that match the activation interval containing their occurrence are reportable.

- A range whose derived UTC interval starts before generation 1 T0 returns local `HistoryUnavailable`; it never returns a partial page. A missing/corrupt activation interval after T0 is `SourceGap`, not history absence.
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

### 1.1 Durable activation binding is a prerequisite, not analyzer state

SHR-011D3 freezes `IReportSourceControlStoreV1` and the Common.Reports-owned DataService collections `fdrs_report_source_activations_v1`, `fdrs_report_source_activation_state_v1`, and `fdrs_producer_operations_v1`, all in the exact controlled `MachineId` partition. TQ-011B consumes the interface only.

`TransitionActivationAsync` accepts only closed `Initial`, `Successor`, or `Rollback` mode and a compatible closed reason enum; no string/diagnostic selects behavior. Its transaction atomically inserts the immutable generation, closes the predecessor as `Superseded` or `RolledBack` when required, and moves the active pointer. The committed `ActivatedUtc` is `T0`; generation 1 must equal the captured restart occurrence, while later transitions must be strictly after every prior committed boundary. The row binds mode/reason, machine mapping/version, zone ID/fingerprint/version, authoritative source name/version, writer contract, query contract/provider, control-store contract, configuration revision, predecessor/rollback target, named decision-owner ID, and approval reference. Exact canonical retry returns the same row. Same-ID/different-fields, a second initial binding, two successors for one predecessor, or multiple active claimants is `IdentityCollision`; a missing generation, pointer disagreement without a second active claimant, or corrupt transition is `SourceGap`.

A legitimate configuration, zone-rule, source, or contract change uses typed `Successor` mode/reason and creates an owner-authorized generation at a strictly later T0; it never mutates the old generation. Records are validated against the activation interval containing their `OccurredUtc`, so a query may span generations only when every record matches its interval. Exact redeploy reuses the current generation. Rollback uses typed `Rollback/ZeroWriteRollback`, names the current and prior compatible target, and never deletes or moves T0: the transaction proves the current interval has zero accepted/pending writes, closes it as rolled back, and creates a copied compatible successor at a new T0. After a write, only compatible redeploy or roll-forward is legal.

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

`AnalyzerReportSourceProducerV1` is the sole implementation. It captures the activated machine, source, configuration revision, and `TimeProvider`; callers cannot override those fields. `SourceComponent.ComponentName` is exactly `triplequadui.substance-analyzer-core`. `SourceComponent.SoftwareVersion` is exactly the running `SubstanceAnalyzerCore.Service` assembly's `AssemblyInformationalVersionAttribute.InformationalVersion`; absent, malformed, or different-from-activation metadata is `UnknownMapping` and disables writers. The local `Trusted*V1` records contain only typed domain values needed by the corresponding method. They reject default/unknown enum values, non-UTC timestamps, inconsistent event correlation, absent stable actor/session IDs, and unapproved alarm codes before repository access. They contain no username, token, path, exception, UI model, or provider type.

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

Before every shared repository call, the producer commits the exact operation intent through SHR-011D3. Its nine-value `ProducerOperationKindV1` catalog, eight phase tokens, logical-ID grammar, CBE-v1 framing, field-order tables, SHA-256 domains, and UUIDv5 byte order are closed in that story. `OperationId`, repository correlation, Event correlation, and draft fingerprint are reproduced from those exact bytes; platform serialization, reflection order, enum ordinals, culture, or free-text phases are prohibited. Only the producer/lifecycle dispatcher retries pending intents with identical bytes; callers never retry repository calls or allocate replacement correlations. The returned FDRS receipt/result plus the accepted SHR-011D3 journal row is the only acceptance evidence.

#### Exact hook ownership

- **Sample acceptance:** refactor the `SampleCollector` `BeginCollecting -> CollectingSample` transition so the analyzer creates one acceptance-attempt UUID, durably journals it, then asynchronously calls `AcceptSampleAsync` after it has a stable actor/session/configuration and after device insertion is detected, but before `CreateNewScanSeries`, acquisition, or a visible accepted state. A non-accepted/ambiguous result prevents acquisition. The current `StartAnalysis` RPC is intent, not Event start.
- **Terminal result:** refactor `SampleCollectionManager.OnSampleCollected` from `async void` into an awaited workflow. After classification and approved alarm mapping, call `CompleteSampleAsync` once for the accepted ID/correlation. `Clear`, `Alarm`, and `Failure` are the only terminal values. Legacy scan persistence may provide an opaque retained-data ID but is not the report commit.
- **Crash recovery:** startup calls `RecoverInterruptedSampleAsync` before session recovery or writer readiness. It closes the same Event ID as `Failure`.
- **Restart:** `MicroServicesHostedService` creates one startup-attempt UUID and captures one `TimeProvider` UTC occurrence at actual `StartAsync` entry, then passes both into the analyzer `ServiceHost`. No draft is created yet. On initial cutover that exact occurrence is the requested/committed generation-1 T0; on every startup it is the restart-start occurrence. After control/FDRS storage initialization and activation binding, the lifecycle service journals/appends restart start, proving its occurrence is not before the applicable T0. Completion is appended only after pending-operation resolution, recovery, trusted dependencies, algorithm warmup, and reconciliation succeed or fail with a published controlled code.
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

The D2 provider class is frozen as `Reports.Persistence.DataService.DataServiceFdrsReportSourceQuery` in project `Reports.Persistence.DataService`. It implements only `IFdrsReportSourceQuery`, uses `ITransactionalDocumentStore`/published FDRS collections and the accepted `IReportSourceControlStoreV1` internally, and is registered in `SubstanceAnalyzerCore.Service.ServiceHost`. First-page admission binds the complete activation-history fingerprint into the immutable query snapshot/cursor and validates every occurrence against its interval; reactivation drains leases before changing the active generation. Product code depends only on interfaces. D2 publication must be a descendant of accepted D1 and D3 and confirm this exact class/project/interval behavior; a mismatch requires review.

The analyzer exposes an in-process `AnalyzerReportSourceQueryFacadeV1` to future report orchestration. It injects `IFdrsReportSourceQuery`, `IReportSourceControlStoreV1`, and the readiness gate; reads the complete validated activation history, supplies the exact machine/zone/interval context, maps D1 results to [outcomes.md](outcomes.md), and returns D1 immutable pages unchanged. It does not add a Kestrel/HTTP/gRPC endpoint, cast either provider, use a service locator, or access storage collections.

### 4. Machine identity

Authoritative input is an existing public hardware-client observation; this ADR does not claim a reconciliation flag that the snapshot type does not contain. After FDRS/control-store initialization, TQ-011B subscribes to `InstrumentManagerClient.DeviceManager.DevicesChanged`, waits for hardware-service health `Serving`, and accepts only a **subsequent** event-applied `DeviceSnapshot` whose `ConnectionState` is `Connected` and serial passes validation. The baseline proves that such snapshots are populated only from the instrument-change stream or `GetCurrentInstrumentAsync`; both call the same `Apply` path. Reading the initial/current snapshot without the post-health event is insufficient. A different valid serial observed before activation is `IdentityCollision`; after activation it is `MachineMismatch`. `Environment.MachineName`, UI labels, legacy sample metadata, and workstation timestamps are prohibited.

The exact mapping is `MachineId = "tq." + lowercaseHex(SHA256(UTF8(NFC(serial))))`. The source serial must be nonempty, have no leading/trailing whitespace or control characters, and contain at most 128 Unicode scalars before hashing. There is no case folding. The activation record stores only the derived controlled ID and algorithm version `tq-machine-v1`, not the raw serial.

- initial snapshot, no post-health applied observation, or disconnected observation: `SourceUnavailable`; invalid/empty serial in a connected applied observation: `IdentityInvalid`; writers/queries disabled;
- a second distinct serial observed in one activation attempt or duplicate activation binding: `IdentityCollision`;
- derived ID different from the committed activation binding after `T0`: `MachineMismatch`; disable immediately, do not merge partitions;
- instrument replacement: owner-reviewed new activation/T0/partition. Existing records are preserved under the old identity.

### 5. Reporting zone and trusted time

TQ-011B adds one deployment setting, `ReportsV1:ReportingZoneId`, read only by the analyzer. Empty/unknown IDs return `ZoneInvalid`. Resolve with `TimeZoneInfo.FindSystemTimeZoneById` at activation. The OS/.NET time-zone database owns rules.

The activation record binds `tq-zone-v1:` plus the lowercase SHA-256 of the exact bytes below. Integers are two's-complement big-endian; text is NFC UTF-8; booleans are one byte `00`/`01`; rule order is ascending `(DateStart, DateEnd)` and duplicate ranges are invalid.

```text
ASCII "tq-zone-v1"; 00
u32 zoneIdByteLength; zoneIdBytes
i64 BaseUtcOffset.Ticks; bool SupportsDaylightSavingTime; u32 ruleCount
for each rule:
  i32 DateStart days since 0001-01-01; i32 DateEnd days since 0001-01-01
  i64 DaylightDelta.Ticks; i64 BaseUtcOffsetDelta.Ticks
  bool NoDaylightTransitions
  transition DaylightTransitionStart; transition DaylightTransitionEnd
transition:
  bool IsFixedDateRule; i64 TimeOfDay.TimeOfDay.Ticks
  u8 Month; u8 Week; u8 Day; u8 DayOfWeek
```

Every conversion-relevant public `TimeZoneInfo` rule property is represented, including `BaseUtcOffsetDelta` and `NoDaylightTransitions`; fields ignored by a particular fixed/floating transition are still encoded. Known vectors use synthetic zones so OS data cannot change the expectation:

- `Test/UTC`, zero base, no DST/rules: bytes `74712d7a6f6e652d76310000000008546573742f55544300000000000000000000000000`; fingerprint `tq-zone-v1:931944f28d981372c39da53bc37b7eeff2ea1b1f656349fe5fb5ecdf39efd774`.
- `Test/DST`, -05:00 base, one 2020-01-01..2029-12-31 rule (day numbers 737424/741076) with +01:00 daylight, +00:30 base delta, `NoDaylightTransitions=false`, floating second Sunday March 02:00 start, and fixed November 15 02:00 end: bytes `74712d7a6f6e652d76310000000008546573742f445354ffffffd61729f8000100000001000b4090000b4ed40000000861c468000000000430e23400000000000010c388d000030201000100000010c388d0000b010f00`; fingerprint `tq-zone-v1:e06693fa35759dcef7669e1a5f0fe1d62e31a1c098d82c83d03c63178ae3a508`.

The current fingerprint must match its activation interval on every startup and before first query admission. A rule change disables readiness until owner-authorized successor activation; stored UTC is never rewritten.

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

The exact cutover is in [runbooks.md](runbooks.md). In summary: deploy compatible binaries with both writers and queries disabled; capture the actual host-start restart UUID/occurrence; drain queries; quiesce submissions; require no active sample/session; validate all publication and identity/zone/clock/storage/mapping gates; prove the partition has no legacy/import/operation state; atomically commit generation 1 with `T0 = captured restart occurrence`; append restart start at exactly T0; enable writers; run reconciliation/conformance probes; then enable queries.

Writer source version, D1/D2 query/provider version, D3 control-store version, activation identity/zone fingerprint, and configuration revision must match the applicable interval. Any known mixed runtime version returns `SourceUnavailable` and disables both sides; a stored interval mismatch is `SourceGap`. Query-first activation is prohibited.

### 8. Startup, restart, and reconciliation

One feasible order is frozen; implementations may not reorder it:

1. At actual `StartAsync` entry the host captures exactly one startup-attempt UUID and trusted restart `OccurredUtc`; analyzer constructs the authoritative source component and sets readiness `Disabled`. No FDRS draft exists.
2. Initialize SHR-011D3 and `IFdrsRepository` schemas/capabilities without a machine partition.
3. Wait for the post-health connected hardware observation; validate/derive machine, zone fingerprint, configuration revision, writer/query versions, and clock boundary.
4. Read the current activation. Initial cutover calls SHR-011D3 `TransitionActivationAsync(Initial, ForwardOnlyCutover, ActivatedUtc = captured restart OccurredUtc)`; an approved change uses typed `Successor`/reason or typed zero-write `Rollback`; ordinary restart must match the binding exactly.
5. Read and resolve every pending operation journal row and ambiguous repository receipt. Recover an active sample as `Failure`, then end its owning session as recovery/incomplete. No new draft is admitted before this completes.
6. Close a prior incomplete restart only with the published controlled failure mapping. Journal and append the current restart-start using the host-captured occurrence/source/binding; on generation 1 assert `restart-start OccurredUtc == T0`, and on every later generation assert it is not before T0.
7. Wait for trusted session bridge, approved alarm mapper, algorithm warmup, D1/D2 provider, and run exact reconciliation/conformance probes.
8. Journal/append restart completion, persist its accepted receipt, enable writers, then enable queries. Any failure remains disabled.

The durable checkpoint is the last accepted machine partition version/high-water Event ID plus SHR-011D3 pending/accepted operations. Time, filename, local sample number, enum ordinal, or in-memory counters are not checkpoints. Pass threshold is exact: zero duplicate IDs, zero discontinuities within committed native IDs, zero conflicting terminals, zero orphaned session links, zero activation/machine/zone/config/source mismatches, and every ambiguous receipt resolved. Any nonzero count is a non-ready outcome.

### 9. Rollback

- **Before `T0`:** stop services; revert the TQ-011B product commit and Reports gitlink; remove only unused additive configuration. No activation/FDRS records exist.
- **After `T0` with zero accepted writes:** never delete the activation. Call the typed `Rollback/ZeroWriteRollback` transition naming the current activation and compatible prior target; it atomically closes the current row as rolled back and commits a copied successor at a new T0, or it writes nothing and remains disabled. Revert only if selected binaries understand the retained history.
- **After any accepted write:** never deploy a binary that cannot preserve/read the written schema. Disable report readiness and sample admission, preserve records, and either roll forward a compatible fix or deploy the last compatible producer/provider set. No delete, rewrite, ID reset, legacy fallback, or zone reinterpretation is permitted.
- The named TripleQuadUI product release owner in the deployment record makes the rollback call. Deployment is blocked if that person is not recorded before `T0`.

## Consequences

The decision creates a single trustworthy source and simple fail-closed support model, but it intentionally provides no pre-cutover history. TQ-011B cannot start from this ADR alone: accepted D1/D2/D3 publication, a trusted session bridge, approved alarm/configuration mapping, triad confirmation, and an accepted ADR SHA are mandatory gates.
