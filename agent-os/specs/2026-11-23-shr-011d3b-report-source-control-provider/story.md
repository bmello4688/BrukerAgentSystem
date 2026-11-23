# SHR-011D3b - transactional report-source control provider and schema composition

## State, size, dependency, and ownership

**State: dependency-blocked on accepted and published D3a. Size: 8 points.**

- Exact base: the independently accepted, live-published D3a SHA; no draft SHA or equivalent tree.
- Branch/worktree: `feature/shr-011d3b-control-provider`; `C:\Git\Common.Reports-shr011d3b-control-provider`.
- Owned paths: new `Reports.ReportSourceControl.DataService/**`; provider tests in `Reports.Fdrs.Persistence.Tests/ReportSourceControl/**`; narrow schema composition/read-boundary files `Reports.Persistence.DataService/DataServiceFdrsSchemaV1.cs`, `Reports.Persistence.DataService/DataServiceFdrsControlReadModelV1.cs`, and `Reports.Persistence.DataService/ReportSourceControlSchemaCompositionV1.cs`; additive project/solution references only.
- Any extraction from `DataServiceFdrsRepository.cs` is mechanical: existing collection names, versions, index fields, and bytes remain exact. No FDRS behavior, D1/D2, DataService abstraction/provider, product, hardware, UI, runtime, gitlink, status-board, or backlog change.

Feature Engineering owns implementation. Reviewer Integration independently reviews the exact commit. D3c starts only after D3b and D3a are both accepted.

## One schema authority and one transactional store

D3b introduces `DataServiceReportSourceControlStoreV1 : IReportSourceControlStoreV1`. Its constructor requires exactly:

```text
ITransactionalDocumentStore store
IReadOnlyReportSourceProducerProfileRegistryV1 profiles
TimeProvider timeProvider
```

The provider is singleton; codecs/profile registry are immutable and stateless; the store is the same singleton injected into `DataServiceFdrsRepository` and later D2. There is no ambient store root, service locator, static current machine/user, process cache, `ConcurrentDictionary`, mutex, semaphore, or in-memory correctness flag. Per-machine concurrency is owned only by the document-store partition transaction.

`DataServiceFdrsSchemaV1` is the provider-internal single source of truth for existing FDRS collection/index descriptors. D3b mechanically moves the current private literals into that descriptor without changing any name/version/index. `DataServiceFdrsControlReadModelV1` exposes only typed, read-only active-event/session/receipt/import/boundary projections over the existing persisted documents; the existing repository and D3 use the same serializers/types, so D3 never copies private JSON field strings or DTO shapes. `ReportSourceControlSchemaV1` contributes D3 collections. `ReportSourceControlSchemaCompositionV1.Compose(fdrs, control)` rejects duplicate collection/index names or version disagreement and returns one immutable array to `EnsureSchemaAsync`. Both repositories consume these descriptors; no D3 or D2 class duplicates private FDRS strings or persisted DTO definitions.

### Exact D3 collections, version 1, same MachineId partition

| Collection | Key / population | Required stored fields and indexes |
|---|---|---|
| `fdrs_report_source_activations_v1` | ActivationId; max 1,024 | exact D3a ActivationBinding fields; indexes `generation(generation)`, `state(state,generation)`, `t0(activatedUtc,generation)` |
| `fdrs_report_source_activation_state_v1` | singleton `state`; exactly 0 or 1 | ContractVersion, MachineId, CurrentActivationId, CurrentGeneration, ActivationHistoryFingerprint, LastOccurrenceUtc, PartitionVersion; index `singleton(documentId)` |
| `fdrs_producer_operations_v1` | OperationId; max 100,000 | immutable operation header plus current State/AttemptOrdinal and exact receipt shape; indexes `state-operation(state,operationId)`, `occurrence(occurredUtc,operationId)`, `correlation(internalCorrelation)` |
| `fdrs_producer_operation_attempts_v1` | `<OperationId>/<AttemptOrdinal>`; max 32 per operation | ContractVersion, OperationId, AttemptOrdinal, State, StartedUtc, ResolvedUtc?, rejection/receipt proof fields, PartitionVersion; index `operation-attempt(operationId,attemptOrdinal)` |
| `fdrs_report_source_query_leases_v1` | LeaseId; max 10,000 | exact D3a QueryLease fields; indexes `state-expiry(state,expiresUtc,leaseId)`, `snapshot(snapshotId)`, `history(activationHistoryFingerprint)` |

