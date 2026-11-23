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
| `fdrs_report_source_activations_v1` | ActivationId; max 1,024 | SchemaVersion, then every D3a ActivationBinding field in its frozen order; indexes `generation(generation)`, `state(state,generation)`, `t0(activatedUtc,generation)` |
| `fdrs_report_source_activation_state_v1` | singleton `state`; exactly 0 or 1 | SchemaVersion, ContractVersion, MachineId, CurrentActivationId, CurrentGeneration, ActivationHistoryFingerprint, LastOccurrenceUtc, CurrentOperationEpoch, CurrentLeaseEpoch, PartitionVersion; index `singleton(documentId)` |
| `fdrs_report_source_partition_transactions_v1` | PartitionVersion; append-only | SchemaVersion, ContractVersion, MachineId, PartitionVersion, MutationKind, MutationFingerprint, CommittedUtc; index `version(partitionVersion)` |
| `fdrs_report_source_storage_epochs_v1` | `<kind>/<epoch>`; append-only | SchemaVersion, ContractVersion, MachineId, EpochKind, Epoch, State, RowCount, UnresolvedCount, FirstPartitionVersion, LastPartitionVersion, PreviousEpochHash?, EpochHash?, ClosedUtc?, PartitionVersion; indexes `kind-epoch(epochKind,epoch)`, `state(state,epochKind)` |
| `fdrs_producer_operations_v1` | `<epoch>/<OperationId>`; max 100,000 per epoch | SchemaVersion, ContractVersion, MachineId, StorageEpoch, ActivationId, ProducerProfileId, ProducerProfileVersion, OperationId, OperationKindCode, LogicalOperationId, InternalCorrelation, SupportCorrelation, DraftFingerprint, OccurredUtc, State, AttemptOrdinal, AcceptedRecordId?, AcceptedSampleEventId?, RepositoryReceiptId?, AcceptanceProofFingerprint?, PermanentRejectionCode?, NotAcceptedDisposition?, ResolvedUtc?, PartitionVersion; indexes `epoch-state-operation(storageEpoch,state,operationId)`, `occurrence(occurredUtc,operationId)`, `correlation(internalCorrelation)` |
| `fdrs_producer_operation_attempts_v1` | `<OperationId>/<AttemptOrdinal>`; max 32 per operation | SchemaVersion, ContractVersion, MachineId, StorageEpoch, OperationId, AttemptOrdinal, State, StartedUtc, ResolvedUtc?, AcceptedRecordId?, AcceptedSampleEventId?, RepositoryReceiptId?, AcceptanceProofFingerprint?, PermanentRejectionCode?, NotAcceptedDisposition?, PartitionVersion; index `operation-attempt(operationId,attemptOrdinal)` |
| `fdrs_report_source_query_leases_v1` | `<epoch>/<LeaseId>`; max 10,000 per epoch | SchemaVersion, ContractVersion, MachineId, StorageEpoch, LeaseId, SnapshotId, OwnerId, ActivationHistoryFingerprint, AcquiredUtc, ExpiresUtc, ReleasedUtc?, State, PartitionVersion, InternalCorrelation, SupportCorrelation; indexes `epoch-state-expiry(storageEpoch,state,expiresUtc,leaseId)`, `snapshot(snapshotId)`, `history(activationHistoryFingerprint)` |

For each row, the fields above are the canonical stored order; named index descriptions are not serialized fields. Epoch Open/Closed and all inherited activation/operation/lease nullability rules are exactly the D3a matrices. The transaction-ledger mutation set is ordered by collection ordinal then key ordinal before hashing. Unknown members are rejected.

Every stored document includes the explicit `SchemaVersion=1` and `ContractVersion=1` fields in the exact positions above, plus partition MachineId and PartitionVersion. Open epoch rows require `UnresolvedCount` equal to the exact current unresolved row count; Closed requires `UnresolvedCount=0`. Strict deserialization occurs before business classification. Unknown/missing/extra property, enum number/token/case, future version, malformed identifier/time, illegal null, or contradictory receipt returns `Unsupported / UnsupportedVersion / DoNotRetry`, null value, zero writes, and downstream `UnknownMapping / ContactSupport`.

