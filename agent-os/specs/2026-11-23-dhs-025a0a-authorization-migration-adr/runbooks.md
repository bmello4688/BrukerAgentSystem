# Migration, cutover, rollback, and support runbooks

## Roles and separation of duties

| Role | Responsibility |
|---|---|
| Project owner | Approves the maintenance window, corrected account data, governed role-policy effects, activation, and any pre-activation rollback. |
| Migration operator | Runs inventory/reprovisioning/reconciliation locally; uses host-owned masked credential entry and never records secrets in command lines, logs, manifests, or chat. |
| Coordinator Architect | Owns exact commits, deployment ordering, activation replacement, and rollback execution. |
| Reviewer Integration | Independently verifies manifests, commands, disclosure scans, protected-repository state, and final readiness. |
| Security/UX reviewer | Verifies fail-closed/disclosure behavior, MFA lifecycle, and safe accessible guidance. |

No one uses default operator UI or a transcript to collect, display, or transport credentials, TOTP
setup material, recovery codes, or access tokens.

## Runbook A: freeze and inventory

1. Verify A0B is the exact independently accepted commit and its Services gitlink is exactly
   `985f19bd059242597915d2a38fc728e8892df896`.
2. Confirm the activation document is absent. If present, stop: the post-activation runbook applies.
3. Start the maintenance window. Prevent interactive login, stop DHS, stop the legacy identity host,
   and confirm no legacy process owns its endpoint or database.
4. Create an access-controlled, read-only backup of the legacy user database and legacy audit data.
   Compute SHA-256 locally. Do not copy data off the approved machine.
5. Inventory every non-deleted account and every field in
   [mapping-and-reconciliation.md](mapping-and-reconciliation.md). Record only hashes/enums in the
   aggregate manifest; keep detailed identity mapping in the restricted evidence annex.
6. Record all active legacy lockouts with disposition `ResetByPolicy`. Do not use lockout state to
   alter legacy `IsDisabled`; that Boolean is copied exactly.
7. Verify the shared store baseline contains only the expected seeded bootstrap account. Any other
   account, duplicate normalized username, unknown role, or unexpected schema blocks migration.
8. Record legacy and shared store hashes and the exact commits. Leave readiness `Disabled`.

## Runbook B: controlled reprovisioning

1. Start shared UserManagement `985f19b` only and wait for `Self=SERVING`.
2. Authenticate the approved bootstrap administrator through host-owned masked input. Never place the
   credential or returned token in a command argument, environment variable, manifest, or log.
3. For each retained legacy account in stable legacy-ID order:
   1. map role/bundles using the frozen table;
   2. validate/copy profile fields;
   3. reject an ordinal-ignore-case collision with the seeded bootstrap or another retained account;
      otherwise create a distinct account through `CreateManagedUser` with a newly generated shared
      ID and a unique temporary credential entered and delivered through the approved masked/out-of-
      band process;
   4. force `ResetPasswordNextLogin=true`;
   5. apply the exact disabled state through authenticated managed-user update;
   6. record the one-to-one legacy/new-shared ID mapping by a service-stopped read-only database
      reconciliation; bootstrap is never a mapping target;
   7. record legacy MFA state as `None`, `SetupPending`, or `Enrolled`; never read/export the secret
      or counter into the migration artifact;
   8. verify effective current shared policy for all three report rights.
4. Disabled accounts receive no credential handoff. Their shared account remains disabled.
5. For enabled accounts, deliver the temporary credential only through the approved out-of-band
   mechanism. The first shared login must complete password reset.
6. If global MFA enforcement is on, require setup, verification, one-time recovery-code presentation,
   and acknowledgement before the account can obtain a token. If it is off, preserve the
   re-enrollment-required disposition for later enforcement.
7. After all `N` accounts are staged, require `N >= 1` and at least one enabled mapped Administrator.
   That mapped Administrator completes mandatory credential reset and any enforced MFA enrollment,
   authenticates, disables bootstrap through the shared managed-user workflow, and verifies the
   bootstrap token/continuations are revoked. Record `BootstrapDisabledNotMapped` separately from
   all `N` mappings.
8. On any per-account failure, stop; do not continue past the first unrecorded partial state. Re-run
   idempotently by username and mapping state after review.

## Runbook C: reconciliation

1. Stop shared UserManagement so the store is stable and compute its hash.
2. Run the read-only reconciler against both frozen stores and the restricted mapping annex.
3. Validate all 15 exact thresholds in
   [mapping-and-reconciliation.md](mapping-and-reconciliation.md). There is no tolerance below 100%
   and no allowed conflict count above zero.
4. Start shared UserManagement; wait for `Self=SERVING`; confirm no pre-cutover token is accepted.
5. Stop/start shared UserManagement once more and run the read-only reconciler again.
6. Require identical counts and mapping/policy results on both runs. Hash changes caused solely by
   expected service metadata must be separately enumerated; unexplained drift blocks cutover.
7. Validate the global MFA response is authoritative and matches the owner-selected switch value.
8. Produce canonical account and reconciliation manifests, compute SHA-256, and have Reviewer
   Integration verify them independently.
