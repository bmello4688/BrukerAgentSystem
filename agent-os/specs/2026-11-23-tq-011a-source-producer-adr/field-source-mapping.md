# TQ-011A field, source, and identity mapping

## Mapping rules

1. Every output is built by the published D2 provider from committed FDRS records for the exact activated machine. The analyzer never constructs report snapshots from UI/client/legacy models.
2. `OccurredUtc`/terminal payload UTC values are domain facts; `RecordedUtc` is ingestion metadata and never substitutes for them.
3. User/Event association is exact ordinal `SessionId` equality only. Username, display name, token, time overlap, and current UI session are prohibited joins.
4. A field not listed as D1-permitted unavailable blocks the whole page with a zero-value outcome.
5. The only permitted field-level unavailability is: `event.annotation = Unknown` with no value; `event.alarmReasons = Unknown` for an Alarm with no projected reasons; `session.endUtc = Deferred` for Open or `Incomplete` for Incomplete.

## Request and shared context

| Contract field | Authoritative source | Validation/disposition |
|---|---|---|
| contract version/query kind | constructor-bound D1 request type | Wrong/unknown version is zero-value `UnknownMapping`; no provider call. |
| machine | startup attempt's latched `tq-machine-v1` candidate before activation, then active SHR-011D3 binding after activation; both derive from a post-health, event-applied connected hardware snapshot | The first qualifying observation latches the attempt candidate. Caller and every later hardware/record/activation machine must equal that candidate before activation or the committed binding afterward. No qualifying observation is `SourceUnavailable`; invalid connected serial is `IdentityInvalid`; every syntactically valid difference, including a second distinct serial in the attempt, is only `MachineMismatch`. |
| inclusive start/end date | server-validated request | Convert to half-open UTC using the activated zone/rule fingerprint. Span and conversion must satisfy D1 limits. |
| reporting-zone ID | deployment option `ReportsV1:ReportingZoneId` bound in each activation interval | Caller cannot override it. Unknown/changed rules are `ZoneInvalid` until an approved successor activation. |
| Equipment division | D1 request enum Day/Week/Month/Year | Unknown is `UnknownMapping`; it affects downstream grouping, not source ordering. |
| Event ID | positive FDRS `SampleEventId` | Legacy sample number/repository ID never maps. Missing exact ID is D1 `NotFound`, mapped locally to zero-value `HistoryUnavailable`. |
| page size/cursor | D1 page request, D2 integrity-protected cursor | Enforce 1-500 and 512 UTF-8 bytes; no cursor inspection in product code. |
| completed/request time | injected `TimeProvider.GetUtcNow()` | Must be UTC and pass clock/readiness checks. |
| activation interval | SHR-011D3 immutable generation whose `[T0, successor T0)` contains the occurrence; generation-1 T0 is the exact captured restart occurrence | Before initial commit, classify against the latched attempt candidate; afterward classify against the committed binding. Every syntactically valid unequal machine claim is only `MachineMismatch`, including a different valid serial before activation and a second distinct valid serial in that attempt. After all claims equal, multiple active claimants are `IdentityCollision`, while missing/overlapping/corrupt interval or other source evidence is `SourceGap`. |

## Canonical Event fields

The same Event projection is used by Equipment, Event, and User queries.

