# SHR-011D3 - durable report-source activation and operation control store

## State, value, and triad routing

**State: Ready for Coordinator Architect, Domain Analyst, and User Experience triad review; not Development-ready.** The triad must accept the frozen API, transition model, operator-visible closed outcomes, source ownership, child split, and validation matrix below before D3a begins. Reviewer Integration accepts the integrated publication after D3c; it does not replace the required triad.

The published FDRS baseline has no durable activation/T0 binding and no product-operation journal. TQ-011B must not invent either in analyzer source. SHR-011D3 publishes one Common.Reports boundary shared by product producers and query facades without changing TripleQuadUI, hardware, simulator, report projection, or runtime data.

## Exact repository plan and ownership

- Repository: `C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI\CommonLibraries\Reports`.
- Exact base: published Common.Reports `664a09a9427cf2ade7fc155a1844c6505890c2bc`.
- Integration branch: `feature/shr-011d3-report-source-control-store`.
- Isolated worktree: `C:\Git\Commercial\Common.Reports-shr011d3-control-store`.
- Contract/codec ownership: `Reports.Fdrs.Application/ReportSourceControlContractsV1.cs`, `Reports.Fdrs.Application/ReportSourceControlCanonicalV1.cs`, focused tests in `Reports.Fdrs.Application.Tests/ReportSourceControlCanonicalV1Tests.cs`, and language-neutral vectors at `Reports.Fdrs.Application.Tests/TestData/report-source-control-canonical-v1.json`.
- Provider ownership: `Reports.Persistence.DataService/DataServiceReportSourceControlStoreV1.cs` and focused tests in `Reports.Fdrs.Persistence.Tests/ReportSourceControlStoreV1Tests.cs`.
- Public interface: `IReportSourceControlStoreV1`; provider: `DataServiceReportSourceControlStoreV1`.
- Collections in the exact controlled `MachineId` partition: `fdrs_report_source_activations_v1`, singleton `fdrs_report_source_activation_state_v1`, and `fdrs_producer_operations_v1`.

TripleQuadUI depends on the interface only. It must not access those collections, `ITransactionalDocumentStore`, or the provider class. D3 does not edit `IFdrsRepository`, existing FDRS contracts/collections, D1/D2 query contracts, DataService abstractions, gitlinks, solution-wide props, or product code.

## Delivery split, dependencies, and role work

| Child | Size | Owner/scope | Starts after | Exit evidence |
|---|---:|---|---|---|
| D3a contract + canonical codec | 3 | Common.Reports contract owner; only the two Application files and Application tests above | triad accepts this story | public API compiles; closed enums, canonical vectors, and independent reference-vector fixture pass |
| D3b transactional provider | 5 | Common.Reports persistence owner; only the provider and persistence tests above | accepted D3a commit | activation and journal concurrency/crash/ambiguity suites pass against DataService test store |
| D3c integration/conformance/publication | 3 | Reviewer Integration; validation/review only, returning defects to the D3a/D3b owner rather than redesigning | D3a + D3b integrated | full solution, disclosure/dependency scans, clean diff, immutable accepted SHA and commands |

The split is sequential at the contract boundary; D3a and D3b must not be implemented concurrently against an unfrozen API. D1 is not a dependency. D2 and TQ-011B are downstream and remain blocked until D3c publishes. Domain Analyst confirms transition/integrity semantics; User Experience confirms the closed reason/outcome surface contains no free-text behavior selector; Coordinator Architect confirms branch, ownership, dependency direction, and integration order.

## Frozen public contract

