# SHR-011D3a - product-neutral report-source control contract, codec, and conformance

## State, size, dependency, and ownership

**State: triad-ready; not Development-ready until the exact base is published live. Size: 5 points.**

- Repository: Common.Reports.
- Required exact base: `72fe39bdcc5ef494673c6f49180e26f31758a3dc`, containing accepted SHR-011D1. Implementation is prohibited until `git ls-remote origin refs/heads/master` returns that exact SHA.
- Branch/worktree: `feature/shr-011d3a-control-contract`; `C:\Git\Common.Reports-shr011d3a-control-contract`.
- Owned paths: new package-free `Reports.ReportSourceControl.Contracts/**`; new package-free `Reports.ReportSourceControl.Contracts.Conformance/**`; tests under matching `*.Tests/**`; `docs/report-source-control/v1/**`; additive `Common.Reports.sln` entries only.
- No provider, FDRS repository, D1/D2, product, DataService, UI, hardware, runtime, gitlink, schema, or generated-code change.

Feature Engineering owns implementation. Reviewer Integration independently accepts the exact commit. D3b starts only after D3a is reviewed and published.

## Product-neutral core and closed profile boundary

The shared core uses `ReportSourceProducerProfileIdV1`, `OperationKindCodeV1`, `LogicalOperationIdV1`, and `ProfileBindingFingerprintV1` controlled values. It contains no TQ operation enum, TQ prefix, TQ payload field list, or TQ domain string.

```csharp
public interface IReportSourceProducerProfileV1
{
    ReportSourceProducerProfileIdV1 ProfileId { get; }
    int ProfileVersion { get; }
    ReportSourceProfileValidationV1 ValidateActivation(ReportSourceActivationTransitionV1 value);
    ReportSourceProfileValidationV1 ValidateOperation(CreateProducerOperationV1 value);
    ReportSourceReceiptShapeV1 GetReceiptShape(OperationKindCodeV1 kind);
    ReportSourceRetryPolicyV1 GetNotAcceptedPolicy(OperationKindCodeV1 kind,
        PermanentRejectionCodeV1 rejection);
}
```

The provider receives an immutable, duplicate-free profile registry at composition. Unknown profile ID/version is `UnsupportedVersion / DoNotRetry`; there is no default profile. TQ-011B supplies the separately reviewed `tq-report-source-v1` edge mapping and must reproduce the existing `tq-operation-v1`, `tq-op-v1`, UUIDv5, zone, and draft vectors without moving TQ semantics into Common.Reports. Other products require their own reviewed profile and vectors.

## Public API

```csharp
public interface IReportSourceControlStoreV1
{
    ValueTask<ReportSourceControlResultV1<bool>> InitializeAsync(CancellationToken token = default);
    ValueTask<ReportSourceControlResultV1<ReportSourceActivationBindingV1?>> ReadCurrentActivationAsync(
        MachineIdV1 machineId, SupportCorrelationV1 support, CancellationToken token = default);
    ValueTask<ReportSourceControlResultV1<ReportSourceActivationHistoryV1>> ReadActivationHistoryAsync(
        MachineIdV1 machineId, SupportCorrelationV1 support, CancellationToken token = default);
    ValueTask<ReportSourceControlResultV1<ReportSourceActivationBindingV1>> TransitionActivationAsync(
        ReportSourceActivationTransitionV1 transition, CancellationToken token = default);
    ValueTask<ReportSourceControlResultV1<ProducerOperationV1>> CreateOrReadOperationAsync(
        CreateProducerOperationV1 request, CancellationToken token = default);
    ValueTask<ReportSourceControlResultV1<ProducerOperationV1>> ResolveOperationAsync(
        ResolveProducerOperationV1 request, CancellationToken token = default);
    ValueTask<ReportSourceControlResultV1<ProducerOperationV1>> RetryProvenNotAcceptedAsync(
        RetryProducerOperationV1 request, CancellationToken token = default);
    ValueTask<ReportSourceControlResultV1<ProducerOperationPageV1>> ReadPendingOperationsAsync(
        ReadPendingOperationsV1 request, CancellationToken token = default);
    ValueTask<ReportSourceControlResultV1<QueryAdmissionLeaseV1>> AcquireQueryLeaseAsync(
        AcquireQueryLeaseV1 request, CancellationToken token = default);
    ValueTask<ReportSourceControlResultV1<QueryAdmissionLeaseV1>> ReleaseQueryLeaseAsync(
        ReleaseQueryLeaseV1 request, CancellationToken token = default);
    ValueTask<ReportSourceControlResultV1<QueryLeasePageV1>> ReadQueryLeasesAsync(
        ReadQueryLeasesV1 request, CancellationToken token = default);
}
```

