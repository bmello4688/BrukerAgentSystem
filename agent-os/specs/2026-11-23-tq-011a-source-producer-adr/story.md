# TQ-011A - TripleQuadUI report-source/producer ADR

## State

Review-ready planning decision. Independent Reviewer Integration acceptance and publication of this exact planning commit are still required. TQ-011B is not Development-ready until every gate in [implementation-handoff.md](implementation-handoff.md) is recorded with an immutable commit.

## Stakeholder goal and product outcome

Give Equipment, Event, and User reports one authoritative, bounded, disclosure-safe source inside `SubstanceAnalyzerCore.Service`. A report must either use a complete immutable FDRS snapshot for the activated instrument or return one closed zero-value outcome. It must never infer report facts from Uno state, legacy sample metadata, display names, access tokens, local time, or provider schema.

## Decision summary

1. **History:** `ForwardOnlyAtCutover`. Generation-1 `T0` is exactly the trusted restart occurrence captured at actual host `StartAsync` entry and committed by the initial activation transaction; restart start occurs at T0 and no product record may occur before it. There is no legacy import or dual read.
2. **Writes:** a new analyzer-owned `IAnalyzerReportSourceProducerV1` is the sole product facade over the published `IFdrsRepository` writer methods. Sample acceptance, terminal completion/recovery, restart lifecycle, session lifecycle, and explicit report annotations have typed methods.
3. **Queries:** the analyzer consumes the separately published `Reports.ReportSources.Contracts.IFdrsReportSourceQuery` in process. The provider belongs to `Reports.Persistence.DataService`; no report endpoint and no direct provider collection access are added.
4. **Activation/control:** Common.Reports SHR-011D3 owns typed atomic `Initial`/`Successor`/`Rollback` transitions, activation generations/T0, the closed operation/phase catalog, CBE-v1 identities/fingerprints, and durable operation journal. TQ-011B consumes that interface and remains blocked until it is published.
5. **Identity:** `MachineId` is a versioned SHA-256 controlled identifier derived only after health `Serving` and a subsequent event-applied connected hardware snapshot. The baseline exposes no reconciliation flag. Empty/invalid/change/collision states fail closed; no hardware change is authorized.
6. **Zone/time:** a deployment-owned `ReportsV1:ReportingZoneId` is resolved at activation and bound to canonical `tq-zone-v1` bytes/hash including all conversion properties. `TimeProvider.GetUtcNow()` supplies UTC instants. Ambient local time is prohibited.
7. **Visibility:** only committed terminal events, completed restart pairs, valid session states, and committed append-only annotations are query-visible through a D1/D2 immutable snapshot.
8. **Readiness:** writers start disabled and queries return zero values until D1/D2/D3 publication, machine/zone/clock/storage checks, durable retry recovery, trusted identity/config/alarm inputs, reconciliation, and conformance probes all pass.

## Prioritized follow-on stories

| Priority | Story | Outcome | Dependency/state |
|---|---|---|---|
| P0 | SHR-011D1 | Publish the versioned query contracts and conformance fixtures. | Publication SHA not yet available; mandatory gate. |
| P0 | [SHR-011D3](../2026-11-23-shr-011d3-report-source-control-store/story.md) | Publish typed atomic activation transitions/T0, CBE-v1 identities, closed operation catalog, and durable journal in Common.Reports. | Ready for Coordinator/Domain/UX triad; sequential 3/5/3 split; mandatory publication gate. |
| P0 | SHR-011D2 | Publish the DataService query provider over the shared storage abstraction and bind activation-history fingerprint/interval validation into each snapshot. | Starts only from accepted D1 and D3; mandatory gate. |
| P0 | Trusted TQ identity/session bridge | Supply durable `UserId`, `SessionId`, attempt correlation, and lifecycle notifications to the analyzer without exposing a token or display name. | Required before TQ-011B can be marked Development-ready. |
| P0 | Approved alarm mapping | Map analyzer result to `Clear`/`Alarm`/`Failure` and each alarm to an approved encoded code plus qualitative strength. | Bruker SME/owner approval required before writer activation. |
| P0 | TQ configuration-revision producer | Publish the canonical Event-affecting manifest and stable `sha256:` revision captured at sample acceptance without storing configuration values or paths. | Required because the current baseline has no approved revision producer. |
| P0 | TQ-011B | Implement the producer, D2/D3 provider registration, readiness gate, activation/recovery flow, and tests from this ADR. | Blocked by all preceding gates and Reviewer Integration acceptance of this ADR. |

No migration child is authorized or required. A later stakeholder requirement for pre-`T0` history must create a new owner-reviewed migration story and revise this ADR before any import work begins.

## Acceptance criteria

- [field-source-mapping.md](field-source-mapping.md) gives every D1 Equipment/Event/User field one source or one D1-permitted unavailable state.
- [ADR-TQ-011A.md](ADR-TQ-011A.md) freezes producer/query ownership, history, machine/zone/time, atomicity, cutover, reconciliation, restart, and rollback.
- [outcomes.md](outcomes.md) gives all fourteen outcomes disjoint typed trigger families and deterministic precedence/retry mappings, explicitly resolving multiple-active versus source corruption and invalid identity while readiness is disabled; every non-ready result contains no canonical values or sensitive/provider details.
- [data-volume-gap-report.md](data-volume-gap-report.md) records the structural evidence, limit fit, zero gap tolerance, and the reason no legacy data is read.
- [runbooks.md](runbooks.md) and [sequence-diagrams.md](sequence-diagrams.md) freeze normal flow, storage-first startup, cutover, restart, configuration reactivation, reconciliation, and rollback.
- [implementation-handoff.md](implementation-handoff.md) freezes the TQ-011B base, branch/worktree, owned/protected paths, tests, builds, readiness disablement, gitlink rollback, and release rollback owner requirement.
- All evidence citations resolve to immutable commits. Unpublished SHR-011D1/2/3 work is named only as a publication dependency, never cited as accepted product evidence.

## Non-goals

- No TripleQuadUI/Common.Reports/Common.DataService source, gitlink, runtime configuration, FDRS data, status board, or backlog change.
- No report calculations, rendering, printing, UI, public transport, hardware behavior, legacy import, data repair, or provider-schema change.
- No mapping of legacy `AnnotationData`, detected-substance names, quantities, scores, exception text, usernames, or tokens into report records.

## Delivery and capacity

- TQ-011A remediation size: 3 points. SHR-011D3 delivery is separately split 3/5/3 because its contract codec, transactional provider, and independent conformance/publication are sequential risk surfaces.
- Suggested TQ-011B batch: one Feature Engineer plus one Reviewer Integration; keep the session bridge and alarm-map owners available for contract questions. Do not parallelize edits to `ServiceHost.cs`, the Reports gitlink, or lifecycle hooks.
- Capacity risks: three unpublished shared contracts, shared gitlink movement, activation/control-store conformance, service startup order, missing trusted identity/session/config data, and SME-owned alarm semantics.
- Publication rollback: revert only this planning commit. This package changes no product/runtime state.
