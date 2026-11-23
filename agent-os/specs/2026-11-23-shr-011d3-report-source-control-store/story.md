# SHR-011D3 - durable report-source activation and operation control store

## State and purpose

Contract-first prerequisite; **not Development-ready until Coordinator Architect, Domain Analyst, and Reviewer Integration accept this exact contract**. TQ-011B is blocked on an independently published Common.Reports commit implementing it. This story changes no TripleQuadUI or hardware behavior.

The published FDRS baseline has no API or collection for an activation/T0 binding and no durable product-operation journal. TQ-011B must not invent either in analyzer source. SHR-011D3 adds the shared persistence boundary used by all product producers and query facades.

## Ownership and exact paths

Common.Reports owns the contract, implementation, schema, and conformance tests:

- contract: `Reports.Fdrs.Application/ReportSourceControlContractsV1.cs`;
- provider: `Reports.Persistence.DataService/DataServiceReportSourceControlStoreV1.cs`;
- tests: `Reports.Persistence.DataService.Tests/ReportSourceControlStoreV1Tests.cs`;
- public interface: `IReportSourceControlStoreV1`;
- provider class: `DataServiceReportSourceControlStoreV1`;
- machine partition key: the exact controlled `MachineId`, identical to `IFdrsRepository`;
- activation rows: `fdrs_report_source_activations_v1`;
- active-generation singleton/pointer: `fdrs_report_source_activation_state_v1`;
- retry journal: `fdrs_producer_operations_v1`.

TripleQuadUI may depend on the interface only. It may not access these collections, `ITransactionalDocumentStore`, or the provider class.

## Frozen contract surface

```csharp
public interface IReportSourceControlStoreV1
{
    ValueTask<ReportSourceControlResultV1<bool>> InitializeAsync(CancellationToken cancellationToken = default);
    ValueTask<ReportSourceControlResultV1<ReportSourceActivationBindingV1?>> ReadCurrentActivationAsync(
        string machineId, string correlationId, CancellationToken cancellationToken = default);
    ValueTask<ReportSourceControlResultV1<IReadOnlyList<ReportSourceActivationBindingV1>>> ReadActivationHistoryAsync(
        string machineId, string correlationId, CancellationToken cancellationToken = default);
    ValueTask<ReportSourceControlResultV1<ReportSourceActivationBindingV1>> ActivateAsync(
        ReportSourceActivationRequestV1 request, CancellationToken cancellationToken = default);
    ValueTask<ReportSourceControlResultV1<ProducerOperationIntentV1>> CreateOrReadOperationAsync(
        CreateProducerOperationV1 request, CancellationToken cancellationToken = default);
    ValueTask<ReportSourceControlResultV1<ProducerOperationIntentV1>> CompleteOperationAsync(
        CompleteProducerOperationV1 completion, CancellationToken cancellationToken = default);
    ValueTask<ReportSourceControlResultV1<IReadOnlyList<ProducerOperationIntentV1>>> ReadPendingOperationsAsync(
        string machineId, int limit, string correlationId, CancellationToken cancellationToken = default);
}

public enum ReportSourceControlFailureV1
{
    None, StorageUnavailable, AcceptanceUnconfirmed, OperationCanceled,
    InitialStateNotEmpty, IdentityConflict, IntegrityFailure,
    UnsupportedVersion, LimitExceeded
}

public enum ReportSourceControlRetryV1 { None, RetryWhenReady, DoNotRetry }

public sealed record ReportSourceControlResultV1<T>(
    T? Value, ReportSourceControlFailureV1 Failure,
    ReportSourceControlRetryV1 Retry, string CorrelationId);
```

The published records/enums must retain these names and fields:

```text
ReportSourceActivationRequestV1
  ActivationId, MachineId, ActivatedUtc, MachineMappingVersion,
  ReportingZoneId, ReportingZoneFingerprint, ZoneFingerprintVersion,
  SourceComponentName, SourceComponentVersion, WriterContractVersion,
  QueryContractVersion, QueryProviderVersion, ControlContractVersion,
  ConfigurationRevisionId, ReplacesActivationId, ActivationReason,
  DecisionOwnerId, ApprovalReference, CorrelationId

ReportSourceActivationBindingV1
  all request fields except CorrelationId, plus Generation,
  State (Active|Superseded|RolledBack), ClosedUtc, PartitionVersion

ProducerOperationIntentV1
  MachineId, ActivationId, OperationId, OperationKind, LogicalOperationId,
  CorrelationId, DraftFingerprint, OccurredUtc, State (Pending|Accepted),
  AcceptedRecordId, AcceptedSampleEventId, PartitionVersion

CreateProducerOperationV1
  MachineId, ActivationId, OperationId, OperationKind, LogicalOperationId,
  CorrelationId, DraftFingerprint, OccurredUtc

CompleteProducerOperationV1
  MachineId, ActivationId, OperationId, CorrelationId, DraftFingerprint,
  AcceptedRecordId, AcceptedSampleEventId
```