### Explicit append-only ordinals

Every public and stored enum has explicit values; new values append only. JSON/wire codes are exact lowercase kebab case, case-sensitive, and numeric input is forbidden.

```text
ActivationMode: Initial=1, Successor=2, Rollback=3
ActivationReason: ForwardOnlyCutover=1, MachineReplacement=2, ZoneRulesChanged=3,
  SourceReleaseChanged=4, ContractReleaseChanged=5, ConfigurationChanged=6,
  CompatibleReleaseChanged=7, ZeroWriteRollback=8
ActivationState: Active=1, Superseded=2, RolledBack=3
OperationState: Pending=1, Accepted=2, ProvenNotAccepted=3
OperationResolution: Accepted=1, ProvenNotAccepted=2
NotAcceptedDisposition: RetrySameIdentity=1, AbortActivation=2
LeaseState: Active=1, Released=2, Expired=3
Status: Success=1, Unavailable=2, Canceled=3, Rejected=4, IntegrityBlocked=5,
  Unsupported=6, LimitExceeded=7
Reason: None=0, StorageUnavailable=1, AcceptanceUnconfirmed=2, OperationCanceled=3,
  InitialStateNotEmpty=4, IdentityConflict=5, IntegrityFailure=6,
  UnsupportedVersion=7, LimitExceeded=8, TransitionNotQuiescent=9,
  LeaseConflict=10, PermanentRejection=11
Retry: None=0, RetryWhenReady=1, RestartQuery=2, DoNotRetry=3
```

Unknown numbers/tokens/case and undefined combinations are invalid at construction and strict deserialization.

## Records and exact field order

The codec and stored DTOs use this order, never reflection order:

```text
ActivationTransition:
  ContractVersion, ActivationId, MachineId, ActivatedUtc, Mode, Reason,
  ProducerProfileId, ProducerProfileVersion, ProfileBindingFingerprint,
  StartupAttemptId?, RestartOccurredUtc?, MachineMappingVersion,
  ReportingZoneId, ReportingZoneFingerprint, ZoneFingerprintVersion,
  SourceComponentName, SourceComponentVersion, WriterContractVersion,
  QueryContractVersion, QueryProviderVersion, ControlContractVersion,
  ConfigurationRevisionId, ReplacesActivationId?, RollbackTargetActivationId?,
  DecisionOwnerId, ApprovalReference, InternalCorrelation, SupportCorrelation

ActivationBinding:
  every ActivationTransition field except both correlations, then Generation,
  State, ClosedUtc?, PartitionVersion, CanonicalFingerprint

Operation:
  ContractVersion, MachineId, ActivationId, ProducerProfileId, ProducerProfileVersion,
  OperationId, OperationKindCode, LogicalOperationId, InternalCorrelation,
  SupportCorrelation, DraftFingerprint, OccurredUtc, State, AttemptOrdinal,
  AcceptedRecordId?, AcceptedSampleEventId?, RepositoryReceiptId?,
  AcceptanceProofFingerprint?, PermanentRejectionCode?, NotAcceptedDisposition?,
  ResolvedUtc?, PartitionVersion

QueryLease:
  ContractVersion, LeaseId, MachineId, SnapshotId, OwnerId,
  ActivationHistoryFingerprint, AcquiredUtc, ExpiresUtc, ReleasedUtc?,
  State, PartitionVersion, InternalCorrelation, SupportCorrelation
```

Collections in public values are immutable defensive copies and structural equality is required. Default `ToString()` for every record/result prints only type, status/reason/retry, count, and support correlation. It must never print machine, activation, profile binding, operation, lease, snapshot, owner, approval, internal correlation, receipt, fingerprint, source/provider/store, exception, or caller input.

## Closed result tuples and method-specific success

`ReportSourceControlResultV1<T>` fields are exactly `Status`, `Reason`, `Retry`, `Value`, `SupportCorrelation`. Factories are internal; the public constructor validates the matrix.