### Canonical document fingerprints

Every post-write document fingerprint is provider-neutral and is computed from the logical stored DTO, never BSON/LiteDB bytes, serializer output, reflection order, index metadata, or provider-assigned IDs. The exact v1 preimage is:

```text
ASCII("report-source-control-document-fingerprint-v1") || 00 ||
T(collection-code) || U32BE(field-count) ||
for each field in the exact stored order above: T(field-name) || V(field-value)
```

`T` is `U32BE(N) || NFC-UTF8 text`. `V(null)=00`; `V(text, identifier, enum, fingerprint)=01 || T(value)`; `V(signed integer)=02 || I64BE(value)`; `V(UTC timestamp)=03 || I64BE(DateTime UTC ticks)`; `V(boolean)=04 || 00|01`. Enums use their exact lower-camel token. No culture, optional-field omission, alternate normalization, provider representation, or numeric enum is legal. The result is lowercase `sha256:<64 hex>`.

Collection codes are exactly `activation`, `pointer`, `ledger`, `epoch`, `operation`, `attempt`, and `lease`. An activation fingerprint uses every activation stored field except its self-referential `CanonicalFingerprint`. Every other fingerprint uses every field listed above, including nulls, `SchemaVersion`, `UnresolvedCount`, receipt/rejection state, and terminal timestamps. Thus a header or attempt state/receipt mutation changes its document fingerprint. A ledger row's own document fingerprint includes `MutationFingerprint`, but the ledger row is excluded from the mutation set it attests; `MutationFingerprint` is the hash of all other inserted/replaced post-write documents sorted by collection-code ordinal and key ordinal. An epoch row fingerprint may include its already computed `EpochHash`; the epoch hash itself covers only the retained operation/lease rows named by that epoch and never the epoch row.

D3b commits binary preimages and sidecar hashes for seven independent vectors. Their common values are: `SchemaVersion=ContractVersion=PartitionVersion=1`; MachineId=`machine.` plus 64 zeroes; ActivationId=`rsc-activation-v1.` plus 64 zeroes; OperationId=`rsc-operation-v1.` plus 64 zeroes; InternalCorrelation=`rsc-internal-v1.` plus 64 zeroes; support correlation=`support-001`; base UTC=`2026-11-23T12:00:00.0000000Z`; fingerprints numbered 1..7 are `sha256:` plus 64 repetitions of that digit. The activation vector is a legal generation-1 Active row: `initial` / `forward-only-cutover`; profile `reference-profile-v1` version 1 and fingerprint 1; startup UUID `00000000-0000-0000-0000-000000000001`; restart equal to base UTC; mapping `machine-map-v1`; zone `Etc/UTC`, fingerprint 2, version 1; source `profile.reference` version `1.0.0`; all writer/query/provider/control versions 1; configuration fingerprint 3; null predecessor/rollback/close; owner `owner:release-board`; approval `approval:0001`; generation 1. Pointer uses history fingerprint 4 and both epochs 1. Ledger uses `activation-initial`, fingerprint 5, and base UTC. Epoch is Closed operation epoch 1 with row count 1, unresolved count 0, versions 1, null predecessor, fingerprint 6, and base close UTC. Operation/attempt are Pending attempt 1 using profile `reference-profile-v1`, kind `reference-operation`, logical ID `logical:0001`, draft fingerprint 7, and all receipt/rejection/resolution fields null. Lease is Active storage epoch 1 with `lease:0001`, `snapshot:0001`, owner `owner:query-provider`, history fingerprint 4, base acquisition, expiry exactly five minutes later, and null release.

