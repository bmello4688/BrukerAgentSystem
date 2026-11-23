# TQ-011A local closed outcomes

## Result envelope

The analyzer facade exposes exactly `ReportSourceReadinessOutcomeV1` plus either one complete D1 value/page for `Ready` or no value. There are exactly fourteen local outcomes. There is no partial value, fallback value, raw diagnostic, or unknown enum escape.

Every non-`Ready` outcome has all canonical source fields absent and exposes only the closed outcome, the exact closed guidance code below, the trigger-selected retry disposition (`None`, `CorrectInput`, `RetryWhenReady`, `RestartQuery`, or `ContactSupport`), and an opaque local support correlation redacted from default `ToString()`. It never contains a path, record value/ID, machine/user/session identity, annotation/alarm value, cursor, exception detail, endpoint, provider/schema/collection name, token, source payload, or configuration value.

## Complete fourteen-outcome trigger/retry table

| # | Local outcome | Exhaustive trigger | Exact retry | Guidance | Value |
|---:|---|---|---|---|---|
| 1 | `Ready` | Readiness is `Ready` and D1 returns one immutable `Completed` result; contractually empty Equipment/User pages are included. | `None` | `report-source-ready` | One complete value/page. |
| 2 | `SourceUnavailable` | Required service/storage/provider/session/alarm/config dependency is not ready; known compatible component is absent or mixed-version; readiness is disabled; snapshot admission is busy; provider work times out; a pending receipt cannot yet be resolved; or current valid configuration differs from the active binding and awaits an approved successor activation. | `RetryWhenReady`, except an expired cursor lease is exactly `RestartQuery`. | `report-source-temporarily-unavailable` | None. |
| 3 | `HistoryUnavailable` | Valid range starts before the earliest applicable activation T0; a range crosses an unrepresented activation interval; or a valid exact Event ID is absent from all applicable activated intervals. | `CorrectInput` | `report-history-unavailable` | None. |
| 4 | `MigrationRequired` | Deployed policy/config explicitly requests pre-T0 legacy history contrary to `ForwardOnlyAtCutover`. | `ContactSupport` | `report-history-policy-review-required` | None. |
| 5 | `MigrationIncomplete` | Initial target partition contains preactivation Events/import receipts/migration state, or a migration marker is open/conflicting. | `ContactSupport` | `report-history-state-not-ready` | None. |
| 6 | `IdentityInvalid` | Required machine/user/session/config identity is absent, default, syntactically malformed, or not stable; this includes a connected applied snapshot with invalid serial and malformed `sha256:` configuration identity. | `ContactSupport` | `report-identity-not-ready` | None. |
| 7 | `IdentityCollision` | Duplicate/reused Event/session/source/operation identity, same correlation with a different fingerprint, duplicate active activation, or more than one identity claims one logical fact. | `ContactSupport` | `report-identity-conflict` | None. |
| 8 | `MachineMismatch` | Request, record, current post-health hardware observation, or activation interval has a different valid machine identity. | `ContactSupport` | `report-machine-binding-changed` | None. |
| 9 | `ZoneInvalid` | Zone ID is absent/unknown; local-date conversion is invalid or ambiguous under the published conversion rule; canonical rule serialization is invalid; or current fingerprint differs from the active interval. | `ContactSupport` | `report-time-zone-not-ready` | None. |
| 10 | `SourceGap` | Native Event sequence is discontinuous; terminal/session/restart/activation sequence is missing, duplicate, conflicting, or orphaned; a receipt resolves to conflicting evidence; a record's machine/zone/source/config does not match its activation interval; or trusted clock/logical boundary is inconsistent. | `ContactSupport` | `report-source-integrity-check-required` | None. |
| 11 | `UnknownMapping` | Request/persisted contract or payload version is unknown/unsupported; source assembly version is missing/malformed; configuration manifest algorithm/version is unsupported; or result/code/strength/lifecycle/field mapping is unknown or unapproved. A known compatible runtime version mismatch is outcome 2, not this outcome. | `ContactSupport` | `report-source-version-or-mapping-not-supported` | None. |
| 12 | `LimitExceeded` | Caller-controlled date/string/page/cursor bound is exceeded or unprovable, or provider row/work/source limit is exceeded. | `CorrectInput` for caller-controlled bounds; `ContactSupport` for provider row/work/source limits. | `report-request-or-source-limit-exceeded` | None. |
| 13 | `Canceled` | Caller cancellation is observed before admission, or wins the provider cancellation/publication race before a completed result is published. | `None` | `report-request-canceled` | None. |
| 14 | `InternalFailure` | Unexpected analyzer orchestration/mapping defect after every defined trigger above has been excluded; ordinary provider failure with no published closed family maps here. | `ContactSupport` | `report-source-internal-failure` | None. |

