# TQ-011A local closed outcomes

## Result envelope

The analyzer facade exposes exactly `ReportSourceReadinessOutcomeV1` plus either one complete D1 value/page for `Ready` or no value. There is no partial value, fallback value, raw diagnostic, or unknown enum escape.

Every non-`Ready` outcome has all canonical source fields absent and exposes only:

- the closed outcome name;
- one closed support guidance code from this table;
- one closed retry disposition (`None`, `CorrectInput`, `RetryWhenReady`, `RestartQuery`, `ContactSupport`);
- an opaque local correlation reference that is redacted from default `ToString()` and is never a record/provider identity.

It never contains a path, record value/ID, machine/user/session identity, annotation/alarm value, cursor, exception text/type/stack, endpoint/port, provider/schema/collection name, token, source payload, or configuration value.

## Complete table

| Local outcome | Trigger/precedence | Retry | Disclosure-safe operator guidance | Value |
|---|---|---|---|---|
| `Ready` | Readiness is enabled and the complete D1 result is `Completed`; an empty Equipment/User page is allowed. | `None` | `report-source-ready` | Exactly one complete D1 page/value; may be contractually empty. |
| `SourceUnavailable` | Dependency/storage/provider not ready; contract/source version mismatch; producer disabled; snapshot busy/timeout; session/alarm/config prerequisite unavailable. | `RetryWhenReady` | `report-source-temporarily-unavailable` | None. |
| `HistoryUnavailable` | Forward-only request begins before `T0`, or a valid exact Event ID is absent from the activated FDRS partition; no legacy lookup/migration is attempted. | `CorrectInput` | `report-history-unavailable` | None. |
| `MigrationRequired` | Reserved fail-closed response if deployed state/config requires legacy history contrary to this ADR. It can never enable migration automatically. | `ContactSupport` | `report-history-policy-review-required` | None. |
| `MigrationIncomplete` | Target partition contains unexpected preactivation events/import receipts, a migration marker, or unclosed migration state. | `ContactSupport` | `report-history-state-not-ready` | None. |
| `IdentityInvalid` | Machine/user/session/config identity is absent, malformed, default, or cannot be proven stable. | `ContactSupport` | `report-identity-not-ready` | None. |
| `IdentityCollision` | Duplicate Event/session/source identity, conflicting correlation, duplicate machine binding, or more than one identity claims one logical fact. | `ContactSupport` | `report-identity-conflict` | None. |
| `MachineMismatch` | Request/source/current hardware identity differs from activated machine. | `ContactSupport` | `report-machine-binding-changed` | None. |
| `ZoneInvalid` | Zone missing/unknown, conversion invalid/ambiguous outside published rules, or current rule fingerprint differs from activation. | `ContactSupport` | `report-time-zone-not-ready` | None. |
| `SourceGap` | Discontinuous native Event source, missing/duplicate/conflicting terminal, orphan/inconsistent session link, incomplete restart pair, unresolved receipt, or clock/config boundary inconsistency. | `ContactSupport` | `report-source-integrity-check-required` | None. |
| `UnknownMapping` | Unknown/unsupported source version, payload/result/code/strength/lifecycle/field code, or unapproved mapping. | `ContactSupport` | `report-source-version-or-mapping-not-supported` | None. |
| `LimitExceeded` | D1 date/string/page/cursor/row/work bound is exceeded or cannot be proven. | `CorrectInput` for request bounds; otherwise `ContactSupport` | `report-request-or-source-limit-exceeded` | None. |
| `Canceled` | Caller cancellation wins before admission or at a D1 cancellation boundary before result publication. | `None` | `report-request-canceled` | None. |
| `InternalFailure` | Unexpected analyzer mapping/orchestration failure after known outcomes are excluded. | `ContactSupport` | `report-source-internal-failure` | None. |

## Deterministic precedence

When more than one condition is observable before publication, evaluate in this order:

1. cancellation already requested;
2. unsupported/malformed contract request or source version;
3. readiness dependencies: machine, zone, clock, storage, session bridge, alarm mapper, config/source version;
4. history/migration state;
5. D1 admission/request/lease limits;
6. machine/identity/source integrity and mapping;
7. cancellation/timeout during provider work according to the published D1/D2 race rule;
8. publish `Ready` once only.

A committed write/result already accepted by persistence remains accepted even if caller cancellation arrives afterward. A published terminal query result is final.

## D1/D2 mapping

The implementation maps the published query result without inspecting provider diagnostics:

| Shared result family | Local outcome |
|---|---|
| `Completed/None/None` | `Ready` |
| Event `NotFound/RequestedEventNotFound` | `HistoryUnavailable`; no Event value and no legacy lookup |
| request rejection for machine/range/zone/division/event/page/cursor | `IdentityInvalid`, `HistoryUnavailable`, `ZoneInvalid`, or `LimitExceeded` according to the already validated field; no provider text |
| snapshot capacity/storage unavailable/query timeout | `SourceUnavailable` |
| lease expired | `SourceUnavailable` with `RestartQuery` |
| operation canceled | `Canceled` |
| corrupt/duplicate/inconsistent/discontinuous source | `IdentityCollision`, `MachineMismatch`, or `SourceGap` by the closed reason |
| unknown source code/version | `UnknownMapping` |
| row/work/string limit | `LimitExceeded` |
| provider failure | `InternalFailure` |

## Logging/support rule

Structured logs may include only local outcome, closed guidance code, component/version, and a generated redacted support correlation. Sensitive values stay inside authorized FDRS/query objects. `Ready` pages, cursor bytes, identities, annotations, alarms, tokens, exceptions, provider types, endpoints, collection names, and paths are never serialized to normal logs or telemetry. Export/print cannot expand query authorization or diagnostics.