```csharp
public interface IReportSourceControlStoreV1
{
    ValueTask<ReportSourceControlResultV1<bool>> InitializeAsync(CancellationToken cancellationToken = default);
    ValueTask<ReportSourceControlResultV1<ReportSourceActivationBindingV1?>> ReadCurrentActivationAsync(
        string machineId, string correlationId, CancellationToken cancellationToken = default);
    ValueTask<ReportSourceControlResultV1<IReadOnlyList<ReportSourceActivationBindingV1>>> ReadActivationHistoryAsync(
        string machineId, string correlationId, CancellationToken cancellationToken = default);
    ValueTask<ReportSourceControlResultV1<ReportSourceActivationBindingV1>> TransitionActivationAsync(
        ReportSourceActivationTransitionV1 transition, CancellationToken cancellationToken = default);
    ValueTask<ReportSourceControlResultV1<ProducerOperationIntentV1>> CreateOrReadOperationAsync(
        CreateProducerOperationV1 request, CancellationToken cancellationToken = default);
    ValueTask<ReportSourceControlResultV1<ProducerOperationIntentV1>> CompleteOperationAsync(
        CompleteProducerOperationV1 completion, CancellationToken cancellationToken = default);
    ValueTask<ReportSourceControlResultV1<IReadOnlyList<ProducerOperationIntentV1>>> ReadPendingOperationsAsync(
        string machineId, int limit, string correlationId, CancellationToken cancellationToken = default);
}

public enum ReportSourceActivationModeV1 { Initial, Successor, Rollback }
public enum ReportSourceActivationReasonV1
{
    ForwardOnlyCutover, MachineReplacement, ZoneRulesChanged, SourceReleaseChanged,
    ContractReleaseChanged, ConfigurationChanged, CompatibleReleaseChanged, ZeroWriteRollback
}
public enum ReportSourceActivationStateV1 { Active, Superseded, RolledBack }
public enum ProducerOperationStateV1 { Pending, Accepted }
public enum ProducerOperationKindV1
{
    SampleStart, SampleComplete, SampleRecovery, RestartStarted, RestartCompleted,
    SessionStarted, SessionAccessDecision, SessionEnded, EventAnnotationAdded
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

The records retain these exact fields in this exact order:

```text
ReportSourceActivationTransitionV1
  ActivationId, MachineId, ActivatedUtc, Mode, Reason,
  StartupAttemptId, RestartOccurredUtc,
  MachineMappingVersion, ReportingZoneId, ReportingZoneFingerprint,
  ZoneFingerprintVersion, SourceComponentName, SourceComponentVersion,
  WriterContractVersion, QueryContractVersion, QueryProviderVersion,
  ControlContractVersion, ConfigurationRevisionId, ReplacesActivationId,
  RollbackTargetActivationId, DecisionOwnerId, ApprovalReference, CorrelationId

ReportSourceActivationBindingV1
  all transition fields except CorrelationId, plus Generation, State,
  ClosedUtc, PartitionVersion

ProducerOperationIntentV1
  MachineId, ActivationId, OperationId, OperationKind, LogicalOperationId,
  CorrelationId, DraftFingerprint, OccurredUtc, State,
  AcceptedRecordId, AcceptedSampleEventId, PartitionVersion

CreateProducerOperationV1
  MachineId, ActivationId, OperationId, OperationKind, LogicalOperationId,
  CorrelationId, DraftFingerprint, OccurredUtc

CompleteProducerOperationV1
  MachineId, ActivationId, OperationId, CorrelationId, DraftFingerprint,
  AcceptedRecordId, AcceptedSampleEventId
