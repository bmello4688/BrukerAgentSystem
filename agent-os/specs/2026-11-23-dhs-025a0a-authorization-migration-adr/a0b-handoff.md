# DHS-025A0B exact implementation handoff

## Dependency gate

A0B remains blocked until Security/UX, Architecture, and independent Reviewer Integration accept and
publish the exact A0A planning commit. No implementation may substitute a different migration path,
Services commit, readiness state, role mapping, token/session derivation, threshold, or rollback
boundary without a reviewed ADR supersession.

## Exact source-control assignment

| Item | Frozen value |
|---|---|
| Repository | `C:\Git\DHS-GUI` in a clean isolated worktree |
| Base | `c060f9db8e2f476b5a50b15d6e9c23e39c24b804` |
| Branch | `feature/dhs-025a0b-report-authorization` |
| Worktree | `C:\Git\DHS-GUI-dhs025a0b-report-authorization` |
| Services baseline/gitlink target | `985f19bd059242597915d2a38fc728e8892df896` |
| Common.Reports gitlink target | `664a09a9427cf2ade7fc155a1844c6505890c2bc` (published SHR-014C trusted-envelope producers) |
| Integration policy | Commit only A0B-owned DHS files and the two named Services/Reports gitlinks. No merge or push before independent review. |

The canonical DHS checkout is not an implementation worktree; it had unrelated local gitlink changes
during A0A evidence collection.

## Source ownership

### Primary owned paths

- `CommonLibraries/Services` — gitlink advancement only from `14bd2025255d535ea1353aa4210679a535e781fe`
  to exact `985f19bd059242597915d2a38fc728e8892df896`; no Services child source edits.
- `CommonLibraries/Reports` — gitlink advancement only from
  `fd705711aa17ab23e34efa1bcf52422ee50868fd` to exact
  `664a09a9427cf2ade7fc155a1844c6505890c2bc`; no Reports child source edits.
- New `Applications/CompoundAnalyzer/UserManagement/UserManagement.SharedAuthorization/` — shared
  host/client owner, in-memory session, token-derived audit identity, per-operation authorization,
  readiness evaluator, activation parser, migration/reconciliation ports, typed outcomes, and safe
  guidance codes.
- New `Applications/CompoundAnalyzer/Tests/UserManagement.SharedAuthorization.Tests/` — all focused
  A0B tests and fixtures.
- `Applications/CompoundAnalyzer/DE-SCION/DE-SCION.csproj` — replace legacy production references
  with the shared adapter and exact Services client/service references.
- `Applications/CompoundAnalyzer/DE-SCION/ViewModel/MainWindowContentViewModel.cs` — replace legacy
  host ownership and enforce startup/health/disposal order.
- `Applications/CompoundAnalyzer/DE-SCION/ViewModel/LoginViewModel.cs` and the existing credential/MFA
  dialog view-model/service files — consume closed shared login/MFA continuation flows.
- `Applications/CompoundAnalyzer/DE-SCION/ViewModel/MainCommandPanelViewModel.cs` — shared report
  navigation projection and local-context clearing on logout.
- `Applications/CompoundAnalyzer/DE-SCION/ViewModel/ReportsTab/ReportSelectorViewModel.cs` — exact
  access/export/print rechecks at protected boundaries; no legacy permission read.
- `Applications/CompoundAnalyzer/DE-SCION/appsettings.json` — non-secret versioned authorization mode,
  activation-document location, service port/address, and global MFA switch.
- `Applications/CompoundAnalyzer/CompoundAnalyzer.sln` — add the adapter and test projects only.

### Legacy paths that may be changed only to remove production composition

- `Applications/CompoundAnalyzer/UserManagement/UserManagement.Client/`
- `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/`
- `Applications/CompoundAnalyzer/UserManagement/UserManagement.Service.Host/`

They may be excluded from the production project graph or wrapped behind a build-time
`LegacyAuthorizationEvidenceOnly` boundary. Do not rewrite the legacy database/schema, credentials,
MFA state, policy values, or historic audit. Do not delete the source in A0B.

### Protected/do-not-touch

- Services child source below `CommonLibraries/Services/`.
- Common.Reports child source, Common.DataService, Algorithms, reporting source/calculation code,
  FDRS schemas/providers, WPF report-page layout, export destinations/file writes, printer adapters,
  hardware, simulators, instrument behavior, package props, and unrelated gitlinks.
- Production accounts, credentials, MFA state, sessions, tokens, and runtime activation during source
  implementation or automated tests. Tests use isolated temporary stores and synthetic values.

If implementation requires a protected path, stop and return to Coordinator/ADR review; do not expand
scope implicitly.

## Required implementation contract

1. Implement `DhsAuthorizationReadiness` as exactly `Disabled`, `Unavailable`, `Ready` and the closed
   outcomes in [outcomes-and-guidance.md](outcomes-and-guidance.md).
2. Parse/canonicalize the v1 activation document strictly and compute its revision; no partial/default
   acceptance.
3. Own exactly one shared `ServiceHost`; start before client, wait for `Self=SERVING`, dispose client
   before host stop. Do not start legacy host.
4. Keep tokens only in the private session object; implement atomic session generation so concurrent
   requests cannot reuse stale actor/session/policy.
5. After a successful request-local `GetAccessPolicy`, require exactly one valid name-identifier claim
   and derive the session ID exactly as the ADR specifies. Never log either value or the token.
6. Recheck the exact capability immediately before every protected source/mutation/spool boundary.
   Never authorize from UI state, role name, cached policy, legacy permission, or USB/printer state.
