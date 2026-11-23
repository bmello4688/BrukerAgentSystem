# ADR: DHS shared reporting authorization migration

- Decision ID: `DHS-025A0A-v1`
- Decision status: accepted and decision-complete for publication review
- Authoritative Services publication: `985f19bd059242597915d2a38fc728e8892df896`
- Legacy evidence baseline: DHS-GUI `c060f9db8e2f476b5a50b15d6e9c23e39c24b804`
- Policy authority: published SHR-030 plus implemented/reviewed SHR-032
- Supersession rule: a later path is valid only through a separately reviewed ADR

## Context and outcome

Legacy DHS owns a local ASP.NET Identity store, bearer tokens, an in-process identity host, cached UI
policy, and a single `CanViewRecallAndPrintAllReports` Boolean. Shared UserManagement owns a different
store and lifecycle, three selectable roles, additive compatibility bundles, distinct report access,
export, and print capabilities, a global MFA switch, protected TOTP/recovery state, and revocable
service-memory-bound access tokens.

The selected outcome makes shared UserManagement the only trusted authentication/session source and
the only reporting authorization source. The product rechecks the exact capability at each protected
boundary. A UI projection, legacy policy, role label, token claim by itself, cached policy, or offline
cache never authorizes reporting.

## Frozen decisions

| ID | Topic | Accepted decision |
|---|---|---|
| D01 | Account transition | `ControlledReprovisioning`; create a distinct shared account for every retained legacy account and record an immutable legacy-ID-to-shared-ID mapping manifest. |
| D02 | Credential transition | Unique temporary credential plus mandatory reset on first shared login. Password hashes, password material, security stamps, and reset tokens are not copied. |
| D03 | MFA transition | Do not copy legacy TOTP secrets/counters. Record prior state, set the shared disposition to re-enrollment required for legacy-enrolled/setup-pending users, and complete enrollment through shared setup/verify/recovery APIs. |
| D04 | Session cutover | Invalidate all legacy sessions. No one-time exchange, token translation, or dual acceptance exists. All users reauthenticate to shared UserManagement. |
| D05 | Token path | Use `UserManagement.Client.UserManagementClient` and its exact `Login`, MFA continuation, `GetAccessPolicy`, and `CancelAccessToken` APIs. Keep the access token in process memory only. No refresh contract exists; expiry, restart, or revocation requires login. |
| D06 | Service lifecycle | The DHS process owns one shared `ServiceHost` instance, starts it before creating the authorization client, waits for `Self=SERVING`, and stops it after product authorization consumers. Loopback HTTP/2 port 7046 is the default; approved configuration may override the port/address. |
| D07 | Offline/degraded behavior | Reporting is unavailable and protected content is removed. No cached-rights authorization, offline token validation, or legacy fallback is allowed. Unrelated non-report DHS workflows remain available. |
| D08 | Cutover | Stop DHS, reconcile at 100%, deploy the A0B binary, disable legacy host startup, remove old executable launchability, atomically install the hash-bound v1 activation document, start shared service, then start DHS. |
| D09 | Mixed version | `N-1` and `N` are never concurrently authorized. Before activation every `N` build reports `Disabled`; after activation only the exact A0B build and Services `985f19b` may report `Ready`. Any mismatch is `Unavailable`. |
| D10 | Reconciliation | All retained accounts and all fields require an explicit disposition; every count must match, every mapping must be unique, and conflicts/unknowns must be zero. The exact thresholds are in [mapping-and-reconciliation.md](mapping-and-reconciliation.md). |
| D11 | Rollback | The last rollback-to-legacy point is immediately before activation. After activation there is no return to legacy authority; preserve shared account changes and roll forward while reporting remains unavailable. |
| D12 | Legacy retirement | A0B retains the stopped legacy store and code as read-only evidence for a separately reviewed destruction story. It removes them from startup/composition and denies execution; it does not delete them. |

## Authority and request-local identity contract

### Authentication and policy