```

`Mode`, `Reason`, `State`, and `OperationKind` are the enums above, never strings or ordinals. `Rollback` is selected only by `Mode = Rollback` and `Reason = ZeroWriteRollback`; no free text or diagnostic chooses a state transition. IDs, versions, fingerprints, owner ID, and approval reference are controlled disclosure-safe values. Raw serials, zone-rule bytes, configuration contents/paths, tokens, usernames, exception text, and provider details are prohibited.

The result mapping is closed: `None -> Ready/continue`; `StorageUnavailable` or `AcceptanceUnconfirmed -> SourceUnavailable/RetryWhenReady`; `OperationCanceled -> Canceled/None`; `InitialStateNotEmpty -> MigrationIncomplete/ContactSupport`; `IdentityConflict -> IdentityCollision/ContactSupport`; `IntegrityFailure -> SourceGap/ContactSupport`; `UnsupportedVersion -> UnknownMapping/ContactSupport`; `LimitExceeded -> LimitExceeded/ContactSupport`. Value is absent for every failure. No diagnostic string selects behavior.

## Atomic activation state machine

One `MachineId`-partition transaction reads the pointer, relevant activation/history rows, FDRS Event/import/receipt state, and operation journal; validates the complete transition; writes the new immutable row; closes the predecessor when required; and replaces the pointer. Legal transitions are only:

| Mode | Required before transaction | Atomic committed result |
|---|---|---|
| `Initial` | no activation/migration state and zero Event aggregate, import/import receipt, active Event, or pending/accepted product operation | generation 1 `Active`; pointer -> generation 1 |
| `Successor` | named current `Active` predecessor; sample/query admission disabled; no active Event/session, pending operation, unresolved receipt, or live D2 lease | predecessor `Active -> Superseded`; generation + 1 `Active`; pointer -> successor |
| `Rollback` | named current `Active` predecessor and named earlier compatible target; same quiescence proof plus zero accepted FDRS record and zero accepted/pending operation in the current interval | predecessor `Active -> RolledBack`; new generation copies the target binding fields, uses the request's new T0/owner/approval, becomes `Active`; pointer -> new generation |

No other transition, direct close, pointer-only update, delete, repair, old-T0 reactivation, or state rewrite exists. A failed transaction writes nothing and leaves readiness disabled.

Mode/reason rules are exact: `Initial` permits `ForwardOnlyCutover` or `MachineReplacement`; `Successor` permits exactly `ZoneRulesChanged`, `SourceReleaseChanged`, `ContractReleaseChanged`, `ConfigurationChanged`, or `CompatibleReleaseChanged`; `Rollback` permits only `ZeroWriteRollback`. `ReplacesActivationId` is null only for `Initial`; it is the current active ID otherwise. `RollbackTargetActivationId` is non-null only for `Rollback`. The provider compares field deltas to the reason: a single named change must change that field family only; `CompatibleReleaseChanged` permits two or more compatible source/contract/config families under one approval. A no-delta deployment reuses the current binding and does not call this API.

Generation 1 has one additional invariant: the host captures exactly one startup-attempt UUID and `RestartOccurredUtc` at actual `StartAsync` entry. `StartupAttemptId` and `RestartOccurredUtc` are required only for `Initial`; both are null for `Successor`/`Rollback`; and `ActivatedUtc` **must equal `RestartOccurredUtc` exactly**. The activation transaction commits that value as generation-1 `T0`; it is not replaced by transaction wall-clock time. The initial-empty proof guarantees there is no report record before T0. The first permitted operation must be `RestartStarted`, its logical ID must be `restart/<StartupAttemptId>/started`, and its `OccurredUtc` must equal T0; `CreateOrReadOperationAsync` rejects anything else as `IdentityConflict`. No operation may be created before initial activation commits. Successor/rollback T0 must be strictly later than the prior T0, every committed occurrence/source boundary, and the transaction's last observed logical boundary.

Exact transition retry is idempotent only when `ActivationId`, `CorrelationId`, mode, reason, predecessor/target, and the complete canonical fingerprint match the already committed transition. Reusing either ID with any different field is `IdentityConflict`. A different ID that attempts to replace an already closed predecessor, a second initial activation, or a second successor for the same predecessor is also `IdentityConflict`. Multiple rows claiming `Active` is persisted-identity collision and returns `IdentityConflict`; a missing generation, pointer disagreement without a second active claimant, corrupt fingerprint, illegal state edge, or absent successor returns `IntegrityFailure`.

`ReadCurrentActivationAsync` returns successful `null` only when both activation collections are empty. `ReadActivationHistoryAsync` returns the complete generation-ascending interval list and verifies pointer, contiguity, state edges, T0 ordering, and fingerprints in one read transaction. Zero rows is an empty success; 1,025 or more is `LimitExceeded`, never truncation. Cancellation before transaction admission is `OperationCanceled`; cancellation/lost acknowledgement after possible commit resolves the exact ID/fingerprint without the caller token. Proven commit is success; unresolved commit is `AcceptanceUnconfirmed`; no replacement ID is allocated.

## Canonical Bytes Encoding v1

Every identity below uses **CBE-v1**, not platform serialization. `F(tag,payload) = tag (one byte) || payloadLength (unsigned 32-bit big-endian) || payload`. Scalar tags are: `01` text, `02` UTC instant, `03` enum token, `04` GUID, `05` signed integer, `06` boolean, `07` null, `08` list. Text payload is NFC UTF-8 with no BOM. UTC payload is ASCII invariant `yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'` after conversion to UTC. Enum payload is its exact token below. GUID payload is lowercase ASCII `D`. Integer payload is shortest invariant ASCII decimal (`0`, no leading zero or plus). Boolean payload is one byte `00` or `01`. Null has zero length. A list payload is `count` as unsigned 32-bit big-endian followed by its fully framed items. No separator, terminal NUL, culture, reflection order, JSON, or enum ordinal is used.

