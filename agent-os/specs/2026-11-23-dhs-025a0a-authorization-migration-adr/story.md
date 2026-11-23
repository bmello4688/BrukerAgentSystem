# DHS-025A0A — DHS Reporting Authorization Migration ADR

## State

Ready for dedicated Domain, Security/UX, and Architecture closure. Planning/decision only; not
Development-ready implementation.

## Outcome

Publish the exact migration/cutover plan by which shared Services/UserManagement becomes the sole
authoritative DHS reporting authorization and trusted actor/session source, with no legacy combined-
permission fallback.

## Fixed policy premise

- Shared Services/UserManagement `985f19bd059242597915d2a38fc728e8892df896` is authoritative for
  reporting.
- `CanAccessReports`, `CanExportReports`, and `CanPrintReports` stay distinct.
- Legacy `CanViewRecallAndPrintAllReports` never grants or backfills shared capabilities.
- MFA enforcement remains operator-configurable on/off; enrollment is not silently destroyed;
  authorized per-user setup/disable/reset/recovery remains supported.
- Policy/session service loss, stale/revoked session, unknown/conflicting identity/rights, and mixed
  authority fail closed.

## Evidence and questions resolved by the ADR

1. Inventory legacy DHS account, role, credential, MFA-enrollment, recovery, token, session, lockout,
   audit, and store ownership/lifetimes.
2. Identify every DHS reporting authorization call site and every actor/session consumer required by
   SHR-014C.
3. Compare legacy identities/roles with shared Services stable IDs, selectable roles, bundles,
   rights, MFA, session, token, and revocation contracts.
4. Select controlled reprovisioning because accounts, credentials, and MFA enrollment cannot be
   migrated losslessly under an approved contract.
5. Freeze active-session/token behavior, degraded operation, startup ordering, service health, and
   mixed-version deployment behavior.

## Binary decisions frozen by the ADR

- **Account transition:** `ControlledReprovisioning` with a new shared ID for every retained legacy
  account; the seeded bootstrap account is never a migrated user.
- **Credential transition:** mandatory reset; plaintext/export shortcuts are prohibited.
- **MFA transition:** mandatory re-enrollment for prior setup/enrolled users; global enforcement and
  on/off control remain explicit.
- **Session cutover:** invalidate all legacy sessions; no exchange or dual acceptance.
- **Token path:** exact shared client/API, memory-only storage, expiry/restart/revocation, and
  request-local propagation.
- **Service lifecycle:** exact owner, startup order, configuration, health, and deployment dependency.
- **Offline behavior:** reporting unavailable/fail closed; no cached-rights authorization or legacy
  fallback.
- **Cutover:** atomic activation document and exact mixed-version behavior.
- **Reconciliation:** accounts, stable IDs, all 32 `AccessPolicy` fields, bundle markers, MFA state,
  sessions, and audit evidence with exact `N` and `N=0` thresholds.
- **Rollback:** pre-activation legacy rollback only; post-activation roll forward.
- **Legacy retirement:** stopped/read-only evidence until a later reviewed destruction story.

## Required deliverables

- Accepted ADR with selected options and rejected alternatives.
- Legacy-to-shared account/role/right/MFA/session/token mapping table, including every exact shared
  `AccessPolicy` field.
- Login, authorization, MFA setup/disable/reset/recovery, cutover, offline, restart, revocation, and
  rollback sequence diagrams.
- Migration/reprovisioning, reconciliation, cutover, rollback, and operator/support runbooks.
- Versioned configuration contract and per-operation readiness states `Disabled`, `Unavailable`,
  `Ready`.
- Closed typed outcomes that distinguish reauthentication, stale, revoked, denied, and transient
  policy outage without contradictory token handling.
- Exact A0B source ownership, branch/worktree base, validation matrix, and rollback owner.

## Acceptance criteria

1. Shared Services is the only reporting authority after cutover; legacy fallback is technically
   impossible.
2. Every retained legacy account receives exactly one new shared ID; the bootstrap account is
   separate, is never rebound, and has one deterministic post-reconciliation disposition.
3. Every exact shared `AccessPolicy` field and both bundle marker bits have one explicit, testable
   disposition; no account, role, right, MFA enrollment, session, or audit field is silently
   broadened, fabricated, or dropped.
4. MFA on/off and authorized per-user lifecycle operations are preserved and tested.
5. Mixed-version, outage, restart, revocation, stale-session, unknown/conflicting state, `N=0`, and
   rollback behavior is exact and fail closed.
6. `Ready` is returned only for a currently allowed exact operation; post-activation lack of a valid
   session is `Unavailable`, never `Disabled`.
7. Actor/session values supplied to SHR-014C are stable, request-local, validated, and disclosure-
   safe.
8. No unresolved migration, bootstrap, stable-ID, cutover, offline, or rollback decision remains.

## Delivery

- Priority P0; fixed size 3 points.
- Planning artifacts only under this specification directory.
- Depends on published SHR-030/SHR-032 policy and Security approval; precedes DHS-025A0B.
- Agent-system base: exact published `8f99be2529ec7be4a17efb498719471a77fb82d8`.
- Branch: `feature/dhs-025a0a-authorization-migration-adr`.
- Isolated worktree: `C:\Git\Commercial\MrmETDSpec-dhs025a0a-authorization-adr`.
- Focused validation: every legacy/shared account, all 32 exact policy fields, bundle markers, MFA,
  session, token, and audit field has one disposition; all binary decisions are selected; readiness,
  outcomes, sequences, and runbooks agree; bootstrap/`N=0` reconciliation is exhaustive; sensitive
  values are absent; A0B handoff is complete; links, formatting, and `git diff --check` pass.
- Publication gate: Security/UX and Architecture closure plus independent Reviewer Integration
  acceptance of the exact ADR commit are required before fast-forward publication to agent-system
  `main`; A0B remains blocked until publication.
- ADR rollback: revert only the accepted planning commit. No DHS source, Services source, account,
  credential, MFA enrollment, session, token, gitlink, or runtime configuration is changed by A.