Every stored document repeats ContractVersion=`1`, schema version=`1`, partition MachineId, and PartitionVersion. Strict deserialization occurs before business classification. Unknown/missing/extra property, enum number/token/case, future version, malformed identifier/time, illegal null, or contradictory receipt returns `Unsupported / UnsupportedVersion / DoNotRetry`, null value, zero writes, and downstream `UnknownMapping / ContactSupport`.

`InitializeAsync` first validates store capabilities, then ensures the exact composed schema. Repeating exact version 1 is idempotent. Missing existing collection/index, version drift, unknown future version, partial initialization, or attempted upgrade is `UnsupportedVersion`; it never creates a best-effort subset. Success `true` means only schema/capability compatibility, never product readiness.

## Atomic cross-collection transaction boundary

Every activation transition executes one transaction in the exact MachineId partition and reads:

- D3 pointer and complete activation history;
- D3 operation headers and attempts in the current interval;
- D3 query leases after expiring elapsed rows using injected time;
- existing `fdrs_machine_state_v1`, `fdrs_records_v1`, `fdrs_sample_events_v1`, `fdrs_imports_v1`, `fdrs_import_receipts_v1`, and `fdrs_append_receipts_v1` through the shared schema/DTO boundary;
- no cleanup/query-snapshot/quarantine payload except its documented integrity/count signal.

The transaction proves history, identity, compatibility, quiescence, and bounds before writing a new activation, closing a predecessor, replacing the pointer, or expiring leases. A failure writes nothing. The transaction never spans another partition/store and never calls product/hardware/network code.

Before D2 exists, the lease collection is initialized and empty. Empty proves only “zero live leases”; it does not enable queries or writers. Only `AcquireQueryLeaseAsync` may insert a lease, and only D2 may call it in runtime composition. Activation never fabricates or clears a lease.

## Executable quiescence predicate

The provider evaluates predicates in this exact order and returns the first failure:

1. **Version/integrity:** every read document is strict version 1, canonical, and cross-linked. Failure is UnsupportedVersion first, otherwise IntegrityFailure.
2. **Identity:** request machine, pointer, activation, FDRS state/rows, operations, and leases are equal ordinal controlled values. Valid unequal machine claim is IdentityConflict; missing/corrupt evidence is IntegrityFailure.
3. **Lease:** after persisting elapsed `Active -> Expired`, zero `Active` lease may have `ExpiresUtc > now`. Any is LeaseConflict. Released/Expired are resolved and retained.
4. **Event:** `fdrs_machine_state_v1.ActiveEventId` is null and `fdrs_sample_events_v1` contains zero nonterminal aggregate. Exactly one consistent open aggregate means not quiescent; multiple/pointer disagreement means integrity failure.
5. **Sessions:** query `fdrs_records_v1` by the exact `session-started`, `session-access-decision`, and `session-ended` payload kinds and group by canonical attempt correlation, then stable SessionId after a granted decision. `Started + granted + Ended` with valid linkage is Completed; `Started + denied` with no SessionId/end is Denied; `Started + granted` without Ended is Open; missing decision, duplicate/conflicting decision/end, denied-plus-end, broken attempt/SessionId linkage, or an Ended without its start is Incomplete. Any group whose `[StartUtc, EndUtc)` or open `[StartUtc, proposed T0)` intersects `[current T0, proposed T0)` participates. Completed and Denied are resolved; Open is not quiescent; Incomplete is integrity failure. No end time or SessionId is fabricated.
6. **Operation:** zero Pending attempt; zero AcceptanceUnconfirmed; zero ambiguous receipt. Accepted and ProvenNotAccepted are resolved only when receipt shape/history is canonical. `ProvenNotAccepted/RetrySameIdentity` with no new Pending attempt is not quiescent. `ProvenNotAccepted/AbortActivation` is resolved, counts as zero accepted write, and permits only approved successor/zero-write rollback; it keeps readiness disabled.
7. **Receipts/imports:** each operation/FDRS write has exactly one matching append/import receipt. Unresolved means storage unavailable; ambiguous/conflicting/missing-after-claimed-acceptance means integrity failure. A receipt is “proven not accepted” only when the store transaction proves no record, aggregate, receipt, or matching correlation/fingerprint exists at the committed partition version; timeout or inability to read is not proof.
8. **Occurrence/source boundary:** proposed T0 is strictly greater than pointer LastOccurrenceUtc, every FDRS `OccurredUtc`, event start/end, resolved operation `OccurredUtc`, import source boundary, and predecessor T0. Equal or earlier is Rejected/IdentityConflict; missing/non-UTC/inconsistent boundary is integrity failure.
9. **Compatibility:** target has exact MachineId, ProducerProfileId/version, ControlContractVersion, WriterContractVersion, QueryContractVersion, partition/schema version, and canonical history. A reason permits only its closed field delta: ZoneRulesChanged=zone ID/fingerprint/version; SourceReleaseChanged=source component/version; ContractReleaseChanged=writer/query/query-provider versions; ConfigurationChanged=configuration revision; CompatibleReleaseChanged=two or more of those families, while machine/profile/control/schema remain equal. MachineReplacement is Initial only. Any unapproved delta is IdentityConflict; unknown version is UnsupportedVersion.
10. **Rollback zero-write:** current interval contains zero Accepted operation, zero FDRS record/import/receipt, and only resolved ProvenNotAccepted operations; target satisfies compatibility. Otherwise TransitionNotQuiescent. History is never deleted or rewritten.

Precedence is UnsupportedVersion -> IntegrityFailure -> IdentityConflict -> LeaseConflict -> StorageUnavailable/AcceptanceUnconfirmed -> TransitionNotQuiescent -> success. Cancellation can preempt as specified below but never masks a possible commit.

## Receipt and proven-not-accepted provider semantics

Create inserts immutable operation header plus Pending attempt 1 in one transaction. Exact create/retry reads existing state. Same OperationId/InternalCorrelation with any different canonical field is IdentityConflict. Resolve with Accepted validates the registered profile receipt shape, appends immutable attempt resolution, and updates only the header projection. Resolve with ProvenNotAccepted requires store proof described above plus a controlled profile rejection code/disposition.

`RetryProvenNotAcceptedAsync` is legal only for `RetrySameIdentity`, attempt <32, no other Pending attempt, exact same operation/correlation/logical ID/draft fingerprint, and profile still accepts the rejection as retryable. It appends attempt+1 and changes the header projection to Pending. It never deletes old evidence or allocates another ID. `AbortActivation` and Accepted cannot reopen. A permanent repository rejection maps to AbortActivation; current activation remains disabled, but the resolved row no longer creates an “unresolved receipt” deadlock and an approved successor/zero-write rollback can recover.

For the nine TQ profile operations, the provider enforces the D3a receipt table exactly. In addition: RepositoryReceiptId is controlled 1..128 ASCII; AcceptedRecordId is canonical lowercase UUID; AcceptedSampleEventId is positive Int64; proof fingerprint is exact SHA-256. Pending has none; Accepted has only required accepted fields; ProvenNotAccepted has only rejection fields. Any contradiction in storage is UnsupportedVersion, not repair.

## Activation-history and D2 lease coordination

Every history read transaction verifies complete generations 1..N, one current Active last row, legal predecessor closure, T0/ClosedUtc half-open intervals, pointer equality, immutable fingerprints, partition versions, and the D3a canonical history hash. Zero rows is legal only with no pointer/FDRS/control evidence. 1,025 is LimitExceeded, never truncation.