A hash preimage is `ASCII(domain) || 00 || F(field1) || ... || F(fieldN)`. SHA-256 output is 64 lowercase hexadecimal characters. Activation field order is the `ReportSourceActivationTransitionV1` order above excluding `ActivationId` and `CorrelationId`; nullable predecessor/target use tag `07`. Enum tokens are the lowercase kebab-case member names, for example `initial`, `zero-write-rollback`, and `sample-start`.

- `ActivationId = "tq-activation-v1." + hex(SHA256(preimage("tq-activation-id-v1", activation fields)))`.
- activation full-field fingerprint is `hex(SHA256(preimage("tq-activation-fingerprint-v1", activation fields)))`.
- activation `CorrelationId = "tq-activation-op-v1." + hex(SHA256(preimage("tq-activation-correlation-v1", text ActivationId)))`.
- `OperationId = "tq-operation-v1." + hex(SHA256(preimage("tq-operation-id-v1", ActivationId, OperationKind token, LogicalOperationId)))`.
- operation `CorrelationId = "tq-op-v1." + hex(SHA256(preimage("tq-operation-correlation-v1", ActivationId, OperationKind token, LogicalOperationId)))`.
- Event correlation is RFC-4122 UUIDv5 namespace `9e086c5d-1d82-5e3a-a0ce-9cf570bc1d91` over the exact CBE-v1 preimage with domain `tq-event-correlation-v1` and the same three operation fields; namespace and digest use RFC network byte order, SHA-1 truncation, version 5, and RFC variant bits.

The provider recomputes all identities and rejects a mismatch as `IdentityConflict`. D3a publishes at least three byte-preimage/hash vectors (ASCII-only, Unicode normalization, and null/list) in source and a language-neutral UTF-8 fixture; tests must construct the bytes independently rather than call the production encoder.

Normative ASCII identity vector: `ActivationId = "tq-activation-v1." + 64*"0"`, kind `SampleStart`/token `sample-start`, and logical ID `acceptance/00000000-0000-0000-0000-000000000001` produce:

```text
OperationId = tq-operation-v1.15c1b511870435266a13f6c6fb739cbf492a218794f5a0dc6b0f9d8f9781fae7
CorrelationId = tq-op-v1.be28a1ba61de4861d4a6ee4ec14590d793f8d3da3227ce25085a4e5320489999
EventCorrelationId = c7026fd0-b7ea-54c7-8db3-457f785f639a
```

Two independent implementations must reproduce these values before D3a acceptance.

## Closed operation catalog and logical IDs

No operation kind or phase is caller text. The exact kind token, logical-ID grammar, and phase token are:

| Kind | Kind token | LogicalOperationId | Phase token |
|---|---|---|---|
| `SampleStart` | `sample-start` | `acceptance/<lowercase-D acceptance UUID>` | `acceptance` |
| `SampleComplete` | `sample-complete` | `event/<lowercase-D EventCorrelationId>/terminal` | `terminal` |
| `SampleRecovery` | `sample-recovery` | `sample/<positive invariant SampleEventId>/recovery` | `recovery` |
| `RestartStarted` | `restart-started` | `restart/<lowercase-D startup-attempt UUID>/started` | `started` |
| `RestartCompleted` | `restart-completed` | `restart/<lowercase-D startup-attempt UUID>/completed` | `completed` |
| `SessionStarted` | `session-started` | `session-attempt/<lowercase-D attempt UUID>/started` | `started` |
| `SessionAccessDecision` | `session-access-decision` | `session-attempt/<lowercase-D attempt UUID>/decision` | `decision` |
| `SessionEnded` | `session-ended` | `session/sha256:<hex(SHA256(NFC UTF-8 SessionId))>/ended` | `ended` |
| `EventAnnotationAdded` | `event-annotation-added` | `annotation/<lowercase-D authorized command UUID>/added` | `added` |

The parser accepts only the row selected by the enum kind, exact lowercase literals, exact slash count, and canonical number/GUID/hash form. IDs/keys are generated once before the intent call; retry never generates another. The phase catalog is exactly `acceptance`, `terminal`, `recovery`, `started`, `completed`, `decision`, `ended`, `added`.

## Exact draft fingerprint

`DraftFingerprint = "sha256:" + hex(SHA256(preimage("tq-operation-draft-v1", common fields, payload fields)))`. Common fields are always, in order: operation-kind enum, schema version integer `1`, `MachineId`, `OccurredUtc`, nullable `UserId`, nullable `SessionId`, nullable `ConfigurationRevisionId`, `Source.ComponentName`, `Source.SoftwareVersion`. The derived repository correlation is excluded to avoid a cycle. Payload fields are exactly:

| Kind | Ordered payload fields |
|---|---|
| `SampleStart` | `EventCorrelationId`, `StartUtc`, `UserId`, `SessionId`, `ConfigurationRevisionId` |
| `SampleComplete` | `SampleEventId`, `EventCorrelationId`, `EndUtc`, result enum, alarm-reason list, nullable retained-data reference, `TimestampQualityCode`, `RecoveryProvenanceCode`, fixed `ImportProvenanceCode` text `native` |
| `SampleRecovery` | `ObservedUtc` |
| `RestartStarted` | `RestartCorrelationId` |
| `RestartCompleted` | `RestartCorrelationId`, `StartUtc`, `EndUtc`, status enum, nullable failure code |
| `SessionStarted` | `AttemptCorrelationId` |
| `SessionAccessDecision` | `AttemptCorrelationId`, decision enum, decision code |
| `SessionEnded` | `StartUtc`, `EndUtc`, reason enum, interrupted-sample-failure-recorded boolean |
| `EventAnnotationAdded` | `AnnotationId`, `TargetMachineId`, `TargetSampleEventId`, `AuthorUserId`, `AuthorSessionId`, `CreatedUtc`, normalized content, nullable `SupersededAnnotationId` |

Alarm reasons are a tag-`08` list sorted ordinally by encoded code; each item is a tag-`08` two-item list of encoded-code text then strength enum. Other enum tokens are their exact lowercase kebab-case member names. Duplicate alarm codes or noncanonical list order are rejected before hashing. `OccurredUtc` equals the repository command/draft occurrence (`StartUtc`, `EndUtc`, or `ObservedUtc` for the three sample commands); repeated command fields remain deliberately included. These tables, not constructor/reflection order, are authoritative.

Normative draft vector: kind `RestartStarted`, schema `1`, `MachineId = "tq." + 64*"0"`, occurrence `2026-11-23T12:34:56.0000000Z`, null user/session, `ConfigurationRevisionId = "sha256:" + 64*"1"`, source `triplequadui.substance-analyzer-core` version `1.2.3`, and restart correlation `11111111-1111-1111-1111-111111111111` produce `DraftFingerprint = sha256:a72bbfdb2b33b67bc17eb54f0aa051950996fd5abde09e969c526a5f8b1ff128`. Independent fixture code must reproduce it without calling the production encoder.

## Durable operation semantics