The two outcomes with trigger-selected retries are deterministic: `SourceUnavailable + LeaseExpired -> RestartQuery`; every other `SourceUnavailable -> RetryWhenReady`. `LimitExceeded + CallerBound -> CorrectInput`; `LimitExceeded + ProviderRowWorkOrSourceBound -> ContactSupport`. No caller/provider text selects a retry.

## Deterministic precedence

Evaluate all observable facts in this order and stop at the first row:

1. caller cancellation already requested -> `Canceled`;
2. local request validation -> `UnknownMapping`, `IdentityInvalid`, `ZoneInvalid`, `LimitExceeded`, or `MigrationRequired` by the exact definitions above;
3. readiness and current binding checks -> `MachineMismatch`, `ZoneInvalid`, `UnknownMapping`, `SourceUnavailable`, then `IdentityInvalid`;
4. activation/history state -> `MigrationIncomplete`, `HistoryUnavailable`;
5. cursor lease check -> `SourceUnavailable/RestartQuery`; new-snapshot capacity -> `SourceUnavailable/RetryWhenReady`;
6. provider integrity -> `IdentityCollision`, `MachineMismatch`, `SourceGap`, `UnknownMapping`, then provider `LimitExceeded`;
7. provider cancellation beats completed publication -> `Canceled`; provider timeout/unavailable -> `SourceUnavailable/RetryWhenReady`;
8. defined provider failure -> mapped family below; undefined failure -> `InternalFailure`;
9. publish `Ready` exactly once.

A committed write accepted by persistence remains accepted even if cancellation arrives later. The producer resolves and journals that receipt without the canceled request token. A D1 completed result that wins the atomic publication race remains final.

## D1/D2 mapping requirement

D1 publication must expose closed result/reason values sufficient for this exact mapping; otherwise TQ-011B remains blocked and this ADR is amended. Product code never inspects diagnostic text.

| Shared semantic family | Local result |
|---|---|
| completed, no failure | `Ready/None` |
| exact Event not found | `HistoryUnavailable/CorrectInput` |
| invalid request identity | `IdentityInvalid/ContactSupport` |
| invalid range before T0 | `HistoryUnavailable/CorrectInput` |
| invalid/changed zone | `ZoneInvalid/ContactSupport` |
| caller request bound | `LimitExceeded/CorrectInput` |
| row/work/source bound | `LimitExceeded/ContactSupport` |
| snapshot busy, storage unavailable, timeout | `SourceUnavailable/RetryWhenReady` |
| lease expired | `SourceUnavailable/RestartQuery` |
| operation canceled before publication | `Canceled/None` |
| duplicate/collision | `IdentityCollision/ContactSupport` |
| machine mismatch | `MachineMismatch/ContactSupport` |
| corrupt/discontinuous/inconsistent source | `SourceGap/ContactSupport` |
| unknown source code/version | `UnknownMapping/ContactSupport` |
| defined provider failure not represented above | `InternalFailure/ContactSupport` |

## Logging/support rule

Structured logs may include only local outcome, closed guidance code, component/version, readiness transition, and a generated redacted support correlation. `Ready` pages, cursor bytes, identities, annotations, alarms, tokens, exceptions, provider types, endpoints, collection names, paths, and activation/configuration values are never serialized to ordinary logs or telemetry. Export/print cannot expand query authorization or diagnostics.
