# SHR-011D3 - durable report-source activation and operation control store

## State and product outcome

**State: triad remediation complete; ready for Coordinator Architect, Domain Analyst, and User Experience re-review. Not Development-ready.**

SHR-011D3 gives report producers and the D2 query provider one product-neutral, transactional Common.Reports authority for activation generations, query admission leases, operation intent/receipt recovery, and activation-history identity. It preserves the accepted typed `Initial`/`Successor`/`Rollback` model, generation-1 T0, zero-write rollback, CBE-v1 framing, deterministic identities, collision/integrity separation, and ambiguous-commit recovery. It does not change product, hardware, runtime, DataService, gitlink, status-board, or backlog source in this planning slice.

The delivery order is exact and sequential:

```text
published SHR-011D1 at Common.Reports 72fe39bdcc5ef494673c6f49180e26f31758a3dc
  -> SHR-011D3a contract, codec, profiles, vectors, conformance (5)
  -> SHR-011D3b transactional provider and schema composition (8)
  -> SHR-011D3c integration, validation, publication (3)
  -> SHR-011D2 query provider
  -> TQ-011B product producer
```

`72fe39bdcc5ef494673c6f49180e26f31758a3dc` is the accepted D1-containing integration candidate. D3a may be reviewed against it, but **must not claim Development-ready or start implementation until that exact SHA is visible on the live Common.Reports remote**. A different SHA, rebase, or equivalent tree requires dependency review.

## Child stories and immutable ownership

| Child | Size | Exact base | Branch / isolated worktree | Owned production paths | Starts after |
|---|---:|---|---|---|---|
| [D3a](../2026-11-23-shr-011d3a-report-source-control-contract/story.md) | 5 | published `72fe39bdcc5ef494673c6f49180e26f31758a3dc` | `feature/shr-011d3a-control-contract`; `C:\Git\Common.Reports-shr011d3a-control-contract` | new `Reports.ReportSourceControl.Contracts/**`, `Reports.ReportSourceControl.Contracts.Conformance/**`, focused tests/docs, additive solution entries | exact base is live and triad records GO |
| [D3b](../2026-11-23-shr-011d3b-report-source-control-provider/story.md) | 8 | accepted/published D3a SHA | `feature/shr-011d3b-control-provider`; `C:\Git\Common.Reports-shr011d3b-control-provider` | new `Reports.ReportSourceControl.DataService/**`; narrow additive schema-composition files and provider tests in existing persistence projects | D3a published |
| [D3c](../2026-11-23-shr-011d3c-report-source-control-integration/story.md) | 3 | accepted D3a+D3b integration tip | `feature/shr-011d3c-control-integration`; `C:\Git\Common.Reports-shr011d3c-control-integration` | additive composition/docs/conformance wiring only; no semantic redesign | D3a and D3b accepted |

Feature Engineering owns D3a, D3b, and D3c implementation. Reviewer Integration is the independent gate after each child and the final combined publication gate; it does not implement D3c or repair its own findings. Domain owns outcome/quiescence meaning, UX owns safe guidance/disclosure, and Architecture owns dependency/schema/runtime direction.

## Frozen boundaries across all children

1. **One shared core, reviewed profiles.** Common.Reports owns a product-neutral, versioned `report-source-control-core-v1` contract. Product operation kinds, logical-ID grammar, prefixes, payload field ordering, and acceptance receipt shapes live in a separately reviewed profile implementing the core profile contract. TQ-011B owns the closed `tq-report-source-v1` mapping at its product edge and must reproduce the already accepted TQ CBE/UUID vectors. No TQ literal, operation enum, or prefix is compiled into the shared core. Another product requires a separately reviewed profile/version; no fallback or free-form profile exists.
2. **One transactional store.** D3b and D2 use the same injected `ITransactionalDocumentStore`. Activation, operation, lease, FDRS evidence, and schema state are read in one exact `MachineId` partition transaction. There is no second database, ambient store locator, filesystem state, cache, lock table, or process-local correctness state.
3. **D3 owns D2 admission.** The core defines the lease schema and acquire/release/read contract that D2 must consume. Before D2 exists, its collection is initialized and empty; empty means no live lease and never means product Ready. Activation transitions may proceed only after the same transaction proves that no unexpired `Active` lease exists. D2 may not create a private lease collection or private field literals.
4. **Fail closed.** Unknown enum number/token/case, contract/schema/profile/partition version, malformed persisted bytes, noncanonical identifier, or incompatible state yields `UnsupportedVersion / DoNotRetry`, a null value, zero writes, and downstream `UnknownMapping / ContactSupport`. Invalid caller text is never echoed.
5. **Readiness is outside success.** Successful initialization, null current activation, empty history, empty pending operations, or empty leases do not imply product readiness. Writers and queries remain disabled until the accepted TQ startup sequence completes: hardware reconciliation, provider conformance, successful `RestartCompleted` accepted receipt, then writers, then queries.
6. **No destructive recovery.** No collection delete, row edit, old-T0 reactivation, operation-ID replacement, pointer-only repair, lease bypass, history truncation, or incompatible binary rollback exists. Proven-not-accepted recovery keeps the same deterministic identity and all immutable evidence.

## Shared invariants and downstream gate

- Activation history is complete, generation-ascending, contiguous, bounded at 1,024, canonical-hashed, and bound into every D2 snapshot/cursor.
- Quiescence is a closed predicate over exact FDRS collections, control rows, and leases; prose such as “compatible” or “no active work” is not executable authority.
- Every public/stored scalar, list, timestamp, version, enum, nullable field, and collection has construction and strict-deserialization N/N+1 tests.
- All public records/results use disclosure-safe `ToString()` and logging projections. Operator-safe support correlation is distinct from the internal deterministic operation correlation.
- Runtime composition is singleton store/provider/profile registry, stateless codecs, injected `TimeProvider`, and one per-machine transactional concurrency owner. No ambient identity, clock, cache, mutex, or current-user state is permitted.

SHR-011D2 remains blocked until D3c publishes an exact Common.Reports SHA. D2 must consume D3 activation-history fingerprint and lease APIs unchanged. TQ-011B remains blocked until D1, D3c, and D2 are published and its separately reviewed TQ profile reproduces all frozen TQ vectors.

## Planning acceptance and non-goals

Triad re-review must confirm all three child stories form one closed contract: dependencies, schema composition, lease/quiescence, history hashing, operation lifecycle/receipts, bounds, result tuples, disclosure, runtime composition, validation, rollback, and downstream gates. Any child change that alters another child's public or stored contract returns the package to triad.

Non-goals: no implementation in this planning commit; no Common.Reports/DataService/product/runtime/hardware/gitlink/status-board/backlog changes; no D2 provider; no TQ producer; no UI/gRPC; no migration or legacy import; no generalized plugin discovery; no diagnostic-text branching.