1. Before `StartSampleAsync`, `CompleteSampleAsync`, recovery, or `AppendRecordAsync`, the analyzer commits `CreateOrReadOperationAsync` with the complete canonical fingerprint and exact occurrence. In generation 1 the provider admits no operation until the required first `RestartStarted` operation matches the activation's startup ID and T0.
2. Exact create/retry returns the existing pending or accepted row. Same `OperationId` or `CorrelationId` with different activation, kind, logical ID, occurrence, or fingerprint is `IdentityConflict`; nothing is overwritten.
3. After repository receipt resolution, `CompleteOperationAsync` atomically changes only `Pending -> Accepted` and stores controlled receipt identity. Identical completion is idempotent. Different receipt, completion from any other state, or mutation after acceptance is `IdentityConflict`.
4. `ReadPendingOperationsAsync` returns an `OperationId` ordinal page, limit 1-500. Startup resolves every pending row before a new draft or readiness. Unresolved acceptance is `StorageUnavailable`/`AcceptanceUnconfirmed`; conflicting evidence is `IntegrityFailure` unless the conflict is a reused operation/correlation identity, which is `IdentityConflict`.
5. `AnalyzerReportSourceProducerV1` alone creates/completes sample/session/annotation rows. `ReportSourceLifecycleHostedServiceV1` alone dispatches startup/restart/recovery retries. Callers never retry the repository independently.
6. Ambiguous commit handling is the same as activation: resolve exact IDs/fingerprint without the canceled token, return proven success, otherwise `AcceptanceUnconfirmed`; never allocate a replacement.

## Acceptance and publication gate

- Contract tests exhaust every enum value, illegal mode/reason/delta pair, legal state edge, exact retry, ID/correlation collision, second-initial/same-predecessor collision, multiple-active collision, pointer/generation/fingerprint integrity failure, 1,024/1,025 history bound, and cancellation/ambiguous commit race.
- Generation-1 tests prove `T0 == captured restart OccurredUtc`, first restart-start `OccurredUtc == T0`, and no operation/record can exist with `OccurredUtc < T0`. Successor/rollback tests prove strict later boundaries.
- Operation tests exhaust nine kinds, eight phase tokens, logical-ID grammar, CBE vectors, UUIDv5 vector, draft field/list/null normalization, crash at intent/repository/receipt boundaries, deterministic pending order, and accepted-row immutability.
- Disclosure tests prove prohibited serial/configuration/zone/token/username/path/exception/provider values cannot enter control rows or ordinary logs.
- From the D3 worktree, D3c records successful exact commands:

```powershell
dotnet test .\Reports.Fdrs.Application.Tests\Reports.Fdrs.Application.Tests.csproj -c Release
dotnet test .\Reports.Fdrs.Persistence.Tests\Reports.Fdrs.Persistence.Tests.csproj -c Release
dotnet build .\Reports.Persistence.DataService\Reports.Persistence.DataService.csproj -c Release
dotnet test .\Common.Reports.sln -c Release
git diff --check
git status --short --branch
```

Publication is blocked until Coordinator Architect, Domain Analyst, and User Experience record triad acceptance; Reviewer Integration confirms only owned paths changed, dependency direction remains product -> interface -> provider -> DataService abstraction, every command passes, canonical fixtures reproduce independently, and the branch is clean. Reviewer Integration then records the immutable accepted Common.Reports SHA and commands for D2/TQ-011B; no merge or gitlink movement is part of this story's planning approval.

Implementation rollback before publication is a branch revert of only D3-owned files. If a deployment has created any D3 row, no schema/data rollback or incompatible binary is allowed: readiness remains disabled and the last compatible accepted Common.Reports SHA is restored or a compatible roll-forward is published. No collection delete, activation edit, T0 rewrite, operation reset, or direct product repair is permitted.

## Non-goals

- No TripleQuadUI, hardware, simulator, gRPC/proto, D1/D2 projection, legacy migration, UI, runtime-data, gitlink, status-board, or backlog change.
- No automatic activation decision; typed mode/reason plus named product release owner and approval reference are required inputs.
- No deletion, repair, compatibility bypass, old-T0 reactivation, diagnostic-text branching, or direct product access to DataService collections.