1. A successful shared login is the only way to create a DHS authorization session.
2. Every report-surface entry, generation, completed-report view, export, print, print-setting change,
   and SSI edit calls shared `GetAccessPolicy` with the current access token immediately before its
   protected boundary.
3. Required capabilities are exact:
   - report surface, Equipment/Event/User generation, and completed view: `CanAccessReports`;
   - export: `CanExportReports` immediately before destination mutation;
   - print: `CanPrintReports` immediately before spool submission;
   - print/auto-print settings: `CanEnableDisablePrinting` immediately before persistence;
   - controlled SSI edit: `CanEditSecurityFooter` immediately before persistence.
4. `CanViewRecallAndPrintAllReports`, `CanTransferDataToUsb`, role names, and any UI enabled state
   never satisfy these checks.

### Actor and session identity supplied to SHR-014C

Services `985f19b` does not publish a session-context RPC. A0B therefore uses only values derived from
the exact service-issued token after that same token has succeeded in a request-local
`GetAccessPolicy` call:

- `ActorUserId`: the single ASP.NET Identity name-identifier claim, normalized as a lowercase `D`
  GUID. Missing, duplicate, non-GUID, or changing values fail closed.
- `SessionId`: `urn:bruker:user-management-session:v1:` plus unpadded base64url SHA-256 of the exact
  UTF-8 access-token bytes. The token itself is never placed in the envelope, log, outcome, or UI.
- `SourceComponent`: the reviewed DHS A0B assembly identity and version.
- `ConfigurationRevision`: the lowercase SHA-256 of the canonical activation document.
- `MachineId`: the existing trusted product machine-identity source required by SHR-014C; it is
  captured once per invocation and must match the report-source scope.

The adapter constructs a new immutable context for each invocation after authoritative policy
success. It stores no actor or session in static/ambient state. Token decoding alone is never
authorization: the service-memory token binding and current account state are validated by
`GetAccessPolicy` first. The actor/session values are discarded on logout, denial, expiry,
revocation, service restart, policy loss, or any mismatch.

### Token issuer, audience, validation, storage, and lifetime

- Logical issuer: the local shared UserManagement service at Services commit `985f19b`.
- Audience: calls to that UserManagement instance only. The current JWT has no `iss` or `aud`
  claims; A0B must not treat it as a general product bearer token.
- Validation: only a successful service RPC that calls the shared server's token validator is
  authoritative. Local parsing is limited to deriving the already-validated actor/session audit
  identifiers.
- Storage: one access token in the session object's private memory; never disk, settings, crash text,
  clipboard, command line, telemetry, or default logs.
- Propagation: pass explicitly to the single request-local authorization call and then immediately
  construct the immutable invocation context. No global header or ambient context.
- Expiry: one day at issuance, bounded by the service-memory mapping. Service restart invalidates it
  earlier.
- Refresh: unsupported. Reauthenticate.
- Revocation: `CancelAccessToken`; managed role/bundle/disabled changes, password reset, MFA reset,
  and recovery revoke the current service token. The next protected call fails closed.

## Versioned configuration and readiness contract

The activation document is canonical UTF-8 JSON with lexicographically ordered property names, no
insignificant whitespace, lowercase SHA-256 values, and these exact fields:

| Field | Exact value/format |
|---|---|
| `accountManifestSha256` | Runtime-bound SHA-256 of the accepted canonical account manifest; exactly 64 lowercase hexadecimal characters. |
| `activatedUtc` | Runtime-bound activation instant in RFC3339 UTC form with `Z`. |
| `contract` | Literal `dhs.authorization-cutover/v1`. |
| `dhsCommit` | Exact 40-character lowercase commit ID accepted for A0B. |
| `mode` | Literal `Shared`. |
| `reconciliationManifestSha256` | Runtime-bound SHA-256 of the accepted canonical reconciliation manifest; exactly 64 lowercase hexadecimal characters. |
| `servicesCommit` | Literal `985f19bd059242597915d2a38fc728e8892df896`. |