| Status | Legal reason | Retry | Value |
|---|---|---|---|
| `Success` | `None` | `None` | method-specific, below |
| `Unavailable` | `StorageUnavailable`, `AcceptanceUnconfirmed` | `RetryWhenReady` | null |
| `Canceled` | `OperationCanceled` | `None` | null |
| `Rejected` | `InitialStateNotEmpty`, `IdentityConflict`, `PermanentRejection` | `DoNotRetry` | null |
| `IntegrityBlocked` | `IntegrityFailure`, `TransitionNotQuiescent`, `LeaseConflict` | `DoNotRetry` | null |
| `Unsupported` | `UnsupportedVersion` | `DoNotRetry` | null |
| `LimitExceeded` | `LimitExceeded` | `DoNotRetry` | null |

No wildcard tuple exists. Method successes are exact: initialize=`true`; current activation=one binding or null only when both pointer and history are empty; history=non-null 0..1,024 list plus fingerprint; transition=one non-null binding; create/resolve/retry=one non-null operation; pending read=non-null 0..500 page; acquire/release=one non-null lease; lease read=non-null 0..500 page. A successful `ResolveOperationAsync(ProvenNotAccepted)` returns the controlled operation in `ProvenNotAccepted` state; `PermanentRejection` result failure is reserved for an illegal retry/operation request against a terminal AbortActivation row. `false`, null where not explicitly allowed, or an empty list does not mean Ready. Every failure has null value and zero payload bytes outside controlled status fields.

Downstream mapping is closed: storage/acceptance -> `SourceUnavailable / RetryWhenReady`; canceled -> `Canceled / None`; initial-not-empty -> `MigrationIncomplete / ContactSupport`; identity -> `IdentityCollision / ContactSupport`; integrity/quiescence/lease -> `SourceGap / ContactSupport`; unsupported -> `UnknownMapping / ContactSupport`; limit -> `LimitExceeded / ContactSupport`; permanent rejection -> `SourceGap / ContactSupport`. Invalid caller input is replaced by a newly generated safe `SupportCorrelationV1`; it is never reflected.

## Exact scalar and population bounds

Construction and strict deserialization enforce both scalar count and UTF-8 byte count. Unless stated as canonical Unicode, fields are ASCII and reject control/space, trimming, normalization changes, and alternate case.

| Type/field | Exact syntax and bound |
|---|---|
| contract/schema/partition/profile versions | integer `1` only; no zero/future value |
| machine ID | ASCII `[a-z0-9][a-z0-9._-]{0,95}`; 1..96 bytes; profile may narrow |
| activation/operation/lease/snapshot IDs | ASCII `[a-z0-9][a-z0-9._:-]{0,127}`; 1..128 bytes; exact profile prefix validated |
| profile ID | lowercase ASCII `[a-z][a-z0-9.-]{2,63}`; 3..64 bytes |
| operation kind code | lowercase kebab ASCII `[a-z][a-z0-9-]{0,47}`; 1..48 bytes |
| logical operation ID | canonical profile grammar; ASCII 1..192 bytes |
| zone ID | case-sensitive ASCII `[A-Za-z0-9._+/-]{1,127}`; 1..128 bytes |
| component name | lowercase ASCII `[a-z][a-z0-9.-]{2,95}`; 3..96 bytes |
| semantic/component version | ASCII SemVer 2 without build metadata; 1..64 bytes |
| mapping/config/owner/approval references | controlled opaque ASCII `[A-Za-z0-9][A-Za-z0-9._:/-]{0,127}`; 1..128 bytes |
| SHA fingerprint | exact lowercase `sha256:` plus 64 hex; 71 bytes |
| UUID | canonical lowercase `D`; 36 bytes |
| internal correlation | deterministic, profile/core canonical ASCII; 1..128 bytes |
| support correlation | random UUID rendered `support:<lowercase-D>`; 44 bytes; no derivation from protected data |
| timestamps | UTC only, offset zero, 100ns precision, years 2000..9999; canonical `yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'` |
| history | 0..1,024 complete rows; never paged/truncated |
| pending operations / lease page | requested limit 1..500; stored operations maximum 100,000 and leases maximum 10,000 per machine partition; N+1 is `LimitExceeded` before writes |
| operation attempts | 1..32 per operation; same identity and fingerprint only |

All nullable fields have an explicit legality rule in the transition, operation, and receipt tables; empty string/collection never substitutes for null. Tests cover N-1/N/N+1 construction and strict deserialization for every row, including scalar characters, UTF-8 byte overflow, timestamps, populations, enum numbers/tokens/case, nullability, and future versions.

## Product-neutral activation and lease contract

