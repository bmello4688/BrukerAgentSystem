# DHS-025A0A authorization migration decision package

This package freezes the DHS reporting-authorization migration from legacy DHS-GUI
`c060f9db8e2f476b5a50b15d6e9c23e39c24b804` to the published shared Services/UserManagement
contract `985f19bd059242597915d2a38fc728e8892df896`.

## Decision

- Transition: **ControlledReprovisioning**.
- Credentials: unique temporary credentials followed by mandatory user reset; no hash, secret, or
  plaintext migration.
- MFA: mandatory shared-service re-enrollment for legacy-enrolled users; legacy enrollment material
  is never copied. Global enforcement remains the authoritative
  `UserManagement:Mfa:EnforcementEnabled` switch and defaults off.
- Sessions: every legacy session is invalidated. There is no exchange and no dual acceptance.
- Authority: after activation, shared UserManagement is the only login, session-validation, and
  reporting-policy authority. The legacy combined report permission is not read by production
  authorization code.
- Rollback: rollback to legacy authority is permitted only before activation. After activation,
  recovery is roll-forward while reporting remains fail closed.

## Artifacts

1. [Acceptance story](story.md) — immutable scope, outcomes, criteria, and delivery gate.
2. [ADR](adr.md) — context, accepted decisions, rejected alternatives, configuration contract,
   invariants, and rollback boundary.
3. [Immutable evidence](evidence.md) — commit/path/line evidence and ownership/lifetime inventory.
4. [Mapping and reconciliation](mapping-and-reconciliation.md) — every account, role, all 32 exact
   shared policy fields, bundle markers, bootstrap/ID rule, MFA,
   credential, session, token, and audit disposition plus exact pass thresholds.
5. [Sequence diagrams](sequences.md) — login, authorization, MFA lifecycle, cutover, offline,
   restart, revocation, and rollback.
6. [Runbooks](runbooks.md) — reprovisioning, reconciliation, cutover, rollback, and support actions.
7. [Closed outcomes and guidance](outcomes-and-guidance.md) — exhaustive typed states and
   disclosure-safe default operator guidance.
8. [DHS-025A0B handoff](a0b-handoff.md) — exact repository base, ownership, tests, builds,
   activation gate, and rollback owner.

## Publication and implementation gate

The decision has no open binary choices. Publication still requires Security/UX and Architecture
closure plus independent Reviewer Integration acceptance of the exact planning commit. DHS-025A0B
must not start from this package until that publication gate passes. This planning package changes no
DHS or Services source, product gitlink, account, credential, MFA enrollment, session, token, or
runtime configuration.