Before activation the document is absent and readiness is `Disabled`. The cutover tool writes a
temporary file in the same directory, flushes file and directory metadata, and performs an atomic
replacement. Its full-document SHA-256 is the `ConfigurationRevision`.

| Readiness | Exact condition | Reporting behavior |
|---|---|---|
| `Disabled` | Activation document absent. | Report navigation/actions unavailable; no legacy authorization read. |
| `Unavailable` | Document present but malformed/unknown, commit or hash mismatch, migration incomplete, service not `SERVING`, MFA policy non-authoritative, no valid session, policy RPC failure, or identity/context conflict. | Fail closed, remove protected report content, retain unrelated workflows, show safe guidance. |
| `Ready` | Exact v1 document; exact DHS/Services commits; both manifests hash-match and passed; service `SERVING`; MFA policy authoritative; current shared session validates; current exact operation is allowed. | Permit only that checked operation and issue its request-local trusted context. |

Unknown fields are allowed only if the `contract` remains exactly v1 and the v1 parser explicitly
ignores them. Unknown contract values, missing required fields, duplicated JSON keys, invalid
canonicalization, or unsupported modes are `Unavailable`.

## Cutover and failure invariants

- The activation document is the single atomic authority switch; no database Boolean participates.
- The legacy host, client, token cache, and `AccessPolicy` may exist only in stopped/read-only
  rollback evidence. Production composition has no reference from report authorization to them.
- A0B build-time dependency tests reject any report-authorization reference to the legacy combined
  permission or legacy identity client/host.
- Startup never becomes `Ready` until the shared service health stream reports `SERVING` and all
  manifests match.
- A service restart empties the service token cache. DHS immediately discards its token and protected
  content and requires login.
- Revocation races are resolved at the protected boundary: a failed or revoked recheck prevents
  source access/mutation. A revocation after an irreversible boundary is audited as the real effect;
  it is never reported as prevented.
- Cancellation before the authoritative check returns `Canceled`; after accepted audit start it
  follows SHR-014C shielding/terminal rules.
- Default operator text never includes identity, session, token, correlation, configuration revision,
  path, endpoint, provider/store, exception, or credential detail.

## Rejected alternatives

| Alternative | Rejection |
|---|---|
| `MigrateAccounts` by migrating the legacy database or password hashes | Store schemas, authorization semantics, MFA secret handling, token validation, and role models differ; a lossless reviewed migration contract does not exist. |
| Copy legacy TOTP secret/counter | Shared Services requires DPAPI-protected TOTP state, replay tracking, and recovery-code acknowledgement; legacy material has no approved transform. |
| Map `CanViewRecallAndPrintAllReports` to all three shared rights | It collapses separately approved access/export/print capabilities and silently broadens authority. |
| Accept legacy sessions or exchange them | Legacy tokens have different signing, caching, issuer/audience behavior and no trusted shared session identity. |
| Cache policy for offline reporting | Cached rights cannot prove current account, revocation, role, token, or service state. |
| Locally validate JWT and continue when service is down | The authoritative validator depends on the service's in-memory token binding and current account state. |
| Add a token refresh path in DHS | Services `985f19b` has no refresh RPC; reauthentication is the closed behavior. |
| Roll back to legacy authority after activation | Post-cutover shared account/MFA/session changes cannot be safely reconciled backward and would reintroduce the prohibited combined permission. |

## Consequences

- Every retained user must complete a controlled password reset; previously enrolled users must
  re-enroll when MFA enforcement requires it.
- Supervisor reporting becomes allowed and QA/Service bundle-only reporting becomes denied according
  to the separately approved shared matrix. These are explicit governed changes, not inferred legacy
  mappings.
- Service outage or restart interrupts reporting and requires reauthentication, but does not block
  unrelated DHS workflows.
- The legacy store remains sensitive read-only evidence until a separate reviewed retirement story.