Legal transitions remain `Initial`, `Successor`, and `Rollback`. Initial creates generation 1 and requires empty history/FDRS/control evidence. Successor closes current Active as Superseded. Zero-write Rollback closes current Active as RolledBack and creates a new generation copying the compatible target's immutable binding while using the request's new T0/owner/approval. It never reactivates or edits the target. Mode/reason/delta rules from the accepted ADR remain exhaustive.

Generation 1 requires `ActivatedUtc == RestartOccurredUtc`; the first profile operation is the profile-defined restart-start identity at exactly T0. Successor/rollback T0 is strictly greater than every prior T0, committed occurrence/source boundary, and last resolved operation occurrence.

The D3-owned query lease is the sole D2 admission representation. Acquire requires current history fingerprint, unique snapshot/lease/internal-correlation, `AcquiredUtc = TimeProvider.GetUtcNow()`, and `ExpiresUtc = AcquiredUtc + 5 minutes`. Release is idempotent only for identical identity/fingerprint and sets `ReleasedUtc` once. Expired is derived and transactionally persisted on next read/acquire/transition; no renewal exists. At most four unexpired Active leases per machine; fifth returns `LeaseConflict / DoNotRetry` with no queue. D2 must acquire before publishing a first page and release on terminal page/cancel/failure. Before D2 exists, the initialized lease collection is empty; no live lease is proven, but product queries remain disabled.

## Canonical activation-history identity

History bytes use accepted CBE-v1 exactly. The preimage is:

```text
ASCII("report-source-activation-history-v1") || 00 ||
F(list of generation-ascending activation-binding entries)
```

Each entry is `F(list)` over these immutable fields in order:

```text
ContractVersion, ActivationId, MachineId, ActivatedUtc, Mode, Reason, StartupAttemptId?,
RestartOccurredUtc?, MachineMappingVersion, ReportingZoneId,
ReportingZoneFingerprint, ZoneFingerprintVersion, SourceComponentName,
SourceComponentVersion, ProducerProfileId, ProducerProfileVersion,
ProfileBindingFingerprint, WriterContractVersion, QueryContractVersion,
QueryProviderVersion, ControlContractVersion, ConfigurationRevisionId,
ReplacesActivationId?, RollbackTargetActivationId?, DecisionOwnerId,
ApprovalReference, Generation, State, ClosedUtc?, PartitionVersion
```

`CanonicalFingerprint` is the SHA-256 of the single binding's same ordered source fields and is verified separately; it is not recursively included in its own source bytes or in the history entry. Both correlations are operation metadata and are excluded as stated in the binding contract. Thus every non-derived immutable binding field is covered exactly once.

Hash is lowercase SHA-256. Contract version and CBE tags are fixed by the D1-compatible codec. D3a commits independent binary fixtures and sidecar hashes for this exact normative generator:

- Base T0 is `2026-11-23T12:00:00.0000000Z`; generation `g` adds `g-1` seconds.
- ActivationId is `rsc-activation-v1.<g as 64 lowercase hexadecimal digits>`; MachineId is `machine.` plus 64 zeroes.
- Generation 1 is `initial` / `forward-only-cutover`, StartupAttemptId `00000000-0000-0000-0000-000000000001`, and RestartOccurredUtc equal to T0. Later rows are `successor` / `compatible-release-changed` with both startup fields null.
- Constants are MachineMappingVersion `machine-map-v1`; ReportingZoneId `Etc/UTC`; ReportingZoneFingerprint `sha256:` plus 64 `1` digits; ZoneFingerprintVersion `1`; SourceComponentName `profile.reference`; SourceComponentVersion `1.0.0`; ProducerProfileId `tq-report-source-v1`; ProducerProfileVersion `1`; ProfileBindingFingerprint `sha256:` plus 64 `2` digits; WriterContractVersion, QueryContractVersion, QueryProviderVersion, and ControlContractVersion all `1`; ConfigurationRevisionId `sha256:` plus 64 `3` digits; DecisionOwnerId `owner:release-board`; ApprovalReference `approval:0001`.
- Generation 1 predecessor is null; later ReplacesActivationId is the preceding generated ID. RollbackTargetActivationId is always null. Generation and PartitionVersion both equal `g`.
- Only the last row is `active` with null ClosedUtc; each earlier row is `superseded` and closes exactly at the next row's T0.

