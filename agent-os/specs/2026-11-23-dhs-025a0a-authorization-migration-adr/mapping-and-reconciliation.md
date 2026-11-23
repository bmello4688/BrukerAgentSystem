# Mapping and reconciliation contract

## Account and field mapping

Every row is mandatory for every retained legacy account. `Archive` means the legacy value remains in
the access-controlled read-only evidence package and is not used for authentication or authorization.

| Legacy field/state | Shared disposition | Reconciliation rule |
|---|---|---|
| Identity `Id` | Archive and map to newly generated `AppUser.Id` | Both IDs nonempty and unique; exactly one immutable mapping row. |
| `UserName` | Copy after shared validation | Ordinal-ignore-case uniqueness; normalized value must match; conflict blocks cutover. |
| `FirstName`, `LastName` | Copy | Exact Unicode scalar sequence after the shared API accepts it. |
| `PhoneNumber`, `Email` | Copy | Exact accepted values; invalid values block and require controlled correction recorded in the manifest. |
| `Company` | Copy | Exact accepted value. |
| `CompanyAddress` | Copy to `Address` | Exact accepted value. |
| `CompanyZipCode` | Copy to `ZipCode` | Exact accepted value. |
| `IsDisabled` | Reproduce disabled state after account creation | Exact Boolean; disabled accounts never receive usable temporary credentials. |
| `ResetPasswordOnNextLogin` | Force `ResetPasswordNextLogin=true` for every enabled account | Must be true until that user's first successful shared reset; legacy false never clears the mandate. |
| `LockoutEnabled`, `LockoutEnd`, `AccessFailedCount` | Do not copy; initialize shared lockout policy, with disabled state retained separately | Disposition recorded `ResetByPolicy`; no active legacy lockout silently becomes enabled. An authorized administrator must resolve each active lockout before cutover and record the decision. |
| Password hash/security/concurrency stamps | Do not copy | Disposition `MandatoryReset`; no secret/hash appears in manifest. |
| Authenticator key, HOTP counter, `TwoFactorEnabled`, `SetupTwoFactor` | Do not copy secret/counter; record prior state and set `ReEnrollmentRequired` where either legacy flag is true | Manifest contains only prior-state enums, never secret/counter. Required accounts must complete shared enrollment when enforcement is on. |
| Legacy recovery state | `NotAvailable` | Shared recovery codes are generated only by shared enrollment and acknowledged by the user. |
| Role assignment | Map using the table below | Exactly one shared base role plus zero, one, or two approved bundles. |
| Combined report permission | Ignore | Must not influence any shared role, bundle, right, or reconciliation expectation. |
| Legacy token/session | Invalidate | Accepted legacy session count after stop is zero. No value copied. |
| Historic audit records | Preserve read-only; do not rewrite actor/session | Count/hash archive; new events use shared actor/session identity only. |

Corrections required because a value fails shared validation are never silent: the manifest records the
field name, `CorrectedWithOwnerApproval`, approver role, UTC time, and old/new value hashes. It never
records secret values.

## Role, bundle, and reporting-right mapping

The shared matrix, not the legacy combined bit, governs report behavior. This explicitly changes some
legacy outcomes and requires owner acknowledgement in the reconciliation manifest.

| Legacy role | Shared base role | Bundles | Shared report access/export/print | Explicit policy effect |
|---|---|---|---|---|
| Screener | Operator | none | denied/denied/denied | No report authority. |
| Supervisor | Supervisor | none | allowed/allowed/allowed | Explicit SHR-030 broadening from legacy report-denied Supervisor. |
| Administrator | Administrator | none | allowed/allowed/allowed | Preserves report outcome through distinct rights. |
| QA | Operator | Lab/QA | denied/denied/denied | Explicit SHR-030 narrowing; bundle alone cannot report. |
| Service Technician | Operator | Service/Maintenance | denied/denied/denied | Explicit SHR-030 narrowing; bundle alone cannot report. |
| Super User | Administrator | Lab/QA and Service/Maintenance | allowed/allowed/allowed | Highest base role plus both compatibility bundles; no future/unknown right. |
| Any missing, duplicate, or unknown role | none | none | denied/denied/denied | Conflict; cutover blocked. |