| Collection code | Canonical bytes | SHA-256 |
|---|---:|---|
| `activation` | 1,426 | `a04663e7aa3fb91df9a9bc418ca6f7af54d49b9461aba78362e55c38d4b1af07` |
| `pointer` | 576 | `bc5cff2500aa928c32f027e60e94b2eae2287750f33e6b63f32260dbe37f08c6` |
| `ledger` | 396 | `51947c9804b1d8b3cbdffb382b0e2cc1ebd2bb78b544fddadb805600468ad62e` |
| `epoch` | 546 | `70caf3786224d17a26d29da1b86104b4409a35e70a375cfda4b76da82a79f8ba` |
| `operation` | 1,116 | `083447e90c85f31d2a4ed65704874d82346f75ae189e3922989080c3ce2d5552` |
| `attempt` | 603 | `40cf143d4a888924f34f10dc9677e682fdfe7eabab497ee2ca703ccc99024a45` |
| `lease` | 688 | `15de8f89375a2252e394c4b3fc2416ee93c0ecd9f34bd704b7b57102b073998d` |

Tests independently construct these bytes without the production encoder, then cover every mutable terminal field, every nullability/state permutation, collection/key ordering, mutation-set ledger exclusion, and LiteDB/MongoDB equality. A document fingerprint mismatch is `IntegrityFailure`; unknown fingerprint domain/version is `UnsupportedVersion`. Neither may be repaired or normalized in place.

`InitializeAsync` first validates store capabilities, then ensures the exact composed schema. Repeating exact version 1 is idempotent. Missing existing collection/index, version drift, unknown future version, partial initialization, or attempted upgrade is `UnsupportedVersion`; it never creates a best-effort subset. Success `true` means only schema/capability compatibility, never product readiness.

### Monotonic PartitionVersion allocator and ledger

The pointer owns `CurrentPartitionVersion`. With no machine documents it is logically `0`. Every mutating partition transaction computes `next = checked(current + 1)` exactly once, stamps `next` on every inserted/replaced D3 document, and appends one `fdrs_report_source_partition_transactions_v1` row containing the mutation kind and canonical hash of the sorted `(collection,key,post-write-fingerprint)` set. It then writes the pointer with the same `next`. The first mutation is version 1. Multi-document activation, attempt resolution, lease expiry/release, and epoch rollover each consume one version, not one per document.

Read-only calls, failed validation, cancellation before admission, proven-absent writes, and rolled-back transactions do not allocate. Exact idempotent retry finds and returns the committed ledger row/version without increment. After ambiguous commit, resolution reads the deterministic identity and ledger with no caller token; proven commit returns that version, proven absence preserves current, and unresolved returns AcceptanceUnconfirmed without allocation. At `Int64.MaxValue`, any mutation returns LimitExceeded/DoNotRetry with zero writes.

Every read reconstructs integrity from retained ledger/documents: versions are positive and no greater than pointer; all documents stamped at a version match that version's canonical mutation set; object replacements increase; activation generations/attempt ordinals/epochs never regress; pointer equals the maximum ledger version; ledger versions are contiguous 1..current. Gap, mixed stamps, unledgered document, incompatible duplicate, or pointer mismatch records IntegrityFailure. Provider tests cover empty/1/2/MaxValue, multi-document same stamp, concurrent allocation, idempotent retry, read/failure no increment, ambiguous resolution, overflow, and every reconstruction fault.

## Atomic cross-collection transaction boundary

Every activation transition executes one transaction in the exact MachineId partition and reads:

- D3 pointer and complete activation history;
- D3 operation headers and attempts in the current interval;
- D3 query leases after expiring elapsed rows using injected time;
- existing `fdrs_machine_state_v1`, `fdrs_records_v1`, `fdrs_sample_events_v1`, `fdrs_imports_v1`, `fdrs_import_receipts_v1`, and `fdrs_append_receipts_v1` through the shared schema/DTO boundary;
- no cleanup/query-snapshot/quarantine payload except its documented integrity/count signal.

The transaction proves history, identity, compatibility, quiescence, and bounds before writing a new activation, closing a predecessor, replacing the pointer, or expiring leases. A failure writes nothing. The transaction never spans another partition/store and never calls product/hardware/network code.