`ActivationId`, `OperationId`, `LogicalOperationId`, owner/approval IDs, versions, and fingerprints are controlled, disclosure-safe values. Raw serials, zone rule bytes, configuration contents/paths, tokens, usernames, exception text, and provider details are prohibited.

The result mapping is closed: `None -> Ready/continue`; `StorageUnavailable` or `AcceptanceUnconfirmed -> SourceUnavailable/RetryWhenReady`; `OperationCanceled -> Canceled/None`; `InitialStateNotEmpty -> MigrationIncomplete/ContactSupport`; `IdentityConflict -> IdentityCollision/ContactSupport`; `IntegrityFailure -> SourceGap/ContactSupport`; `UnsupportedVersion -> UnknownMapping/ContactSupport`; `LimitExceeded -> LimitExceeded/ContactSupport`. Value is absent for every failure. No diagnostic string selects behavior.

## Atomic activation semantics

1. `InitializeAsync` validates capabilities and ensures all three version-1 collections before any activation read, operation intent, FDRS draft, or query.
2. `ActivateAsync` executes in the `MachineId` partition. One transaction reads the active pointer, relevant activation row, FDRS machine/event/import/receipt state, and operation journal; validates the request; inserts the immutable activation row; supersedes the predecessor when present; and replaces the pointer. The commit itself defines `T0 = ActivatedUtc`; an analyzer timestamp not committed by this transaction is not T0.
3. First activation is legal only when that same transaction proves zero Event aggregates, zero imports/import receipts, zero active Event, zero pending/accepted product operation, and no activation/migration state. The caller cannot attest to or bypass this proof. Any nonzero state returns `InitialStateNotEmpty`; unreadable/inconsistent state returns `IntegrityFailure`; neither performs a write.
4. Exact retry is idempotent: the same `ActivationId`, complete field fingerprint, and `CorrelationId` returns the committed binding. The same ID/correlation with any different field returns `IdentityConflict`; a different initial activation for a machine with an active binding does likewise.
5. `ReadCurrentActivationAsync` returns successful `null` only when both activation collections are empty. Otherwise it returns the one active binding plus its transaction partition version. Multiple active rows, pointer disagreement, generation gaps, field/fingerprint corruption, or a state transition without its successor returns `IntegrityFailure`.
6. `ReadActivationHistoryAsync` returns the complete generation-ascending immutable interval list and revalidates pointer, contiguity, states, T0 ordering, and field fingerprints in one read transaction. Zero rows is an empty success. More than 1,024 generations is `LimitExceeded`; it never truncates.
7. Generations start at 1 and increment by exactly one. An activation is immutable after commit except the atomic `Active -> Superseded` or zero-write `Active -> RolledBack` close performed while its successor/pointer is committed.
8. Cancellation observed before transaction admission returns `OperationCanceled`. Cancellation or lost acknowledgement after a possible commit triggers correlation/fingerprint resolution without the caller token; a proven commit returns the committed success, and an unresolved commit returns `AcceptanceUnconfirmed`. It never creates a replacement activation.

`ActivationId = "tq-activation-v1." + lowercaseHex(SHA256(canonical request bytes))`, where canonical request bytes are NFC UTF-8, NUL-delimited fields in the record order shown above, excluding `ActivationId` and `CorrelationId`; nullable predecessor is the literal `<null>`; `ActivatedUtc` is UTC `O` format with seven fractional digits. `CorrelationId = "tq-activation-op-v1." + lowercaseHex(SHA256(UTF8(ActivationId)))`. The provider recomputes both IDs and a separate full-field fingerprint. Same ID/correlation and identical fingerprint is the only idempotent retry. Any collision returns `IdentityConflict` and maps to local `IdentityCollision`.

## Reactivation, configuration change, and rollback

- Machine replacement always uses a new `MachineId` partition and a new generation-1 activation after owner review.
- Zone-rule, source-component version, writer/query-contract version, or legitimate configuration-revision change uses an owner-authorized successor activation in the same machine partition. `ReplacesActivationId` must identify the current active row; `ActivatedUtc` must be strictly later than its T0 and last committed source boundary.
- A successor transaction is legal only while sample/query admission is disabled and its same-partition checks find no active Event, no active granted session, no pending operation, and no unresolved receipt. It atomically closes the current interval and opens the successor, so no occurrence can fall between bindings.
- Configuration-only reactivation is legitimate only for a published `sha256:<64 lowercase hex>` manifest revision. The old configuration remains authoritative for records before successor T0; the new revision is authoritative at and after successor T0. A query spanning generations is complete only when each record matches the activation interval containing its `OccurredUtc`; otherwise it returns an integrity outcome.
- An exact re-deploy with no binding field change reuses the current activation and T0. It does not create a generation.
- Rollback never deletes or edits an activation or moves T0. The same machine-partition transaction must prove zero accepted FDRS records and zero accepted/pending operation rows in the current interval before it atomically closes that generation as `RolledBack` and creates an owner-authorized successor at a new T0 using the prior compatible field set. After any accepted write, rollback must create a compatible roll-forward successor or redeploy the last compatible binaries; it cannot reactivate an incompatible predecessor at its old T0.
- A failed/conflicting activation leaves the current pointer unchanged and readiness disabled.

