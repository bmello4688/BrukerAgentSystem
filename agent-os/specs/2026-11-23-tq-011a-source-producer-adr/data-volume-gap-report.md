# TQ-011A sanitized volume, retention, and gap evidence

## Evidence scope and privacy

No customer, laboratory, FDRS, or legacy sample data was opened, copied, counted, or changed for this planning story. The available evidence is immutable source structure and published contract bounds. This is deliberate: the history decision is forward-only, so no legacy population estimate can justify reading or importing confidential data.

The lack of a sanctioned production distribution is not hidden as an estimate. Capacity is enforced by hard D1/D2 limits and operational telemetry must expose only aggregate closed counts, never identities or values.

## Structural observations

| Observation | Evidence/consequence |
|---|---|
| Legacy `ISamplesRepositoryClient.LoadMetadata` loads all sample metadata and offers CRUD/export/last-number operations, not a commit-watermark page API. | It cannot satisfy stable bounded source queries; no dual read. See [evidence-register.md](evidence-register.md). |
| Current sample number wraps and can be sourced from legacy metadata/settings. | It cannot prove positive monotonic FDRS identity or gaps. |
| Published DataService FDRS default capacity is 50,000 aggregates per repository instance, while D1 permits at most 10,000 returned rows and 20,000 work units per snapshot. | A legal storage population can exceed one report snapshot. The provider must return `LimitExceeded`; it must not truncate. |
| D1 page size is 1-500, active snapshots are 4, lease is absolute 5 minutes, and provider work per call is 30 seconds. | Product code must page through one lease, never fan out unbounded parallel snapshots. |
| Generation-1 `T0` equals the restart occurrence captured at actual host `StartAsync` entry; the activation transaction requires an empty target partition and the first restart-start occurs exactly at T0. | This is the only accepted initial population/boundary for `ForwardOnlyAtCutover`; any pre-T0 operation/record or nonzero preactivation Event/import/import-receipt state is `MigrationIncomplete` before activation or `SourceGap` after activation. |
| Published FDRS has append receipts but no activation binding or product-operation journal. | SHR-011D3 adds bounded pending-operation reads (1-500) and immutable activation generations; TQ-011B cannot use files/memory as durable retry state. |

## Bound fit

| Dimension | Frozen bound | TQ rule |
|---|---:|---|
| inclusive date span | 3,660 days | Validate before provider access. |
| identifier length | 128 Unicode scalars | Machine hash is 67 ASCII characters; actor/session/config inputs must independently satisfy published contracts. |
| annotation/source string | 4,096 D1 scalars; FDRS annotation itself is 512 scalars | Producer enforces the stricter FDRS annotation limit; no truncation. |
| page size | 1-500 top-level rows | Pass exact validated value to D1. |
| cursor | 512 UTF-8 bytes | Opaque; analyzer never parses/logs it. |
| snapshot rows | 10,000 | One Event/restart/session is one row. Exceeding it is zero-value `LimitExceeded`. |
| snapshot work | 20,000 | Count every inspected candidate and nested annotation/alarm/pair/join per D1. No local re-count or partial result. |
| provider call | 30 seconds monotonic | Timeout is zero-value `SourceUnavailable`; cursor does not advance. |
| lease | 5 minutes absolute | Expiry is exactly `SourceUnavailable/RestartQuery`; no sliding renewal. |
| concurrent snapshots | 4 provider-wide, nonqueued | Fifth admission is `SourceUnavailable`/retry. |
| activation generations | 1,024 complete rows | SHR-011D3 history read never truncates; 1,025 is provider/source `LimitExceeded`/`ContactSupport`. |

Minimum work is at least the top-level candidate count. Alarm reasons, annotations, restart pairing, and session/Event joins add work. Therefore a request with fewer than 10,000 rows can still legally exceed 20,000 work; this is expected fail-closed behavior, not a reason to omit nested facts.

## Gap and duplicate policy

Tolerance is exactly zero for report-visible native FDRS facts:

- zero duplicate/reused `SampleEventId` within a machine; duplicate identity claim is `IdentityCollision`, while a missing native sequence member is `SourceGap`;
- zero missing IDs inside the committed native sequence after `T0`, except a retention condition explicitly represented by the published provider contract; inability to prove continuity is `SourceGap`;
- zero Events with multiple/conflicting terminal records;
- zero terminal Events without stable user/session/config identity;
- zero Event/session joins by anything other than exact stable `SessionId`;
- zero incomplete/duplicate restart pairs represented as values;
- zero unknown/unapproved result/alarm/lifecycle codes represented as values;
- zero unresolved ambiguous write receipts when readiness is enabled;
- zero pending SHR-011D3 operation rows when readiness is enabled;
- zero operation or record occurrence before generation-1 T0, and restart start occurrence exactly equal to generation-1 T0;
- zero cross-machine records or machine/zone/source/config mismatch against the activation interval containing each occurrence.

Retention must not silently turn a requested range into a successful partial page. If D2 cannot prove the requested complete snapshot because required source records were retained/evicted, map its integrity/unavailability result to `SourceGap`/`HistoryUnavailable` according to the published reason; never synthesize zero counts.

## Required sanitized operational counters

TQ-011B may emit only aggregate counters with no labels derived from identities, payloads, paths, provider/schema, or cursors:

- readiness state transition count by closed local outcome;
- accepted start/terminal/recovery/append counts;
- unresolved-receipt count;
- reconciliation duplicate/gap/orphan/unknown/mismatch counts;
- query row/work/page count buckets and limit outcome count;
- active lease count and lease-expiry count.
- activation-generation/reactivation success/failure counts and pending-operation count; never activation IDs, owner IDs, or configuration revisions.

No raw distribution was available to this planning work. Before enabling a production site, the release owner reviews only these sanitized aggregate results from simulator/site qualification. Readiness requires all integrity counters to be zero; volume counters may be nonzero within published bounds.

## Verification datasets for TQ-011B

Use synthetic controlled identifiers and annotations only. Tests must cover: empty; 1; page boundary 500/501; row 9,999/10,000/10,001; work 19,999/20,000/20,001; four/five leases; exact 5-minute expiry with `RestartQuery`; 30-second timeout; date 3,660/3,661; annotation 512/513 FDRS scalars; identifier 128/129; cursor 512/513 bytes; duplicate ID; skipped ID; duplicate terminal; orphan session; incomplete restart; unknown code; machine/zone mismatch; activation interval/config change; activation generation 1,024/1,025; pending operation 500/501; cancellation at each intent/repository/receipt/publication boundary.

The expected result is complete `Ready` only at or within each accepted bound. Every exceeding/integrity case is the specified zero-value outcome.