| Canonical field | Authoritative producer/API | Provider projection and invalid behavior |
|---|---|---|
| `MachineId` | latched startup-attempt candidate before activation and activated producer binding captured in `StartSampleCommand.MachineId` afterward | Validate every request, hardware, partition/envelope, stored-record, and activation machine claim first: absent/default/malformed is `IdentityInvalid`; syntactically valid and unequal to the latched candidate before activation or committed binding afterward is only `MachineMismatch`; equal proceeds to later evidence checks. A different valid serial before activation and a second distinct valid serial during one activation attempt are never collisions. Missing/corrupt non-identity activation/source evidence after equality is `SourceGap`; only duplicate/conflicting equal-machine claims are `IdentityCollision`. |
| `SampleEventId` | `IFdrsRepository.StartSampleAsync` atomic high-water allocation | Positive, never reset/wrapped/reused. Duplicate/collision is `IdentityCollision`; discontinuity is `SourceGap`. |
| `EventCorrelationId` (ordering/integrity source identity) | RFC-4122 UUIDv5 over activation ID, `sample-start`, and the acceptance-attempt UUID already committed in SHR-011D3 | Exact deterministic retry only. Conflicting correlation for one Event is `IdentityCollision`; never exposed as operator guidance. |
| `StartUtc` (source integrity, not Event report display) | `TimeProvider.GetUtcNow()` captured at accepted `BeginCollecting` transition; repository applies logical boundary | Missing/non-UTC/backward-inconsistent value is `SourceGap`. |
| `EndUtc` | `CompleteSampleAsync` after analysis terminal result; startup recovery uses observed trusted UTC | Exact terminal UTC controls range attribution. Missing/duplicate/conflicting terminal is `SourceGap`. |
| `Result` | approved analyzer terminal mapper: exactly `Clear`, `Alarm`, or `Failure` | Unknown/unmapped result is `UnknownMapping`; no terminal is published. |
| `UserId` | separately published trusted UserManagement bridge, captured at Event start | Mandatory stable ID. Username/operator text is prohibited. Missing/changed identity is `IdentityInvalid`/`SourceGap`. |
| `SessionId` | same trusted bridge, captured at Event start and immutable through completion | Mandatory stable ID. Events join User sessions only by exact ID. Missing/inconsistent link is `SourceGap`. |
| `ConfigurationRevisionId` | approved canonical configuration-manifest producer, captured at Event start and matched to the activation interval | Exact `sha256:<64 lowercase hex>`; settings/path/content never enters reports. Missing/malformed identity is `IdentityInvalid`; unsupported manifest algorithm/version is `UnknownMapping`; mismatch with the applicable activation interval is `SourceGap`. A legitimate change requires an SHR-011D3 successor activation before another start. |
| `Result = Alarm` reason code | approved Bruker code mapper creates `AlarmReason.EncodedCode` | One per distinct code, ordinal sorted. Names/compounds are prohibited. No approved mapping blocks writer readiness. D1 provider may mark `event.alarmReasons = Unknown` only where its published contract permits it. |
| alarm strength | same approved mapper creates `AlarmReason.Strength` (`Low`/`Medium`/`High`) | Conflicting/unknown strength is `UnknownMapping`; quantity/score is not exposed. |
| current annotation | explicit authorized `AddEventAnnotationAsync`, append-only `EventAnnotationAddedPayload`; latest valid unsuperseded correction wins | Existing `AnnotationData` has no mapping. With no explicit record, return D1 `event.annotation = Unknown`, value absent. Invalid supersession/content blocks the page. |
| retained-data reference (not a canonical report field) | successful legacy scan repository save may provide one opaque controlled repository ID to completion | Optional support/audit link only; no file/path/scan data and never used to establish Event identity. |
| immutable source-record identity/order tie-breaker | persistence-assigned UUIDv7 record ID | Provider-only ordering key; never shown in local non-ready outcomes. |
| `SourceComponent` | name literal `triplequadui.substance-analyzer-core`; version from running service `AssemblyInformationalVersion` and bound in SHR-011D3 | Caller cannot override. Missing/malformed version is `UnknownMapping`; interval mismatch is `SourceGap`. |

### Event query cardinality

For `(activated MachineId, positive SampleEventId)`, D2 returns at most one complete terminal Event. Zero is D1 `NotFound` and local `HistoryUnavailable`. First, every syntactically valid machine-ID difference is `MachineMismatch` regardless of whether it appears in the request, partition/envelope, stored Event, or activation. Only after machine equality, more than one identity/terminal is `IdentityCollision`, while an open Event requested as terminal or missing/corrupt session/source evidence is `SourceGap`.

## Equipment query fields

| Canonical field | Authoritative source | Rule |
|---|---|---|
| header machine/range | activated machine + validated inclusive dates/zone | Must match every represented interval and start at/after generation 1 T0. |
| division | validated request | Day/Week/Month/Year only. |
| events | canonical terminal Event mapping above | Ordered `EndUtc`, `SampleEventId`, immutable source identity ascending. Empty is Ready with an empty sequence. |
| restart `StartUtc` | one trusted occurrence captured at actual host `StartAsync` entry | One startup-attempt UUID per actual host start; on generation 1 the activation commits this exact value as T0 and restart start occurs exactly at T0; later restarts must be at/after applicable T0. Deterministic CBE-v1 correlation/draft retry. |
| restart `EndUtc` | matching `RecordRestartCompletedAsync` payload | Must be UTC and not precede start. |
| restart completed/status | matching completed payload with controlled status/failure code | Only completed valid pairs are values. First, a syntactically valid machine-ID difference in either record is `MachineMismatch`. After machine equality, missing/corrupt pair evidence is `SourceGap` and duplicate identity claims are `IdentityCollision`. A failed restart may be a completed pair if D1 includes the published semantics. |
| restart order tie-breaker | immutable start/completion record identity | Provider-only; order `StartUtc`, `EndUtc`, source identity. |

