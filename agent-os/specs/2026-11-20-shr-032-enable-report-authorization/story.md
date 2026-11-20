# SHR-032 - Enable the Approved Report Authorization Policy

## State

**Development-ready as of 2026-11-20.**

- Owner matrix approval: recorded in SHR-030.
- Security GO and controlled SSI revision verification: recorded at agent-system commit `aeb65e98f713a53b0bc8f3caf2bf30e7445bb01a`.
- Authoritative matrix: SHR-030 artifacts published through `ff84aed2b0f5eb238c2d12ab1444b5f264a66344`.
- User Management baseline: Services `14bd2025255d535ea1353aa4210679a535e781fe`.

## Goal

Implement the accepted SHR-030 capability matrix in the authoritative User Management service so report generation/viewing, export, print, print settings, SSI editing, and managed-user target scope are additive, version-compatible, and fail closed.

## Priority and size

- Priority: P0; blocks DHS-025A/TQ-026A and product report enablement.
- Size: 5 points after final contract review.

## Exact ownership

- Repository: standalone Services child repository.
- Primary projects:
  - `UserManagement/UserManagement.Service`
  - `UserManagement/UserManagement.Client`
  - `UserManagement/UserManagement.Service.Tests`
  - `UserManagement/Protos/UserManagement.proto`
- Do not change TripleQuadUI/DHS product source, Common.Reports, Common.DataService, UI routes, report values, audit payloads, hardware, simulator behavior, or parent gitlinks in this story.

## Frozen contract

1. Preserve every existing `UserRights` numeric value and AccessPolicy proto field 1-30.
2. Add `CanExportReports = 1UL << 31` and `CanPrintReports = 1UL << 32`.
3. Add AccessPolicy fields 31 and 32 for export and print; old clients ignore these fields and therefore deny the new operations.
4. Operator receives no report generation/view/export/print rights.
5. Supervisor and Administrator receive `CanAccessReports`, `CanExportReports`, and `CanPrintReports`.
6. Supervisor and Administrator retain `CanEnableDisablePrinting`; only Administrator receives `CanEditSecurityFooter`.
7. Administrator is an explicit named capability set. Future/unknown bits are never granted automatically.
8. Exactly one recognized base role is required. Conflicting roles, unknown roles, invalid masks, bundle-only identities, and unsupported inputs fail closed.
9. QA and Service bundles are additive only after a valid base role and never independently grant report access/export/print.
10. Supervisor managed-user scope is Operator-only and may not change target role or specialist-bundle state. Administrator scope covers the three selectable roles while preserving self-access and final-active-Administrator safeguards.
11. A successful AccessPolicy response expresses per-capability Allowed/Denied decisions. Existing authentication/authorization RPC failures remain typed and must not be converted into an all-false success response; product adapters map them to `ReauthenticationRequired` or `PolicyUnavailable`.
12. Report generation is authorized before source access. Product adapters must recheck export/print immediately before their irreversible boundary; cached UI state is never authoritative.

## Acceptance criteria

1. Resolver output matches all applicable SHR-030 role/bundle decisions and target-scope fixtures.
2. Existing aliases normalize to exactly one base role; conflicting recognized roles fail closed rather than using precedence.
3. Existing users migrate without rewriting stored masks; base-role grants are derived authoritatively and bundle markers retain their published ordinals.
4. Client and service generated contracts expose export/print fields while older serialized messages remain readable.
5. Unknown future fields/bits do not grant access in old or new consumers.
6. Report capabilities are never logged with tokens, usernames, machine identifiers, policy payloads, SSI text, or rights masks.
7. Existing non-report authorization behavior remains compatible except for the separately approved fail-closed role/bundle corrections.
8. Exhaustive tests cover three base roles, four bundle sets, report access/export/print, aliases, conflicting roles, bundle-only input, unknown bits, rolling upgrade, target scope, self-access, and final-active-Administrator protection.
9. No product source or gitlink changes occur.

## Validation

- Focused Release tests for `UserManagement.Service.Tests`.
- Release builds for User Management service, client, and tests.
- Proto compatibility/field-number scan and `UserRights` ordinal scan.
- SHR-030 fixture parity and unknown-input fail-closed tests.
- Formatting, `git diff --check`, dependency/vulnerability/disclosure scans.
- Exact-commit detached worktree validation.
- Independent Reviewer Integration before merge or remote publication.

## Integration and rollback

- Feature branch: `feature/shr-032-report-authorization` from Services `master` at `14bd2025255d535ea1353aa4210679a535e781fe`.
- Rollback is additive: revert the new rights/proto fields and resolver policy before product consumers adopt them. Existing field numbers and rights ordinals must never be renumbered.
- Production use remains fail closed until DHS/TQ adapters consume and recheck the authoritative policy in their separately reviewed stories.