No per-user raw report-right override is created. `CanAccessReports`, `CanExportReports`, and
`CanPrintReports` are derived only by Services `985f19b` from the valid base role.

## Complete right-field disposition

No legacy Boolean is copied into `RightsMask`. The shared base-role resolver and approved bundles
derive all effective rights. The counterpart column is traceability for behavior review, not a data
migration rule.

| Legacy `AccessPolicy` field | Shared counterpart/decision | A0B disposition |
|---|---|---|
| `CanStartupAndShutdown` | `CanShutdownReboot` | Derived from shared role; legacy value archived only. |
| `CanLogOnAndLogOff` | `CanLogonLogoff` | Derived from shared role; legacy value archived only. |
| `CanAnalyzeSamples` | `CanAnalyzeSamples` | Derived from shared role; legacy value archived only. |
| `CanPerformBasicSystemCleans` | `CanCleanSystem` | Derived from shared role/bundle; legacy value archived only. |
| `CanViewAndPrintAlarmStatus` | `CanAccessAlarms` | Derived from shared role; legacy value archived only. |
| `CanEnableAdjustAndDisableAuralAlarm` | `CanEditAudibleAlarms` | Derived from shared role; legacy value archived only. |
| `CanEnableDisablePrinterFunction` | `CanEnableDisablePrinting` | Derived from shared role; legacy value archived only. |
| `CanTransferDataToUsb` | `CanCopyDataToUsb` | Derived from shared role; not report-export authority. |
| `CanPerformAutoCalibrationsAndVerifications` | `CanAutoCalibrate` | Derived from shared role/bundle; legacy value archived only. |
| `CanPerformManualCalibrationsAndVerifications` | `CanManuallyCalibrate` | Derived from shared role/bundle; legacy value archived only. |
| `CanPerformMaintenance` | `CanDoMaintenance` | Derived from shared role/bundle; legacy value archived only. |
| `CanViewRecallAndPrintLiveAndHistoryDataAndSystemStatuses` | `CanAccessSamplingDataSystemStatus` | Derived from shared role/bundle; legacy value archived only. |
| `CanViewRecallAndPrintAllReports` | `CanAccessReports`, `CanExportReports`, `CanPrintReports` | **Ignored**; never grants or backfills any shared right. |
| `CanViewAndPrintDeviceConfiguration` | `CanAccessInstrumentConfiguration` | Derived from shared role/bundle; legacy value archived only. |
| `CanViewSystemDirectories` | `CanViewSystemFolders` | Derived from shared role/bundle; legacy value archived only. |
| `CanEditSSIStatement` | `CanEditSecurityFooter` | Derived from shared Administrator role only. |
| `CanInstallAndUpgradeSoftware` | `CanUpgradeSoftware` | Derived from shared role/bundle; legacy value archived only. |
| `CanPerformFullDataManagement` | `CanManageData` | Derived from shared role; legacy value archived only. |
| `CanExportHistoryFilesInTextFormat` | `CanExportSamplingData` | Derived from shared role; never satisfies report export. |
| `CanViewTheSubstanceLibrary` | `CanViewSubstanceLibrary` | Derived from shared role/bundle; legacy value archived only. |
| `CanAddOrModifyDetectionChannels` | No lossless field mapping | Legacy value archived; shared role/bundle policy governs substance-library editing. |
| `CanSwitchBetweenMultipleDetectionAlgorithms` | `CanSelectDetectionAlgorithm` | Derived from shared role/bundle; legacy value archived only. |
| `CanCreateAndDisableAdministrators` | `CanManageAdministrators` | Derived from shared role and target-scope rules. |
| `CanDisableSuperUsers` | `CanManageSuperusers` | Derived from shared Administrator role and safeguards. |
| `CanCreateScreenersAndSupervisors` | `CanManageScreeningStaff` | Derived from shared role; target scope may narrow legacy behavior. |
| `CanCreateQAUsers` | `CanManageTesters` plus bundle target rules | Derived from shared role/target scope; legacy value is not copied. |
| `CanCreateServiceTechnicians` | `CanManageServiceTechs` plus bundle target rules | Derived from shared role/target scope; legacy value is not copied. |
| `CanStandardizeASubstance` | `CanDoSubstanceTraining` | Derived from shared role/bundle; legacy value archived only. |
| `CanChangeUserLevel` | `CanEditUserRole` | Derived from shared Administrator role/target scope. |
| No legacy field | `HasLabQaTools` | Derived only from legacy QA role in the frozen role mapping. |
| No legacy field | `HasServiceMaintenanceTools` | Derived only from legacy Service Technician role; Super User receives both bundles explicitly. |
| No legacy field | `CanManageUsers` | Shared aggregate projection only; never persisted or migrated. |

