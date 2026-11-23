# Immutable authorization migration evidence

## Evidence method

All source assertions below are bound to immutable commits and use one-based line numbers. Reproduce a
citation without reading a mutable checkout with:

```powershell
git -C C:\Git\DHS-GUI show c060f9db8e2f476b5a50b15d6e9c23e39c24b804:<path>
git -C C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI\CommonLibraries\Services show 985f19bd059242597915d2a38fc728e8892df896:<path>
```

The evidence pass was read-only. The canonical DHS checkout had pre-existing unrelated gitlink
changes; no file or gitlink in it was modified. The Services checkout was clean at the cited commit.

## Legacy DHS ownership and lifetime inventory

All citations in this table use DHS-GUI
`c060f9db8e2f476b5a50b15d6e9c23e39c24b804`.

| Concern | Immutable evidence | Finding and disposition driver |
|---|---|---|
| Store | `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/appsettings.json:9-13`; `Applications/CompoundAnalyzer/UserManagement/UserManagement.Service.Host/appsettings.json:9-13` | SQLite `AspIdUsers.db`; the product host points into ProgramData. Preserve read-only, do not migrate the database. |
| Account/profile | `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Models/ApplicationUser.cs:7-43`; `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Models/RegisteredUser.cs:6-46` | ASP.NET Identity ID plus username, names, company/address/zip, phone/email, disabled/reset/MFA state and counter. Every field receives a mapping disposition. |
| Roles | `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Controllers/AccountController.cs:34-35`; `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Startup.cs:95-389` | Six selectable legacy roles and hard-coded policies. They do not match the shared three-base-role model. |
| Report right | `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Authorization/AccessPolicy.cs:27-31`; `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Startup.cs:109-112,157-160,205-208,254-257,303-306,352-356` | A single combined Boolean differs by legacy role. It cannot populate three shared rights. |
| Credentials/lockout | `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Startup.cs:39-66`; `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Controllers/AccountController.cs:117-168` | Legacy ASP.NET Identity hashes, 8-character policy, and inconsistent lockout handling are owned by the legacy store. No approved hash migration exists. |
| MFA enrollment | `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Authentication/TwoFactorAuthenticator.cs:15-17,27-48,68-88`; `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Models/ApplicationUser.cs:38-42` | Legacy uses HOTP/SHA-256, an Identity authenticator key, and a mutable counter. Shared Services uses protected TOTP plus replay/recovery state, so secret migration is not lossless. |
| MFA lifecycle | `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Controllers/AccountController.cs:262-328,330-408` | Legacy supports setup/verify, password-reset-triggered re-setup, and disable; it has no shared recovery-code lifecycle. Preserve the operator capabilities through shared APIs, not state copying. |
| Token | `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Services/TokenManagerService.cs:14-49,70-131`; `Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Startup.cs:78-93` | One cached RS256 JWT per username, one-day expiry, no issuer/audience validation, memory revocation, and a commented refresh endpoint. Invalidate all tokens. |
| Product token/session cache | `Applications/CompoundAnalyzer/UserManagement/UserManagement.Client/UserSecurityManager.cs:21-37,285-330,444-493` | DHS stores token and parsed username/role in one manager and caches `AccessPolicy`; there is no stable product `SessionId`. Replace, do not bridge. |
| Service lifecycle | `Applications/CompoundAnalyzer/DE-SCION/ViewModel/MainWindowContentViewModel.cs:67-83`; `Applications/CompoundAnalyzer/UserManagement/UserManagement.Service.Host/ServiceHost.cs:15-38` | The UI composition owns and starts an in-process legacy host; startup exceptions are swallowed by the host. A0B replaces this owner with shared host readiness. |
| Audit identity | `Applications/CompoundAnalyzer/UserManagement/UserManagement.Client/UserSecurityManager.cs:311-329`; `Applications/CompoundAnalyzer/DE-SCION/ViewModel/MainCommandPanelViewModel.cs:191-212` | Login/logout audit uses mutable username/role and has no stable user/session pair. It cannot satisfy SHR-014C. |
| Historic user-session report | `Applications/CompoundAnalyzer/ReportingSystem/EventReporter.Service/Processors/UserSummaryReportProcessor.cs:80-111` | Legacy pairs login/logout records by order and uses username as `UserID`; this is evidence only and is not a trusted session source. |

