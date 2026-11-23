# SHR-011D3c - report-source control integration, validation, and publication

## State, size, dependency, and ownership

**State: dependency-blocked on accepted D3a and D3b. Size: 3 points.**

- Exact base: reviewed integration tip containing the exact published D3a SHA and exact accepted D3b SHA. No reimplementation, squash with changed blobs, or equivalent tree.
- Branch/worktree: `feature/shr-011d3c-control-integration`; `C:\Git\Common.Reports-shr011d3c-control-integration`.
- Owner: Feature Engineering. Reviewer Integration is an independent acceptance/publication gate and never authors or repairs D3c.
- Owned changes: additive solution/project composition, DI extension in Common.Reports composition boundary, combined conformance fixtures, and `docs/report-source-control/v1/**`. No semantic contract/provider change, product, D2, DataService, hardware, UI, runtime configuration, gitlink, status-board, or backlog change.

If integration reveals a D3a contract or D3b provider defect, D3c stops and returns it to that child. D3c may not redesign the contract under integration scope.

## Exact runtime composition

The Common.Reports registration extension creates:

- one singleton `ITransactionalDocumentStore` supplied by the host;
- one singleton immutable `IReadOnlyReportSourceProducerProfileRegistryV1` with no default profile;
- one singleton `DataServiceReportSourceControlStoreV1` exposed only as `IReportSourceControlStoreV1`;
- stateless singleton CBE/wire/history codecs;
- one singleton injected `TimeProvider`;
- no hosted service, listener, endpoint, filesystem writer, ambient identity, static cache/lock, or product profile registration.

The same store instance must be used by `DataServiceFdrsRepository`, D3, and later D2. DI validation fails on duplicate store/profile registrations, scoped/transient control provider, missing TimeProvider, duplicate profile ID/version, or a product profile registered from Common.Reports. TQ-011B registers its reviewed TQ profile at the product edge.

Initialization composes existing FDRS and D3 schemas once. Method success does not set product readiness. D3c publishes a readiness-neutral health projection limited to `Compatible`, `Unavailable`, or `Unsupported`; it carries no machine, activation, operation, lease, provider, exception, or path data. Product startup still owns Disabled/WritersEnabledQueriesDisabled/Ready ordering.

## Combined conformance and compatibility matrix

The final combined suite must prove:

1. D1 contract projects and every existing report/FDRS public enum and golden fixture are byte/ordinal unchanged.
2. D3a canonical core fixtures, three activation-history vectors, enum ordinals, strict wire codes, result tuples, scalar/population N/N+1, receipt shapes, lease cases, and disclosure tests pass.
3. D3b runs identical provider conformance against LiteDB and MongoDB using the exact Common.DataService checkout/property.
4. Existing FDRS initialization and persistence remain compatible after schema composition; existing collection names/versions/index fields are exact.
5. One store/partition race tests atomically serialize acquire lease versus successor/rollback, operation resolution versus transition, and FDRS acceptance versus zero-write rollback.
6. Empty lease/history/pending reads never imply Ready. Unknown version/token/case/malformed storage yields UnsupportedVersion/DoNotRetry, null value, zero writes, and disclosure-safe support correlation.
7. The shared production assemblies contain no TQ/DHS product names, TQ operation/domain/prefix literals, DataService provider literals outside schema descriptors, ambient time, process locks, absolute paths, agent-system/orchestration terms, credentials, or default diagnostic record rendering.
8. The separately stored TQ edge-profile fixtures still reproduce the accepted operation ID, correlation, UUIDv5, draft, and zone vectors without Common.Reports implementing that profile.

## Exact validation and evidence

Prepare clean dependency checkout:

```powershell
git -C C:\Git\Common.DataService-shr011d3 status --short --branch
git -C C:\Git\Common.DataService-shr011d3 rev-parse HEAD
```

It must be clean at `ca36e9aabb149da9ff6d02e6707bd3df77224b38`. Then, from D3c worktree:

```powershell
dotnet test .\Reports.ReportSourceControl.Contracts.Tests\Reports.ReportSourceControl.Contracts.Tests.csproj -c Release
dotnet test .\Reports.ReportSourceControl.Contracts.Conformance.Tests\Reports.ReportSourceControl.Contracts.Conformance.Tests.csproj -c Release
dotnet test .\Reports.ReportSourceControl.DataService.Tests\Reports.ReportSourceControl.DataService.Tests.csproj -c Release -p:DataServiceStorageRoot=C:\Git\Common.DataService-shr011d3
dotnet test .\Reports.Fdrs.Persistence.Tests\Reports.Fdrs.Persistence.Tests.csproj -c Release -p:DataServiceStorageRoot=C:\Git\Common.DataService-shr011d3
dotnet build .\Reports.Persistence.DataService\Reports.Persistence.DataService.csproj -c Release -p:DataServiceStorageRoot=C:\Git\Common.DataService-shr011d3
dotnet test .\Common.Reports.sln -c Release -p:DataServiceStorageRoot=C:\Git\Common.DataService-shr011d3
dotnet format .\Common.Reports.sln --verify-no-changes --no-restore
dotnet list .\Reports.ReportSourceControl.Contracts\Reports.ReportSourceControl.Contracts.csproj package --vulnerable --include-transitive
dotnet list .\Reports.ReportSourceControl.DataService\Reports.ReportSourceControl.DataService.csproj package --vulnerable --include-transitive
git diff --check
git status --short --branch
```

The handoff records exact command outputs, test counts/skips, dependency SHA, D3a/D3b parent SHAs, cumulative changed paths, canonical fixture hashes, schema descriptor diff, vulnerability result, and environment gaps. Any skipped contract/provider test is NO-GO. Existing host-only PDF gates may remain documented only when their unchanged baseline behavior is independently reproduced; they do not waive D3 tests.

Reviewer Integration independently verifies exact ancestry/blobs, additive solution resolution, clean clone, both provider fixtures, protected-source diff, enum ordinals, dependency direction, disclosure, no product profile leakage, and clean status. It returns defects to Feature Engineering. After GO, Feature Engineering fast-forwards Common.Reports `master`, pushes `master`, fetches, and verifies local/cached/live SHA equality. No feature branch is pushed.

## Publication, rollback, and downstream gates

The accepted live SHA is recorded as the only D3 publication authority. SHR-011D2 starts from that exact SHA, consumes D3 history fingerprint and lease methods, and may not create private lease/schema literals. TQ-011B starts only after D2 publishes a descendant and implements its reviewed TQ profile at the product edge. A downstream SHA mismatch returns to review.

Before any D3 runtime row exists, rollback reverts only D3a/D3b/D3c additive commits. Once any activation, operation, attempt, or lease row exists, incompatible schema/binary rollback and collection deletion are prohibited. Disable readiness, restore the last compatible accepted SHA, or publish an additive compatible roll-forward. No direct data repair, operation reset, T0/history rewrite, lease bypass, or profile substitution.

## Acceptance criteria

- Exact order D1 -> D3a -> D3b -> D3c -> D2 -> TQ-011B is evidenced by immutable SHAs.
- Feature Engineering, not Reviewer Integration, owns integration.
- All exact commands pass with zero D3 skips and clean repositories.
- One singleton product-neutral runtime composition is proven; shared binaries contain no TQ-specific semantics.
- Full schema/transaction/cancellation/quiescence/receipt/history/lease/disclosure conformance passes on both providers.
- The exact commit is independently accepted, published live, and recorded before D2 starts.