Unknown future legacy or shared fields/bits have disposition `UnknownCodeOrVersion`, block cutover, and
grant nothing.

## MFA global and per-user lifecycle mapping

| Legacy state | Shared initial state | Enforcement off | Enforcement on |
|---|---|---|---|
| No enrollment and no setup request | Not enrolled | Password-only login permitted; state retained | Login returns setup continuation; setup, verify, recovery-code acknowledgement required before token. |
| Setup pending | Re-enrollment required | Password-only login permitted; requirement remains recorded | Setup continuation required before token. |
| Enrolled | Re-enrollment required; old secret archived only inside stopped legacy store | Password-only login permitted; no secret is destroyed or claimed migrated | New shared TOTP enrollment and recovery-code acknowledgement required before token. |
| Shared enrollment completed | Shared protected TOTP and acknowledged recovery codes | Enrollment remains stored; password-only login permitted | TOTP/recovery required. |
| Authorized disable/reset | Shared authenticator/recovery state cleared; token and continuations revoked; setup required | Password-only access follows global-off policy while setup-required state persists | Re-enrollment required before token. |
| Recovery code used | Entire prior authenticator and recovery set invalidated | Not applicable until next login flow | Re-enrollment required; old token revoked. |

Changing global enforcement is a controlled configuration change followed by shared service restart,
health verification, and DHS reauthentication. Turning enforcement off never deletes enrollment.

## Session/token/audit mapping

| Legacy item | Shared/A0B item | Disposition |
|---|---|---|
| Cached legacy JWT | None | Revoke by stopping host and removing launchability; never exchange. |
| Parsed username/role globals | None | Delete from authorization/audit composition. Display name may be a separate non-authorizing projection. |
| Cached legacy `AccessPolicy` | Request-local shared `AccessPolicy` | No migration; each protected operation re-fetches. |
| No stable legacy session ID | Token-derived `SessionId` after shared validation | New identity; never fabricated for historic records. |
| Legacy username audit actor | Shared stable Identity `ActorUserId` | New events only; historic audit is not rewritten. |
| Legacy login/logout records | Preserved archive | No ordinal pairing or backfill into new stable sessions. |
| Legacy token expiry/refresh | Shared one-day/no-refresh contract | Reauthenticate at expiry/restart/revocation. |

## SHR-014C audit-field disposition