7. Construct an immutable SHR-014C trusted envelope per invocation and validate machine/scope/source/
   version/revision. No ambient/static identity.
8. On logout/restart/revocation/outage/conflict, atomically clear token, context, cached projection,
   and protected content. No background retry may execute a protected operation without a new check.
9. Implement the migration/reconciliation tooling as local, explicit maintenance-mode commands with
   host-owned masked credential entry and canonical manifests. Never accept credentials from command
   arguments or emit sensitive values.
10. Make production dependency tests prove the legacy report bit/client/host cannot reach report
    authorization composition.

## Validation matrix

### Focused automated behavior

- Account mapping: every field disposition, all six role mappings, corrections, disabled accounts,
  username collision, unknown/duplicate role, seeded bootstrap binding, `N=0`, `N=1`, and `N+1`.
- Credentials: mandatory reset for all enabled accounts; no legacy hash/secret serialization; masked
  input and disclosure fixtures.
- MFA: enforcement off/on; prior none/setup/enrolled; setup/verify/recovery acknowledgement;
  authorized disable/reset/recovery; enrollment preservation while off; service restart during every
  continuation; no secret/counter copy.
- Policy: all three base roles and four bundle sets; exact access/export/print fields; Administrator
  SSI only; unknown bits/roles/conflicts/bundle-only fail closed.
- Operation boundaries: surface, three generation operations, completed view, export, print, print
  settings, and SSI edit each call the service; source/mutation is not called on denial/failure.
- Session/token: success, 24-hour expiry seam, no refresh, logout, stale generation, explicit revoke,
  role/bundle/disable/password/MFA revocation, service restart, parallel requests, cancellation, and
  request-local actor/session isolation.
- Readiness/config: absent document, malformed/duplicate keys, wrong hash/commit/mode/version,
  incomplete manifest, health transition, authoritative/non-authoritative MFA response, atomic
  replacement interruption, and exact `Disabled`/`Unavailable`/`Ready` transitions.
- Mixed version: N-1 package not launchable after activation; wrong DHS or Services commit is
  `Unavailable`; no legacy fallback under any injected fault.
- Rollback: pre-activation restore; post-activation roll-forward only; post-cutover shared changes are
  preserved.
- Audit: stable request-local actor/session, machine/scope match, accepted/terminal ordering,
  rejection before source access, cancellation shielding, restart/revocation, and no sensitive
  values in default text/log fixtures.

### Required commands

Run from the clean A0B DHS worktree and record exact output/counts:

```powershell
git status --short --branch
git submodule status CommonLibraries/Services CommonLibraries/Reports
dotnet test .\Applications\CompoundAnalyzer\Tests\UserManagement.SharedAuthorization.Tests\UserManagement.SharedAuthorization.Tests.csproj -c Release
dotnet test .\CommonLibraries\Services\UserManagement\UserManagement.Service.Tests\UserManagement.Service.Tests.csproj -c Release
dotnet build .\CommonLibraries\Services\UserManagement\UserManagement.Client\UserManagement.Client.csproj -c Release
dotnet build .\CommonLibraries\Services\UserManagement\UserManagement.Service\UserManagement.Service.csproj -c Release
dotnet build .\Applications\CompoundAnalyzer\CompoundAnalyzer.sln -c Release
git diff --check
git status --short
```

Also run deterministic scans that fail on:

- a production reference from report authorization to `CanViewRecallAndPrintAllReports`, legacy
  `UserSecurityManager`, or legacy `UserManagement.Service.Host`;
- a token/credential/MFA secret/recovery value in persistence, logs, snapshots, command arguments, or
  operator text;
- Services/Reports child-source changes or any protected/unassigned gitlink/source change;
- unknown/unhandled outcome/readiness/contract values;
- a report source/mutation occurring without a same-invocation authoritative policy success.

### Manual/rehearsal validation

Use isolated synthetic stores, never production data:

1. full reprovision/reconcile/cutover rehearsal at `N`, `N+1`, disabled, conflict, and interrupted
   account volumes;
2. two consecutive reconciliation runs separated by service restart;
3. global MFA off/on across restart with enrollment retained;
4. login, setup, disable, reset, recovery, logout, expiry, revoke, offline, restart, and mixed-version
   sequences;
5. accessibility review of persistent safe guidance and protected-content removal;
6. pre-activation rollback and post-activation roll-forward incident rehearsal;
7. detached clean-worktree validation at the exact A0B commit.

No real hardware validation is required; A0B changes no hardware or instrument behavior.

## Activation and publication gate

A0B is review-ready only when:

- all focused and solution builds/tests pass;
- Services child source is clean at exact `985f19b`, Reports child source is clean at exact `664a09a`,
  and their parent gitlinks are the only child-repository changes;
- every mapping/reconciliation threshold and fault fixture passes;
- Security/UX validates guidance/disclosure/MFA behavior;
- Reviewer Integration accepts the exact clean commit;
- no production runtime/account cutover has occurred during development.

## Rollback owner and source rollback

- Rollback execution owner: **Coordinator Architect**.
- Activation/rollback authorization: **Project owner**.
- Independent verification: **Reviewer Integration**.
- Before runtime activation: revert only the accepted A0B DHS commit and restore the prior Services
  gitlink/package; no production data was changed by source implementation.
- During a migration rehearsal before activation: follow Runbook E and preserve/disable staged shared
  accounts.
- After runtime activation: do not restore legacy authority or its combined permission. Preserve all
  shared account/MFA/session evidence and roll forward with a reviewed shared-authority-compatible
  repair while reporting remains `Unavailable`.
