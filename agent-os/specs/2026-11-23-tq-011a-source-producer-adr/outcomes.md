# TQ-011A local closed outcomes

## Result envelope and typed trigger selection

The analyzer returns exactly `ReportSourceReadinessOutcomeV1` plus either one complete D1 value/page for `Ready` or no value. There are exactly fourteen local outcomes. There is no partial/fallback value, raw diagnostic, or unknown-enum escape.

Every non-`Ready` result exposes only the outcome, closed guidance code, typed retry disposition (`None`, `CorrectInput`, `RetryWhenReady`, `RestartQuery`, or `ContactSupport`), and an opaque local support correlation redacted from default `ToString()`. Canonical source fields, paths, values/IDs, identities, annotations/alarms, cursors, exceptions, endpoint/provider/schema/collection names, tokens, source payloads, and configuration values are absent.

Classification never starts from a Boolean "readiness disabled" flag or diagnostic text. Each validation/provider adapter emits one closed `OutcomeTriggerV1` member from the families below. The first family reached in the frozen precedence is the only selected trigger, so every request has one outcome/retry even when several bad facts coexist. Readiness is an effect of that trigger, not a competing trigger.

## Fourteen disjoint trigger families

| # | Outcome | The only trigger family and its closed members | Exact retry | Guidance | Value |
|---:|---|---|---|---|---|
| 1 | `Ready` | `Completed`: every earlier stage passed and D1 atomically published one immutable completed result. Contractually empty Equipment/User pages are completed values. | `None` | `report-source-ready` | One complete value/page. |
| 2 | `SourceUnavailable` | `Availability`: `DependencyNotReady`, `CompatibleComponentAbsent`, `KnownMixedRuntimeVersion`, `SnapshotAdmissionBusy`, `ProviderTimeout`, `StorageUnavailable`, `PendingReceiptUnresolved`, `AwaitingApprovedActivation`, or `LeaseExpired`. A bare disabled flag is not a member. | `RestartQuery` only for `LeaseExpired`; otherwise `RetryWhenReady`. | `report-source-temporarily-unavailable` | None. |
| 3 | `HistoryUnavailable` | `HistoryBoundary`: `RangeStartsBeforeGeneration1T0`, `ExactEventAbsentFromApplicableIntervals`, or `PublishedRetentionBoundary` only when D1 supplies an explicit complete coverage boundary. A missing/corrupt activation interval is family 10. | `CorrectInput` | `report-history-unavailable` | None. |
| 4 | `MigrationRequired` | `PolicyConflict`: deployed policy explicitly requests pre-T0 legacy history while the accepted policy is `ForwardOnlyAtCutover`. | `ContactSupport` | `report-history-policy-review-required` | None. |
| 5 | `MigrationIncomplete` | `InitialPartitionNotEmpty`: initial transition finds any preactivation Event/import/import-receipt/migration/operation state. This family is evaluated only while no activation has ever committed. | `ContactSupport` | `report-history-state-not-ready` | None. |
| 6 | `IdentityInvalid` | `IdentitySyntax`: a required machine/user/session/config identity is absent, default, malformed, or unstable, including invalid connected serial or malformed `sha256:` configuration ID. It contains no duplicate/conflict or valid-machine-change member. | `ContactSupport` | `report-identity-not-ready` | None. |
| 7 | `IdentityCollision` | `IdentityClaimConflict`: two or more claimants use one Event/session/source/activation/operation/correlation identity, the same identity has different canonical fingerprints, two activation rows claim `Active`, a second initial activation is attempted, or two successors replace the same predecessor. It never represents a missing row/ID. | `ContactSupport` | `report-identity-conflict` | None. |
| 8 | `MachineMismatch` | `ValidMachineDifference`: request, current post-health hardware observation, stored record, or applicable activation contains a syntactically valid machine ID different from the committed binding. | `ContactSupport` | `report-machine-binding-changed` | None. |
| 9 | `ZoneInvalid` | `ZoneDefinition`: zone ID absent/unknown, requested local time invalid/ambiguous under the published rule, canonical rule serialization invalid, or current rule fingerprint differs from the active binding before record admission. | `ContactSupport` | `report-time-zone-not-ready` | None. |
| 10 | `SourceGap` | `SourceIntegrity`: a required native ID/row/terminal/session/restart/generation/successor is missing; pointer disagrees without a second active claimant; activation or receipt evidence is corrupt/inconsistent; interval-bound machine/zone/source/config fields disagree; or trusted clock/logical boundary is inconsistent. Duplicate identity claims are excluded and always family 7. | `ContactSupport` | `report-source-integrity-check-required` | None. |
| 11 | `UnknownMapping` | `UnsupportedSemantic`: request/persisted contract, payload, source assembly version, configuration-manifest algorithm/version, result/code/strength/lifecycle, or field mapping is unknown or unsupported. A known compatible runtime-version mismatch is family 2. | `ContactSupport` | `report-source-version-or-mapping-not-supported` | None. |
| 12 | `LimitExceeded` | `BoundExceeded`: `CallerBound` for date/string/page/cursor input, or `ProviderBound` for row/work/source/generation limit. | `CorrectInput` for `CallerBound`; `ContactSupport` for `ProviderBound`. | `report-request-or-source-limit-exceeded` | None. |
| 13 | `Canceled` | `CancellationWon`: caller cancellation was observed at the admission checkpoint, or provider cancellation won the atomic publication race before a completed result. Cancellation after an accepted write/completed publication is not a member. | `None` | `report-request-canceled` | None. |
| 14 | `InternalFailure` | `UnexpectedDefect`: an exception/undefined adapter result escaped after all thirteen defined families were excluded. No published provider failure is routed here when it has a family above. | `ContactSupport` | `report-source-internal-failure` | None. |