Before D2 exists, the lease collection is initialized and empty. Empty proves only “zero live leases”; it does not enable queries or writers. Only `AcquireQueryLeaseAsync` may insert a lease, and only D2 may call it in runtime composition. Activation never fabricates or clears a lease.

## Executable whole-set quiescence predicate

The transaction reads the complete bounded evidence set first, validates every decodable document, and records every applicable `QuiescenceTriggerV1` in a duplicate-free set. It never returns from the first failed predicate and never lets query/enumeration order choose the result. If a document cannot be strictly decoded, `UnsupportedVersion` is recorded and remaining independently decodable evidence is still evaluated without using fields from the bad document. After whole-set evaluation, exactly one outcome is selected by the single precedence table below.

1. **Version/syntax:** every read document is strict version 1 and canonical. Unknown/malformed version, token, case, rejection code, or member shape records UnsupportedVersion; a decodable but broken cross-link records IntegrityFailure. Selection occurs only after the complete fact set is built.
2. **Machine:** after syntax/version validation, compare every request, partition, pointer, activation, FDRS row, operation, and lease MachineId to the expected binding. Any syntactically valid unequal value records `ValidMachineDifference`; it maps only to `MachineMismatch / ContactSupport` and is evaluated before identity/integrity. Missing/malformed machine is UnsupportedVersion; only equal-machine duplicate/conflicting claims can record IdentityConflict.
3. **Lease:** after persisting elapsed `Active -> Expired`, zero `Active` lease may have `ExpiresUtc > now`. Any is LeaseConflict. Released/Expired are resolved and retained.
4. **Event:** `fdrs_machine_state_v1.ActiveEventId` is null and `fdrs_sample_events_v1` contains zero nonterminal aggregate. Exactly one consistent open aggregate means not quiescent; multiple/pointer disagreement means integrity failure.
5. **Sessions:** query `fdrs_records_v1` by the exact `session-started`, `session-access-decision`, and `session-ended` payload kinds and group by canonical attempt correlation, then stable SessionId after a granted decision. `Started + granted + Ended` with valid linkage is Completed; `Started + denied` with no SessionId/end is Denied; `Started + granted` without Ended is Open; missing decision, duplicate/conflicting decision/end, denied-plus-end, broken attempt/SessionId linkage, or an Ended without its start is Incomplete. Any group whose `[StartUtc, EndUtc)` or open `[StartUtc, proposed T0)` intersects `[current T0, proposed T0)` participates. Completed and Denied are resolved; Open is not quiescent; Incomplete is integrity failure. No end time or SessionId is fabricated.
6. **Operation:** zero Pending attempt; zero AcceptanceUnconfirmed; zero ambiguous receipt. Accepted and ProvenNotAccepted are resolved only when receipt shape/history is canonical. `ProvenNotAccepted/RetrySameIdentity` with no new Pending attempt is not quiescent. `ProvenNotAccepted/AbortActivation` is resolved, counts as zero accepted write, and permits only approved successor/zero-write rollback; it keeps readiness disabled.
7. **Receipts/imports:** each operation/FDRS write has exactly one matching append/import receipt. Unresolved means storage unavailable; ambiguous/conflicting/missing-after-claimed-acceptance means integrity failure. A receipt is “proven not accepted” only when the store transaction proves no record, aggregate, receipt, or matching correlation/fingerprint exists at the committed partition version; timeout or inability to read is not proof.
8. **Occurrence/source boundary:** proposed T0 is strictly greater than pointer LastOccurrenceUtc, every FDRS `OccurredUtc`, event start/end, resolved operation `OccurredUtc`, import source boundary, and predecessor T0. Equal or earlier is Rejected/IdentityConflict; missing/non-UTC/inconsistent boundary is integrity failure.
9. **Compatibility:** target has exact MachineId, ProducerProfileId/version, ControlContractVersion, WriterContractVersion, QueryContractVersion, partition/schema version, and canonical history. A reason permits only its closed field delta: ZoneRulesChanged=zone ID/fingerprint/version; SourceReleaseChanged=source component/version; ContractReleaseChanged=writer/query/query-provider versions; ConfigurationChanged=configuration revision; CompatibleReleaseChanged=two or more of those families, while machine/profile/control/schema remain equal. MachineReplacement is Initial only. Any unapproved delta is IdentityConflict; unknown version is UnsupportedVersion.
10. **Rollback zero-write:** current interval contains zero Accepted operation, zero FDRS record/import/receipt, and only resolved ProvenNotAccepted operations; target satisfies compatibility. Otherwise TransitionNotQuiescent. History is never deleted or rewritten.