| Rows | Canonical byte length | SHA-256 |
|---:|---:|---|
| 0 | 45 | `b7fb0bfdf1ff5c28f1393cfe89c2e3a9103d8a17bff5bc2b9252a3755b9a2169` |
| 1 | 799 | `cec0135d976b4e7f2a94a69e7b1ca25dd03d2ed6fa680280dd4094cfa549ccae` |
| 1,024 | 835,405 | `3e3c1beebd5845558bf4e1177b8332413347ba4b7f4f4e003653533e0534b945` |

Tests independently construct bytes without production codec, verify all three hashes, reject 1,025 rows, and prove changing any immutable field changes the hash. D2 binds the exact fingerprint into snapshot and cursor cross-binding; it cannot recompute a subset.

## Operation lifecycle and receipt-shape profile contract

The core lifecycle is append-evidenced and closed:

```text
new -> Pending(attempt 1)
Pending -> Accepted
Pending -> ProvenNotAccepted(RetrySameIdentity | AbortActivation)
ProvenNotAccepted(RetrySameIdentity) -> Pending(attempt + 1, same IDs/correlations/fingerprint)
```

Accepted and `AbortActivation` are terminal. No attempt or resolution evidence is deleted or overwritten. Retry appends a new attempt under the same OperationId/InternalCorrelation/LogicalOperationId/DraftFingerprint; maximum attempt 32. `AbortActivation` leaves current activation disabled but is resolved for quiescence, allowing an owner-approved successor or zero-write rollback when all other predicates pass. It never allocates a replacement identity. Unknown/permanent rejection code is AbortActivation/DoNotRetry.

The TQ profile required by TQ-011B freezes this receipt matrix; shared core enforces the profile-returned shape without embedding the names:

| TQ operation | AcceptedRecordId | AcceptedSampleEventId | RepositoryReceiptId | AcceptanceProofFingerprint |
|---|---|---|---|---|
| SampleStart | forbidden | required positive | required | required |
| SampleComplete | required UUID | required positive | required | required |
| SampleRecovery | required UUID | required positive | required | required |
| RestartStarted | required UUID | forbidden | required | required |
| RestartCompleted | required UUID | forbidden | required | required |
| SessionStarted | required UUID | forbidden | required | required |
| SessionAccessDecision | required UUID | forbidden | required | required |
| SessionEnded | required UUID | forbidden | required | required |
| EventAnnotationAdded | required UUID | required positive | required | required |

For Pending every receipt/rejection/resolution field is null. For Accepted all matrix-required fields and `ResolvedUtc` are required; rejection fields are null. For ProvenNotAccepted all accepted IDs/receipt/proof are null and controlled rejection code, disposition, and `ResolvedUtc` are required. Contradictory shapes are `UnsupportedVersion` for stored rows and rejected at public construction. Profile rejection codes and their retry/abort mapping are closed, case-sensitive, bounded controlled codes; exception/provider text is forbidden.

## Conformance and acceptance

D3a publishes a reusable provider conformance assembly. It exhausts public enum ordinals, result tuples/factories, method success shapes, strict wire codes, every scalar/population N/N+1, defensive copies/equality, transition tables, all history vectors, lease 4/5 admission, lifecycle/receipt shapes, retry identity, cancellation boundaries, malformed stored values, profile registration, and disclosure-safe rendering. It also preserves the accepted TQ CBE/UUID/draft vectors as external edge-profile fixtures without compiling TQ semantics into core.

Exact commands from the isolated worktree:

```powershell
dotnet test .\Reports.ReportSourceControl.Contracts.Tests\Reports.ReportSourceControl.Contracts.Tests.csproj -c Release
dotnet test .\Reports.ReportSourceControl.Contracts.Conformance.Tests\Reports.ReportSourceControl.Contracts.Conformance.Tests.csproj -c Release
dotnet format .\Reports.ReportSourceControl.Contracts\Reports.ReportSourceControl.Contracts.csproj --verify-no-changes --no-restore
dotnet format .\Reports.ReportSourceControl.Contracts.Conformance\Reports.ReportSourceControl.Contracts.Conformance.csproj --verify-no-changes --no-restore
dotnet list .\Reports.ReportSourceControl.Contracts\Reports.ReportSourceControl.Contracts.csproj package --vulnerable --include-transitive
git diff --check
git status --short --branch
```

Both production projects are package-free. D3a publication requires independent review, a clean exact commit, live remote publication, and recorded SHA. Rollback before downstream use reverts only D3a-owned additive files. After a dependent stored version exists, incompatible rollback is forbidden; restore the accepted compatible SHA or roll forward.