## Every legacy reporting authorization call site

These are the complete matches for `CanViewRecallAndPrintAllReports` in production DHS C# source at
the evidence commit. The two policy-definition matches above are configuration, not consumers.

| Call site | Lines | Current use | A0B replacement |
|---|---:|---|---|
| `Applications/CompoundAnalyzer/DE-SCION/ViewModel/MainCommandPanelViewModel.cs` | 164-180 | Report navigation projection | Shared `CanAccessReports`; projection only, followed by operation recheck. |
| `Applications/CompoundAnalyzer/DE-SCION/ViewModel/ReportsTab/ReportSelectorViewModel.cs` | 102-112 | Export eligibility combines legacy report bit and USB bit | Shared `CanExportReports` at mutation boundary; storage prerequisite remains separate. |
| same | 144-155 | Print eligibility | Shared `CanPrintReports` at spool boundary; printer readiness remains separate. |
| same | 248-270 | Generate/view eligibility | Shared `CanAccessReports` before source access. |

The immutable grep also found the policy definition at
`Applications/CompoundAnalyzer/UserManagement/UserManagement.Identity.Service/Authorization/AccessPolicy.cs:29`
and assignments in `Startup.cs`; neither may be referenced by A0B production reporting composition.

## Shared Services authority and lifetime inventory

All citations in this table use Services
`985f19bd059242597915d2a38fc728e8892df896`.

