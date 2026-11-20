# SHR-030 - Freeze the Contractual Capability Matrix

## State

**Published and independently accepted as of 2026-11-20. Security confirmation pending.**

- Owned path: `agent-os/specs/2026-11-18-shr-030-capability-matrix/`
- Execution is confined to this policy/evidence artifact directory in the existing agent-system checkout.

Feature Engineering produced the deterministic v1 catalog, exhaustive canonical CSV/JSON matrix,
JSON schema, fail-closed fixtures, cross-product parity manifests, documentation, generator, and
validator. No User Management, product, Common.Reports, UI, route, or gitlink source changed.

SHR-030 publishes policy evidence and machine-readable fixtures; it changes no User Management or product source. Owner attestation for the v1 matrix is recorded below. The accepted artifacts are published through agent-system commit `ff84aed2b0f5eb238c2d12ab1444b5f264a66344`. Security confirmation remains a production-release gate, and SHR-032 remains blocked until that confirmation is recorded against the exact artifact hashes in `security-confirmation-request.md`.

## Priority and size

- Priority: P0; blocks SHR-032 and DHS/TQ reporting integration.
- Size: 3 points for the contract/evidence artifact.

## Stakeholder goal

Create one authoritative, reviewable mapping from governed access policy to stable operation identities, capabilities, typed policy states, safe guidance, and accessible product presentation so DHS and TripleQuadUI cannot diverge.

## Verified baseline

- User Management is the authoritative authentication and authorization service.
- `CanAccessReports = 1UL << 12` and proto field 13 already exist, but the resolver deliberately removes report access.
- No dedicated report-export or report-print capabilities exist.
- Administrator currently uses an unsafe future-bit mask; it must become an explicit known-capability grant.
- Conflicting base roles currently use precedence rather than failing closed.
- Legacy QA/Service inputs can create effective access without a selected base role; bundle-only access must fail closed.
- Common.Reports remains token-, role-, username-, and rights-mask unaware.

## Required operation identities

The catalog must contain distinct stable IDs even when multiple operations share a capability:

1. Enter/view report surface.
2. Generate Equipment report.
3. Generate Event report.
4. Generate User report.
5. View a completed report.
6. Export report.
7. Print report.
8. Manage print/auto-print settings.
9. Edit controlled SSI statement.
10. Each configuration and maintenance operation.
11. Each user-management operation, including create, edit, disable/enable, reset, delete, and policy inspection where supported.

## Recommended report matrix for owner/Security approval

| Operation | Operator | Supervisor | Administrator | Capability |
|---|:---:|:---:|:---:|---|
| Enter/view report surface | No | Yes | Yes | `CanAccessReports` |
| Generate Equipment/Event/User | No | Yes | Yes | `CanAccessReports` |
| View completed report | No | Yes | Yes | `CanAccessReports` |
| Export controlled report | No | Yes | Yes | New `CanExportReports` |
| Print controlled report | No | Yes | Yes | New `CanPrintReports` |
| Manage print settings | No | Yes | Yes | Existing `CanEnableDisablePrinting` |
| Edit SSI statement | No | No unless governed evidence says otherwise | Yes | Existing `CanEditSecurityFooter` |

QA and Service bundles never grant report access, export, or print independently of the authenticated base role.

## Acceptance criteria

1. Every role/capability cell cites Appendix C Table C-1, another governing requirement, or an explicit dated Security/owner attestation. Unknown cells remain blocked.
2. The published catalog contains stable operation IDs, capability IDs, descriptions, enforcement boundaries, safe denial/guidance categories, retry disposition, and unknown-code fallback. Localized strings are excluded.
3. Operator, Supervisor, and Administrator are the only selectable base-role rows. Aliases normalize without creating another matrix.
4. Conflicting base roles, unknown roles, invalid masks, unknown bits, and bundle-only users fail closed.
5. QA/Service bundles are additive only after a valid base role and never grant report operations independently.
6. Administrator receives an explicit known-capability set. New/future bits are denied until the matrix is revised and tested.
7. Report surface, each generation kind, completed-view, export, print, print settings, and SSI edit remain distinct operation IDs. Sharing `CanAccessReports` for generation/view is an explicit approved mapping, not identity collapse.
8. Controlled report export and print use dedicated append-only capabilities `CanExportReports` and `CanPrintReports` unless owner/Security explicitly chooses another reviewed expression.
9. Generation authorization is resolved before source retrieval. Export and print recheck authoritative policy immediately before mutation/submission. Cached UI state never authorizes an operation.
10. Policy results distinguish `Allowed`, `Denied`, `ReauthenticationRequired`, `PolicyUnavailable`, and unmet non-security prerequisites. SHR-032 must not collapse failures into an all-false Boolean policy.
11. Product-neutral presentation projections are frozen:
    - no report access: hide report navigation and reject deep links;
    - report access allowed but export/print denied: actions remain visible and disabled with persistent accessible denial guidance;
    - loading/unavailable/reauthentication: protected actions remain disabled and expose neutral typed guidance;
    - non-security prerequisites such as no completed report or no configured printer are distinct from authorization denial;
    - revocation/logout/policy loss disables actions immediately, announces the state, restores focus to a stable target, and applies the approved protected-content rule.
    - operation-specific denial of generation, export, print, print settings, auto-print settings, or SSI editing retains an otherwise authorized displayed report; only report-surface/completed-content access loss or session/policy loss removes protected report content.