| Trusted-envelope field | Source after cutover | Disposition |
|---|---|---|
| Machine ID | Existing approved trusted DHS machine-identity source | Capture per invocation; require exact report-source scope match. |
| Occurrence time | SHR-014C trusted time source | Capture per audit phase; never accept UI-supplied time. |
| Source component | Exact A0B assembly identity | Constant reviewed identity, request-local envelope value. |
| Source version | Exact A0B assembly/commit-derived version | Must match activation `dhsCommit`; mismatch fails closed. |
| Actor user ID | Single normalized name-identifier from the just service-validated token | Present for authenticated reporting operations; never username/display name. |
| Session ID | Namespaced SHA-256 derivation of the same validated token | Present for authenticated reporting operations; token bytes are never emitted. |
| Configuration revision | SHA-256 of canonical v1 activation document | Required and exact; mismatch fails closed. |
| Correlation/operation identity | SHR-014C invocation handle and stable operation catalog | Newly generated/selected per invocation; never copied from legacy events. |
| Safe operation facts | Product request/result mapper after disclosure validation | Identifier-free and operation-specific; no credential/token/identity leakage. |

Historic audit fields retain their original representation and are not fabricated into this envelope.

## Reconciliation manifest

The reconciliation tool emits canonical JSON and a detached SHA-256 recorded by the activation
document. It contains no credential, token, TOTP secret/counter, recovery code/hash, or operator-facing
identity detail. Detailed identity mapping is access-controlled migration evidence, not default UI.

Required aggregate fields:

- legacy evidence commit and database SHA-256;
- Services commit and empty/new-store baseline SHA-256;
- migration batch identifier and UTC window;
- total/active/disabled account counts on each side;
- counts by legacy role, shared role, and bundle set;
- count for every field disposition and correction;
- credential reset-required/completed counts;
- MFA prior-state and shared-state counts;
- unique legacy/shared ID mapping count;
- current shared policy decisions for the three report capabilities for every account;
- legacy/shared accepted-session counts;
- audit archive count/hash and migration/cutover audit receipt IDs in the restricted evidence annex;
- pass/fail for each gate below.

## Exact cutover thresholds

Let `N` be every non-deleted row in the frozen legacy user store, including disabled users. Cutover
passes only when all statements are true:

1. Legacy inventory count is `N`; shared reprovisioned count is `N`; mapping count is `N`.
2. There are `N` unique legacy IDs, `N` unique shared IDs, and `N` unique normalized usernames.
3. All required profile fields have an explicit `Copied`, `CorrectedWithOwnerApproval`, or
   `ArchivedNotCopied` disposition; missing dispositions are zero.
4. Role mappings match the table for `N/N`; unknown, missing, or conflicting roles are zero.
5. Shared effective report access/export/print matches the approved role matrix for `3N/3N` checks;
   any grant sourced from the legacy combined bit is zero.
6. Enabled accounts with uncompleted reset have `ResetPasswordNextLogin=true`; copied hashes and
   plaintext/exported credentials are zero.
7. Every legacy setup/enrolled account has disposition `ReEnrollmentRequired` or a completed shared
   enrollment. Copied legacy MFA secrets/counters are zero.
8. When enforcement is on, every enabled account has completed shared enrollment and recovery-code
   acknowledgement before activation. When off, incomplete re-enrollment is allowed only with the
   explicit recorded disposition and preserved setup-required state.
9. Legacy accepted tokens/sessions are zero after stop. Shared accepted tokens/sessions are zero at
   activation; all users authenticate after restart.
10. Account/profile/role/MFA aggregate counts and hashes match on two consecutive read-only runs
    separated by at least one full service restart, with zero drift.
11. Migration and cutover audit attempts and terminal receipts are complete and hash-bound; missing,
    duplicate, contradictory, or ambiguous receipts are zero.
12. Corrected-field owner acknowledgements, explicit Supervisor broadening acknowledgements, and
    QA/Service narrowing acknowledgements are present for every affected account class.
13. Unknown schema/version/code, unsupported Services commit, malformed activation data, and
    disclosure-scan findings are zero.

Any failed threshold leaves the activation document absent and readiness `Disabled`. A failure after
activation yields `Unavailable`; it never re-enables legacy authority.