## Durable operation/idempotency semantics

1. Before calling `StartSampleAsync`, `CompleteSampleAsync`, recovery, or `AppendRecordAsync`, the analyzer calls `CreateOrReadOperationAsync` with the complete canonical draft fingerprint. The intent and exact `OccurredUtc` are committed first.
2. `OperationId = lowercaseHex(SHA256(UTF8("tq-operation-id-v1\0" + ActivationId + "\0" + OperationKind + "\0" + LogicalOperationId)))`.
3. `CorrelationId = "tq-op-v1." + lowercaseHex(SHA256(UTF8(ActivationId + "\0" + OperationKind + "\0" + LogicalOperationId)))`. Event correlation GUID is RFC-4122 UUIDv5 using namespace `9e086c5d-1d82-5e3a-a0ce-9cf570bc1d91` and NFC UTF-8 name bytes `ActivationId + "\0" + OperationKind + "\0" + LogicalOperationId`; RFC network-byte order, SHA-1 truncation, version 5, and RFC variant bits are mandatory.
4. `DraftFingerprint = lowercaseHex(SHA256(UTF8("tq-operation-draft-v1\0" + OperationKind + "\0" + canonical draft fields)))`. Fields follow the published repository command/payload constructor order; strings are NFC; GUIDs use lowercase `D`; integers use invariant decimal; UTC uses `O` with seven fractional digits; enums use controlled names, never ordinals; null is `<null>`; each field is NUL-terminated; lists encode invariant count then items in required ordinal order. Common machine, occurrence, source name/version, actor/session/configuration and every typed payload/command field are included. Raw exception/provider values are not fields.
5. Exact create/retry returns the existing pending/accepted row. Same `OperationId` or `CorrelationId` with a different activation, kind, logical ID, timestamp, or draft fingerprint returns `IdentityConflict` and disables readiness.
6. After the repository receipt is resolved, `CompleteOperationAsync` atomically marks the matching intent `Accepted` and stores only controlled receipt identity. Completion is idempotent only for the identical receipt. It never changes the draft or creates a second correlation.
7. `ReadPendingOperationsAsync` returns a deterministic `OperationId`-ordinal page, limit 1-500. Startup resolves all pending rows before creating a new FDRS draft or enabling writers. An unresolved row is unavailable; a conflicting row is an integrity failure.
8. `AnalyzerReportSourceProducerV1` exclusively creates and completes sample/session/annotation journal rows. `ReportSourceLifecycleHostedServiceV1` exclusively dispatches startup/restart/recovery retries. Callers supply logical operation IDs but never retry repository calls independently.
9. The same cancellation/ambiguous-commit rule applies to operation create/complete: a proven commit is success; unresolved is `AcceptanceUnconfirmed`; no replacement ID/correlation is allocated.

Logical operation IDs are frozen as: acceptance attempt UUID for start; accepted Event correlation plus `terminal` for completion; active `SampleEventId` plus `recovery` for recovery; host startup-attempt UUID plus restart phase; trusted identity attempt/session notification ID plus phase; authorized annotation command UUID. Each UUID is generated once and committed in the operation intent before the shared repository call.

## Acceptance criteria

- Schema creation and activation create/read/pointer change are transactional in one machine partition.
- Initial activation, current/history read, 1,024/1,025 generation bound, exact retry, collision, pointer corruption, generation gap, successor quiescence, configuration-only reactivation, zero-write rollback, and post-write rollback constraints have conformance tests.
- Operation-intent exact retry, fingerprint conflict, ambiguous receipt resolution, crash between intent/repository/receipt commits, pending ordering, and accepted-row immutability have conformance tests.
- Tests prove no raw serial/configuration/zone bytes, token, username, path, exception, or provider diagnostic can enter the records or ordinary logs.
- Common.Reports publishes an immutable accepted SHA and exact test command. TQ-011B records both before branch creation.

## Non-goals

- No TripleQuadUI, hardware, simulator, gRPC/proto, FDRS report projection, legacy migration, UI, or runtime-data change.
- No automatic activation/reactivation decision; a named product release owner and approval reference are inputs.
- No deletion, repair, T0 rewrite, compatibility bypass, or direct product access to DataService collections.