| Concern | Immutable evidence | Contract used by this ADR |
|---|---|---|
| Account/profile store | `UserManagement/UserManagement.Service/AppUser.cs:9-51`; `UserManagement/UserManagement.Service/AppDbContext.cs:10-12`; `UserManagement/UserManagement.Service/ServiceHost.cs:75-117` | Shared SQLite Identity store owns stable `AppUser.Id`, profile, disabled/reset state, rights mask, MFA state, and migrations. |
| Public account fields | `UserManagement/Protos/UserManagement.proto:143-159`; `UserManagement/UserManagement.Service/DtoMappers.cs:12-31` | Public DTO covers profile, role, disabled/reset, MFA flags, and bundles but not ID, password hash, or protected MFA material. |
| Roles and aliases | `UserManagement/UserManagement.Service/UserAccessPolicyResolver.cs:87-109,120-183` | Exactly one base role is required; Operator/Supervisor/Administrator aliases normalize; unknown/conflicting roles and unknown bits return an all-denied policy. |
| Report rights | `UserManagement/UserManagement.Service/UserRights.cs:23-27,47-54`; `UserManagement/UserManagement.Service/UserAccessPolicyResolver.cs:32-80,185-222` | Access bit 12 and distinct export/print bits 31/32. Supervisor and Administrator receive all three; bundles do not. |
| Proto compatibility | `UserManagement/Protos/UserManagement.proto:11-50` | Access, export, and print are fields 13, 31, and 32. |
| Login/MFA contract | `UserManagement/Protos/UserManagement.proto:71-109,170-214`; `UserManagement/UserManagement.Service/UserManagementService.cs:73-113,957-993` | Closed login results and authoritative MFA policy; enforcement off preserves enrollment and permits password-only success. |
| MFA storage and lifecycle | `UserManagement/UserManagement.Service/AppUser.cs:39-51`; `UserManagement/UserManagement.Service/TwoFactorAuthenticator.cs:14-58,61-99,146-242` | DPAPI-protected TOTP, replay time step, hashed recovery codes, acknowledgement, reset, and recovery invalidation/re-enrollment. |
| Global MFA switch | `UserManagement/UserManagement.Service/MfaPolicyOptions.cs:3-8`; `UserManagement/UserManagement.Service/appsettings.json:9-13`; `UserManagement/UserManagement.Service/UserManagementService.cs:102-113` | `UserManagement:Mfa:EnforcementEnabled`, default `false`, authoritative response explicitly says enrollment is preserved while off. |
| Authorized MFA reset | `UserManagement/Protos/UserManagement.proto:122-141,204-213`; `UserManagement/UserManagement.Service/UserManagementService.cs:435-478,878-890` | Admin-scoped password/MFA reset and disable/reset revoke active token and continuations. |
| Authentication continuations | `UserManagement/UserManagement.Service/AuthenticationContinuationStore.cs:7-13,34-65,68-103` | Reset/setup/verify/recovery acknowledgement continuations are memory-only and expire after five minutes. Restart invalidates them. |
| Token issue/lifetime | `UserManagement/UserManagement.Service/Authenticator.cs:62-109,158-208` | One service-cached token per username, one-day JWT expiry, service cache plus expiry required for validation. |
| Token revocation | `UserManagement/UserManagement.Service/Authenticator.cs:122-155,211-233`; `UserManagement/UserManagement.Service/UserManagementService.cs:901-909` | Token/user bidirectional memory mappings are removed on revocation. |
| Current-account validation | `UserManagement/UserManagement.Service/UserManagementService.cs:996-1009` | Service rejects absent/invalid cache binding, disabled user, and locked-out user on each protected call. |
| Policy RPC | `UserManagement/UserManagement.Service/UserManagementService.cs:162-182,1117-1121`; `UserManagement/UserManagement.Client/UserManagementClient.cs:159-169` | `GetAccessPolicy` validates token/current account and resolves current roles/mask. Null/failure is not authorization. |
| Managed-user mutation | `UserManagement/UserManagement.Service/UserManagementService.cs:184-239,297-351` | Authenticated create forces reset and empty MFA; role/bundle/disabled changes revoke tokens. |
| Password reset | `UserManagement/UserManagement.Service/UserManagementService.cs:389-478` | Continuation reset and admin reset are scoped; admin reset revokes token and optionally resets MFA. |
| Service lifecycle/readiness | `UserManagement/UserManagement.Service/ServiceHost.cs:20-65,108-133,172-223`; `UserManagement/UserManagement.Client/UserManagementClient.cs:51-75,591-615` | Local loopback HTTP/2, default port 7046, `Self` health service, explicit start/stop, configurable address. |
| Restart effect | `UserManagement/UserManagement.Service/ServiceHost.cs:53-60`; `UserManagement/UserManagement.Service/Authenticator.cs:14-37`; `UserManagement/UserManagement.Service/AuthenticationContinuationStore.cs:34-38` | Token and continuation stores are service singletons backed by process memory; a host restart invalidates both. |
| Actor/session gap | `UserManagement/Protos/UserManagement.proto:76-81,143-159`; `UserManagement/UserManagement.Client/UserManagementClient.cs:13-17` | Login returns token/continuation/recovery only and user DTO omits ID; there is no session-context RPC. The ADR therefore freezes validated-token-derived audit IDs without changing Services. |

## Policy and security evidence

Agent-system commit `8f99be2529ec7be4a17efb498719471a77fb82d8` contains the frozen SHR-030
contract and Security record used by this decision:

- `agent-os/specs/2026-11-18-shr-030-capability-matrix/README.md:29-39,47-61` freezes
  three roles, additive bundles, distinct report capabilities, and fail-closed rolling upgrades.
- `agent-os/specs/2026-11-18-shr-030-capability-matrix/security-confirmation-request.md:25-45`
  records Security GO with no conditions.
- `agent-os/specs/2026-11-20-shr-032-enable-report-authorization/story.md:31-48` freezes the
  implemented report/role contract; `:80-86` names Services base and additive rollback.

The published Services commit includes focused tests for token expiry/revocation, MFA continuation,
global/per-user MFA, role/bundle fail-closed policy, target scope, and gRPC workflows under
`UserManagement/UserManagement.Service.Tests/`.

## Evidence conclusion

Lossless database/credential/MFA/session migration is not established. Controlled reprovisioning is
the only selected path that avoids copying incompatible secrets or fabricating authority. Shared
Services has the required policy and MFA lifecycle, but products must supply request-local audit
identity from a just-validated service token and must treat restart/outage as reauthentication.