The only precedence is:

```text
UnsupportedVersion
  -> ValidMachineDifference / MachineMismatch
  -> IntegrityFailure (including incomplete session/source evidence)
  -> IdentityConflict (equal-machine duplicate/conflicting claims only)
  -> LeaseConflict
  -> AcceptanceUnconfirmed or StorageUnavailable
  -> ActiveEvent or OpenSession or PendingOperation or BoundaryConflict
  -> IncompatibleTarget or RollbackHasWrites
  -> success
```

The selected trigger maps through the D3a closed result table; non-selected triggers are retained only as aggregate test evidence and are never logged with protected values. Cancellation is handled by the separate transaction rules below and is not a competing quiescence trigger; it never masks a possible commit. Exhaustive pairwise and representative multi-trigger tests prove the same selected result regardless of collection order, provider order, or simultaneous facts; in particular valid unequal machine wins over corrupt source and equal-machine collision, while UnsupportedVersion wins when syntax/version cannot establish a valid machine claim.

## Receipt and proven-not-accepted provider semantics

Create inserts immutable operation header plus Pending attempt 1 in one transaction. Exact create/retry reads existing state. Same OperationId/InternalCorrelation with any different canonical field is IdentityConflict. Resolve with Accepted validates the registered profile receipt shape, appends immutable attempt resolution, and updates only the header projection. Resolve with ProvenNotAccepted requires store proof described above plus a controlled profile rejection code/disposition.

`RetryProvenNotAcceptedAsync` is legal only for `RetrySameIdentity`, attempt <32, no other Pending attempt, exact same operation/correlation/logical ID/draft fingerprint, and profile still accepts the rejection as retryable. It appends attempt+1 and changes the header projection to Pending. It never deletes old evidence or allocates another ID. If attempt 32 is conclusively not accepted with a retryable disposition, the same resolution transaction writes `ProvenNotAccepted / AbortActivation / retry-exhausted-v1`; all 32 attempts remain immutable and the header becomes terminal. It cannot remain RetrySameIdentity, Pending, or acceptance-unconfirmed. `AbortActivation` and Accepted cannot reopen. A recognized permanent repository rejection uses the same sole controlled code and AbortActivation. Current activation remains disabled, but the resolved row no longer creates an unresolved-receipt deadlock and an approved successor/zero-write rollback can recover.

`retry-exhausted-v1` is the only recognized stored rejection token. Any absent, future, provider-supplied, alternate-case, or malformed rejection code is `Unsupported / UnsupportedVersion / DoNotRetry`, null value, zero writes; it is never silently converted to AbortActivation. Tests cover attempts 31->32, attempt-32 exhaustion terminalization, exact retry of the terminal resolution, forbidden attempt 33, unknown codes on requests and stored rows, and recovery through successor/zero-write rollback without deleting evidence.

For the nine TQ profile operations, the provider enforces the D3a receipt table exactly. In addition: RepositoryReceiptId is controlled 1..128 ASCII; AcceptedRecordId is canonical lowercase UUID; AcceptedSampleEventId is positive Int64; proof fingerprint is exact SHA-256. Pending has none; Accepted has only required accepted fields; ProvenNotAccepted has only rejection fields. Any contradiction in storage is UnsupportedVersion, not repair.

## Activation-history and D2 lease coordination