12. Hidden elements are absent from keyboard and automation traversal. Disabled elements have persistent, screen-reader-discoverable localized explanation outside the disabled control itself.
13. Machine-readable CSV and canonical JSON contain operation ID, capability expression, role/bundle decision, typed policy state, guidance category, retry disposition, and presentation projection; both validate identically.
14. DHS and TripleQuadUI fixtures produce identical semantic decisions for every base role, bundle combination, operation, policy state, and unknown future code.
15. Existing `UserRights` numeric values and proto field numbers remain unchanged. Additive capabilities are append-only, versioned, migration-safe, and fail closed in old consumers.
16. Audit operation IDs and denial/guidance categories align with published SHR-014A before SHR-032 integration.
17. Managed-user decisions bind capability checks to a machine-readable target-scope policy. Supervisor scope is limited to Operator targets, Operator creation without specialist bundles, and Operator edits that preserve the Operator role and specialist-bundle state. Supervisor role changes are denied. Administrator scope covers the three selectable roles while preserving self-access and final-active-Administrator safeguards.

## Owner-approved v1 matrix attestation — 2026-11-18

1. Operator has no report access. Supervisor and Administrator may enter the report surface, generate Equipment/Event/User reports, and view completed reports.
2. Supervisor and Administrator may export and print controlled reports through dedicated append-only `CanExportReports` and `CanPrintReports` capabilities.
3. Supervisor and Administrator may manage print settings through `CanEnableDisablePrinting`; only Administrator may edit the controlled SSI statement through `CanEditSecurityFooter`.
4. QA and Service compatibility bundles require a valid base role and never independently grant report access, export, or print.
5. Generation and completed-report viewing share `CanAccessReports` in v1 while retaining separate stable operation IDs.
6. Report navigation is hidden when report access is denied. On an authorized report surface, denied export/print actions remain visible and disabled with persistent accessible guidance.
7. Logout, revocation, or policy-service loss removes any displayed report immediately, disables protected actions, restores focus to a stable target, and requires fresh authorization and generation.
8. Appendix C is normalized to three selectable base roles. Administrator represents the highest governed level; no separate selectable commissioning role is introduced. Compatibility bundles remain non-selectable additive inputs.
9. Administrator grants are an explicit named set; conflicting roles, bundle-only input, unknown roles/bits, and unsupported policy versions fail closed.
10. This dated owner attestation authorizes SHR-030 artifact preparation. Security confirmation remains required before SHR-032 production enablement and product release.

## Non-goals

- No source changes to User Management, products, Common.Reports, UI routes, or gitlinks.
- No production enablement; SHR-032 implements the approved contract.
- No lockout/reset policy; SHR-031 owns it.
- No product-specific matrix.

## Validation and handoff

Validate schema, canonical CSV/JSON equivalence, exhaustive matrix/alias/bundle/unknown-bit/presentation fixtures, version compatibility, formatting/diff/disclosure, and protected-repository SHA/status. Reviewer Integration and owner/Security approval are required before SHR-032 becomes development-ready.

## Feature Engineering evidence

- Published SHR-014A alignment: all 39 operation names and ordinals match Common.Reports `743a65b40d9351bfd296ad477c9bd51f184948fb`.
- Matrix coverage: 3 roles x 4 bundle sets x 39 operations x 5 policy states = 2,340 unique decisions.
- Each decision resolves one of 11 structured target-scope policies without adding a target dimension. The schema therefore remains 2,340 exhaustive decisions while requiring 18 semantic fields per row.
- Seven explicit presentation fixtures begin with independently proven Supervisor report access. Six policy-denial fixtures prove action/settings denial retains an authorized report while report-surface/completed-view denial removes content; the seventh separately proves Supervisor SSI role denial retains that authorized report. Four target-scope fixtures prove Supervisor Operator-only management, prohibited Supervisor role changes, and Administrator safeguards.
- Canonical CSV and JSON regenerate byte-for-byte from the checked-in generator and validate identically.
- DHS and TripleQuadUI parity manifests bind the same matrix and fail-closed fixture hashes.
- Existing UserRights bit positions and AccessPolicy proto fields remain read-only and unchanged; planned report export/print additions are append-only bits/fields 31 and 32.
- Focused validation command: `./validate-capability-matrix.ps1` from this directory, or the command documented in `README.md` from the agent-system root.
- Security confirmation remains a release gate. SHR-032 remains blocked pending Reviewer Integration and publication of this artifact.