No trigger member appears in two rows. `SourceUnavailable` and `LimitExceeded` are the only outcomes with reason-selected retry, and their closed reason members above select it without text parsing.

## Frozen precedence and conflict resolution

Evaluate in this exact order and stop after emitting one trigger:

1. admission cancellation checkpoint -> `CancellationWon`;
2. local request bounds/policy/semantic syntax -> `BoundExceeded(CallerBound)`, `PolicyConflict`, `UnsupportedSemantic`, `IdentitySyntax`, then `ZoneDefinition`;
3. current valid bindings -> `ValidMachineDifference`, `ZoneDefinition`, `UnsupportedSemantic`; then typed `Availability` dependency state;
4. initial-only state -> `InitialPartitionNotEmpty`; established history -> `HistoryBoundary`;
5. cursor lease/capacity -> `Availability(LeaseExpired|SnapshotAdmissionBusy)`;
6. provider identity claims -> `IdentityClaimConflict`; this explicitly makes **multiple active activation claimants `IdentityCollision`, never `SourceGap`**;
7. provider machine -> `ValidMachineDifference`; missing/corrupt/interval evidence -> `SourceIntegrity`; unsupported version/code -> `UnsupportedSemantic`; bounds -> `BoundExceeded(ProviderBound)`;
8. atomic provider publication race -> `CancellationWon`, then typed `Availability`;
9. defined completed result -> `Completed`; otherwise -> `UnexpectedDefect`.

A syntactically invalid required identity therefore returns `IdentityInvalid` before availability is considered, even when readiness is disabled. If identity is valid and a dependency is unavailable, the result is `SourceUnavailable`. The disabled flag alone never masks the stored typed cause. A committed write remains accepted if cancellation arrives later; its receipt is resolved and journaled without the canceled request token.

## D1/D2/D3 mapping requirement

D1/D2/D3 must publish closed enum reasons sufficient to select these trigger members. If they do not, TQ-011B remains blocked and this ADR is amended. Product code never parses diagnostic text.

| Shared semantic | Trigger -> local result |
|---|---|
| completed | `Completed -> Ready/None` |
| exact Event absent/range before T0 | `HistoryBoundary -> HistoryUnavailable/CorrectInput` |
| invalid identity | `IdentitySyntax -> IdentityInvalid/ContactSupport` |
| invalid/changed zone before admission | `ZoneDefinition -> ZoneInvalid/ContactSupport` |
| caller/provider bound | `BoundExceeded(CallerBound|ProviderBound) -> LimitExceeded/CorrectInput|ContactSupport` |
| busy/storage unavailable/timeout | `Availability -> SourceUnavailable/RetryWhenReady` |
| lease expired | `Availability(LeaseExpired) -> SourceUnavailable/RestartQuery` |
| cancellation won | `CancellationWon -> Canceled/None` |
| duplicate/reused ID, fingerprint collision, multiple active rows | `IdentityClaimConflict -> IdentityCollision/ContactSupport` |
| valid machine difference | `ValidMachineDifference -> MachineMismatch/ContactSupport` |
| missing/corrupt/discontinuous/inconsistent source | `SourceIntegrity -> SourceGap/ContactSupport` |
| unknown source code/version | `UnsupportedSemantic -> UnknownMapping/ContactSupport` |
| undefined adapter defect after exhaustive mapping | `UnexpectedDefect -> InternalFailure/ContactSupport` |

## Logging/support rule

Structured logs may include only local outcome, closed guidance code, component/version, readiness transition, and generated redacted support correlation. `Ready` pages, cursor bytes, identities, annotations, alarms, tokens, exceptions, provider types, endpoints, collection names, paths, and activation/configuration values are never serialized to ordinary logs or telemetry. Export/print cannot expand query authorization or diagnostics.