Every history read transaction verifies complete generations 1..N, one current Active last row, legal predecessor closure, T0/ClosedUtc half-open intervals, pointer equality, immutable fingerprints, partition versions, and the D3a canonical history hash. Zero rows is legal only with no pointer/FDRS/control evidence. 1,025 is LimitExceeded, never truncation.

Lease acquire transaction verifies current complete history fingerprint, current Active generation, unique LeaseId/SnapshotId/InternalCorrelation, fewer than four live leases, no activation transaction in progress (enforced by same partition serialization), and requested expiry exactly now+5 minutes. Exact retry is idempotent; cross-binding is IdentityConflict. Release requires exact binding and atomically records ReleasedUtc. Expiry records TimeProvider now and is idempotent. Transition and acquire serialize through the same partition; therefore no lease can appear between the transition's lease proof and commit.

## Non-destructive lifetime capacity and epoch hash chain

The 100,000-operation and 10,000-lease limits are per active storage epoch, not lifetime limits. Normal resolved volume must not permanently disable reporting.

- Epoch 1 is created with the first row of its kind. At exactly 100,000 operations, the next new operation atomically closes the epoch and opens operation epoch+1 only if every operation is Accepted or terminal ProvenNotAccepted and no ambiguous/Pending attempt exists. At exactly 10,000 leases, the next acquire first terminalizes elapsed leases and may close/open the lease epoch only when zero Active lease remains.
- Closing computes CBE-v1 `SHA256(ASCII("report-source-control-epoch-v1") || 00 || F(EpochKind) || F(Epoch) || F(RowCount) || F(FirstPartitionVersion) || F(LastPartitionVersion) || F(PreviousEpochHash?) || F(list))`; list entries are ID text, terminal-state enum, canonical-fingerprint text, and PartitionVersion integer, ordered by ID ordinal. Rows remain in their original collections and are never deleted, moved, rewritten, or truncated. The new immutable epoch row stores the prior hash; the pointer selects the new active epoch.
- Historical reads/reconstruction verify the complete epoch hash chain and may query older rows by epoch. Runtime pending/active reads inspect current epoch plus any older epoch whose immutable summary says unresolved count nonzero; a closed epoch must record zero unresolved count. A hash mismatch is IntegrityFailure.
- If capacity is reached while unresolved work/live leases exist, the new write returns TransitionNotQuiescent/DoNotRetry with zero writes; resolving/releasing the existing rows permits rollover. If epoch is `Int32.MaxValue`, rollover is LimitExceeded/DoNotRetry. Neither case deletes evidence or invents IDs.
- Boundaries are exact: operation 99,999 and 100,000 remain epoch N; 100,001 opens epoch N+1. Lease 9,999 and 10,000 remain epoch N; 10,001 opens N+1 only after zero live leases. D3b commits independently generated empty, one-row, 100,000-operation, and 10,000-lease CBE/hash vectors. Tests cover those vectors, rollover atomicity/crash/lost acknowledgment, unresolved blocker then recovery, retained-row hashes, chain tamper/gap/replay, epoch overflow, and years of repeated rollover without readiness loss.

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

Tests execute both LiteDB and MongoDB contract fixtures for schema idempotency/version rejection; whole-set quiescence and precedence permutations; MachineMismatch before identity/integrity; all 9 receipt shapes; Pending/Accepted/ProvenNotAccepted/retry/exhaustion; 1/32/33 attempts; exhaustive activation/binding/lease nullability; 4/5 live leases; expiry/release races; 1,024/1,025 history; exact DTO field order and unknown members; scalar/UTF-8/population N/N+1; PartitionVersion allocation/ledger/reconstruction/overflow; 100,000/100,001 operation and 10,000/10,001 lease epoch rollover/hash chains; exact history hashes; cancellation/ambiguous commits; and disclosure-safe diagnostics/logging.

Publication requires independent review and exact live SHA. Before any runtime data exists, rollback reverts only D3b-owned additive files and the mechanical schema extraction. After a D3 row exists, no schema/data rollback is allowed: restore the last compatible accepted binary or publish a compatible roll-forward. No collection deletion, repair, state reset, T0 edit, or private maintenance command.