## User query fields

| Canonical field | Authoritative producer/API | Provider projection and invalid behavior |
|---|---|---|
| `UserId` | trusted bridge; stable identity for credential attempt | Mandatory for granted and denied attempts. Display/operator name prohibited. |
| `SessionId` | trusted bridge creates it only for a granted session | Exact stable ID for Open/Completed/Incomplete; denied has no fabricated ID. |
| `StartUtc` | `RecordSessionStartedAsync`/attempt occurrence from trusted clock | Mandatory. An attempt correlation ties start and decision without becoming the SessionId. |
| access decision | `RecordSessionAccessDecisionAsync` with closed decision/code | Granted/Denied only; backend messages and role/capability names prohibited. |
| `EndUtc` | `RecordSessionEndedAsync` for a normal/recovery close | Completed requires exact UTC. Open is `Deferred`; crash-incomplete is `Incomplete`; denied legitimately has no end. |
| lifecycle state | D2 derives Denied/Open/Completed/Incomplete from the typed sequence and startup recovery evidence | Unknown/conflicting sequence is `SourceGap`; no synthetic end time. |
| associated events | terminal Events whose stored `SessionId` exactly equals the session ID | No join for denied attempts. No name/time/active-user inference. Inconsistent user on same session is `SourceGap`. |
| session ordering | start UTC, UserId ordinal, null SessionId first then SessionId ordinal, immutable source identity | Duplicate order identity is `IdentityCollision`; no provider order leaks. |

## Producer source ownership matrix

| Fact family | Product owner/hook | Analyzer facade | Shared persistence API |
|---|---|---|---|
| accepted sample start | `SampleCollector` asynchronous admission at device insertion, before collection state entry | `AcceptSampleAsync` | `StartSampleAsync` |
| terminal sample | awaited `SampleCollectionManager` terminal workflow | `CompleteSampleAsync` | `CompleteSampleAsync` |
| interrupted sample | reporting startup/reconciliation service | `RecoverInterruptedSampleAsync` | `RecoverInterruptedSampleAsync` |
| restart pair | host-to-analyzer lifecycle handoff + reporting startup service | `RecordRestartStartedAsync` / `RecordRestartCompletedAsync` | `AppendRecordAsync` |
| session attempt/lifecycle | published trusted UserManagement bridge | three typed session methods | `AppendRecordAsync` |
| annotation | future explicit authorized report-annotation command | `AddEventAnnotationAsync` | `AppendRecordAsync` |
| alarm reason | approved result/code/strength mapper in reporting boundary | input to `CompleteSampleAsync` | `CompleteSampleAsync` |
| activation/control state | Common.Reports SHR-011D3 provider; owner-approved cutover/reactivation/rollback hook | `IReportSourceControlStoreV1.TransitionActivationAsync` with closed mode/reason | atomic DataService transition in the machine partition |
| durable retry | producer journals; lifecycle service is sole dispatcher | D3 `CreateOrReadOperationAsync` / `ResolveOperationAsync` / `RetryProvenNotAcceptedAsync`; TQ edge profile supplies nine controlled kinds and CBE-v1 identities/fingerprints | D3 operation and immutable attempt collections through `IReportSourceControlStoreV1` only |

## Explicit prohibited sources

- Uno/view models, `UserSession.CurrentUserName`, access tokens, policy/capability names, localized messages.
- `ScanSeries.SampleNumber`, legacy repository ID as Event ID, metadata cache, sample files, export paths.
- `Environment.MachineName`, display instrument name, mutable current user/machine state at query time.
- `DateTime.Now`, current local zone, scan timestamp without provenance, workstation/instrument local clock.
- detected substance/display/unique names, compound names, quantities, raw scores/peaks, exception text.
- direct DataService collection/schema/provider access from product/report code.