9. Keep the activation document absent until the project owner accepts the exact hashes.

## Runbook D: cutover

1. Confirm the maintenance window remains active, all sessions are ended, all thresholds passed, and
   Reviewer Integration accepted the exact A0B commit and manifests.
2. Stop all DHS and UserManagement processes.
3. Transactionally deploy the exact A0B package. The package must replace the old executable, remove
   the legacy identity host/client from production composition, and leave the old package/store only
   in the access-controlled rollback evidence location. An `N-1` executable must not remain
   launchable.
4. Confirm the deployed Services gitlink/content is exactly `985f19b`; confirm no Services source
   diff exists.
5. Generate the canonical v1 activation document with the exact DHS commit, manifest hashes, Services
   commit, and UTC activation time. Compute its revision hash.
6. Write beside the final location, flush, and atomically replace the final activation document. If
   atomic replacement fails, remove the temporary file and execute pre-activation rollback; never
   accept a partial document.
7. Start shared UserManagement and wait for `Self=SERVING`. Confirm authoritative MFA policy.
8. Start DHS. Before login it must return per-operation `Unavailable`/
   `ReauthenticationRequired`; it must not return `Disabled` or start the legacy host.
9. Execute smoke checks with governed test accounts for Operator, Supervisor, Administrator,
   QA-bundle Operator, and Service-bundle Operator:
   - Operator/bundle-only report operations deny;
   - Supervisor/Administrator access, export, and print rights allow at the policy seam;
   - only Administrator has SSI edit authority;
   - each operation rechecks the service;
   - audit context uses distinct stable actor/session IDs without exposing values in UI/logs.
10. Revoke one test session, restart the service once, and simulate service unavailable. Confirm
    explicit revocation returns `RevokedSession`, confirmed restart returns
    `ReauthenticationRequired`, and transient outage returns `PolicyUnavailable` while retaining the
    token only for an explicit post-health policy retry. All remove protected content and permit no
    fallback.
11. Project owner closes the window only after Reviewer Integration records all outcomes.

## Runbook E: pre-activation rollback

This runbook is legal only while the activation document has never existed.

1. Project owner authorizes rollback; Coordinator Architect records the reason and exact state.
2. Stop DHS and shared UserManagement.
3. Preserve migration manifests, evidence hashes, and the shared store. Do not delete accounts or
   rewrite the legacy store.
4. Through an authenticated administrative workflow, disable all newly staged mapped shared
   accounts. Keep bootstrap disabled unless the separately reviewed legacy rollback procedure needs
   it for a later migration attempt; any re-enable requires a governed receipt. Do not expose
   credentials or tokens.
5. Restore the previously reviewed DHS package and its legacy host launchability from the local
   controlled rollback artifact.
6. Verify the legacy store hash equals the frozen pre-migration hash before starting. Any mismatch
   blocks rollback and requires support.
7. Start prior DHS, validate its prior login/reporting behavior, and keep the shared staged accounts
   disabled.
8. Record rollback completion. A later attempt starts again at Runbook A with new manifest hashes.

## Runbook F: post-activation incident/recovery

After the activation document exists, legacy-authority rollback is prohibited.

1. Set reporting `Unavailable`, remove protected content, and keep unrelated workflows available.
2. Preserve the activation document, shared store, all post-cutover account/MFA changes, and audit
   evidence. Do not restore or write the legacy store.
3. Diagnose through restricted logs/evidence; show only the closed safe guidance to operators.
4. Deploy a reviewed A0B-compatible repair that retains shared UserManagement as authority. A prior
   DHS UI/application build may be used only if it consumes the same shared authority and recognizes
   the exact activation contract; `N-1` legacy-authority builds are ineligible.
5. Restart shared UserManagement, require reauthentication, reconcile 100%, and repeat cutover smoke
   checks before returning `Ready`.

## Runbook G: operator/support actions by outcome

| Outcome | Operator action | Support action |
|---|---|---|
| Invalid input | Correct highlighted input. | None unless repeatable with valid input. |
| Reauthentication/stale/revoked | Sign in again. | Verify current account state and revocation without disclosing identity/session in operator text. |
| Denied | Do not retry. | Authorized administrator reviews governed role/bundle; never set the legacy combined bit. |
| Policy unavailable | Retry when service is ready. | Verify host health, exact commits, configuration and restart behavior. |
| Migration incomplete/conflict/unknown/support required | Contact support. | Keep reporting unavailable, use restricted evidence, reconcile or roll forward. |
| Canceled | No action. | Confirm terminal audit handling if an accepted start occurred. |

For `PolicyUnavailable`, the adapter retains the opaque token in private memory but clears policy,
request context, and protected content. The operator's explicit retry after health recovery performs
a new `GetAccessPolicy`. A confirmed restart, explicit revocation, local stale generation, expiry, or
generic rejection follows its distinct reauthentication outcome and clears the token. No background
retry performs a protected operation.

## Legacy retirement

A0B does not delete the legacy database, host source, or historic audit. They remain read-only,
non-launchable, access-controlled evidence until a separately approved retirement story defines
retention and destruction. They never participate in post-activation authentication or authorization.