Lease acquire transaction verifies current complete history fingerprint, current Active generation, unique LeaseId/SnapshotId/InternalCorrelation, fewer than four live leases, no activation transaction in progress (enforced by same partition serialization), and requested expiry exactly now+5 minutes. Exact retry is idempotent; cross-binding is IdentityConflict. Release requires exact binding and atomically records ReleasedUtc. Expiry records TimeProvider now and is idempotent. Transition and acquire serialize through the same partition; therefore no lease can appear between the transition's lease proof and commit.

## Runtime, time, cancellation, and ambiguous commit

- `TimeProvider` is required; production passes `TimeProvider.System`; tests pass a fake. UTC comes only from `GetUtcNow()`. Lease/timeout elapsed comparisons use `GetTimestamp()/GetElapsedTime()`. `DateTime.Now/UtcNow`, timers, sleep, filesystem time, and product clocks are prohibited.
- Before transaction admission, cancellation returns Canceled/OperationCanceled with zero writes.
- Inside read-only transactions, cancellation aborts before publication and returns Canceled; no partial value is returned.
- Inside write transactions, the token is honored until commit admission. Once commit may have occurred, the provider resolves the exact deterministic ID/fingerprint with `CancellationToken.None`: proven commit returns Success; proven absence returns Canceled only when the store proves no write; inability to prove either returns Unavailable/AcceptanceUnconfirmed. No replacement ID or retry side effect occurs.
- Schema initialization follows the same possible-commit resolution using exact schema descriptors. Lease release/expiry, activation transition, operation create/resolve/retry each have explicit crash-before-write, crash-after-write, lost-acknowledgment, cancellation, and concurrent-race tests.

## Build arrangement and exact validation

Standalone provider validation uses a clean Common.DataService sibling checkout at exact `ca36e9aabb149da9ff6d02e6707bd3df77224b38`:

```text
C:\Git\Common.DataService-shr011d3\DataService.Storage.Abstractions\DataService.Storage.Abstractions.csproj
C:\Git\Common.DataService-shr011d3\DataService.Storage.LiteDb\DataService.Storage.LiteDb.csproj
C:\Git\Common.DataService-shr011d3\DataService.Storage.MongoDb\DataService.Storage.MongoDb.csproj
```

Commands always pass `-p:DataServiceStorageRoot=C:\Git\Common.DataService-shr011d3`; they never rely on an absent `..\..\DataService`. The checkout must be exact and clean; D3 does not edit it.

```powershell
dotnet test .\Reports.Fdrs.Persistence.Tests\Reports.Fdrs.Persistence.Tests.csproj -c Release -p:DataServiceStorageRoot=C:\Git\Common.DataService-shr011d3
dotnet test .\Reports.ReportSourceControl.DataService.Tests\Reports.ReportSourceControl.DataService.Tests.csproj -c Release -p:DataServiceStorageRoot=C:\Git\Common.DataService-shr011d3
dotnet build .\Reports.Persistence.DataService\Reports.Persistence.DataService.csproj -c Release -p:DataServiceStorageRoot=C:\Git\Common.DataService-shr011d3
dotnet format .\Reports.ReportSourceControl.DataService\Reports.ReportSourceControl.DataService.csproj --verify-no-changes --no-restore
dotnet list .\Reports.ReportSourceControl.DataService\Reports.ReportSourceControl.DataService.csproj package --vulnerable --include-transitive
git diff --check
git status --short --branch
```

Tests execute both LiteDB and MongoDB contract fixtures for schema idempotency/version rejection, every atomic predicate/precedence, all 9 receipt shapes, Pending/Accepted/ProvenNotAccepted/retry, 1/32/33 attempts, 4/5 leases, expiry/release races, 1,024/1,025 history, population/scalar strict deserialization, exact history hashes, cancellation/ambiguous commits, and disclosure-safe diagnostics/logging.

Publication requires independent review and exact live SHA. Before any runtime data exists, rollback reverts only D3b-owned additive files and the mechanical schema extraction. After a D3 row exists, no schema/data rollback is allowed: restore the last compatible accepted binary or publish a compatible roll-forward. No collection deletion, repair, state reset, T0 edit, or private maintenance command.
