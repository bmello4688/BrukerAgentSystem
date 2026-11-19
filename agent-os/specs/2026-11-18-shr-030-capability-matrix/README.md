# SHR-030 capability matrix v1

This directory contains the provider-neutral authorization contract that SHR-032 must implement. It does not enable any capability and does not modify User Management or either product.

## Authoritative artifacts

- `capability-catalog.v1.json` freezes capability bits, three selectable base roles, compatibility bundles, all 39 published SHR-014A operation identities, 11 structured managed-user target-scope policies, enforcement boundaries, evidence IDs, and rolling-upgrade rules.
- `capability-matrix.v1.json` is the canonical decision set.
- `capability-matrix.v1.csv` is the reviewable tabular representation of the same decisions.
- `capability-matrix.v1.schema.json` freezes the canonical JSON shape.
- `fixtures/` contains alias, fail-closed, and cross-product parity evidence.
- `generate-capability-matrix.ps1` deterministically regenerates the artifacts.
- `validate-capability-matrix.ps1` validates regeneration, exhaustiveness, published contract alignment, and product parity.

The matrix is exhaustive over:

- 3 selectable base roles: Operator, Supervisor, Administrator;
- 4 bundle sets: none, Lab/QA, Service/Maintenance, and both;
- 39 stable operation identities published by SHR-014A;
- 5 typed policy states.

That produces 2,340 canonical decisions. DHS and TripleQuadUI consume the same semantic fixture hash; neither product owns a separate role matrix.
Target role is not another matrix dimension: every role/operation decision resolves a required `targetScopePolicyId`, and SHR-032 must enforce both the capability expression and that policy before a managed-user operation.

## Capability and role rules

1. User Management remains the authoritative policy service. A UI projection is never authorization.
2. Base roles are mutually exclusive. Unknown or conflicting roles fail closed.
3. Lab/QA and Service/Maintenance are compatibility bundles, not selectable roles. A bundle without one valid base role fails closed.
4. Bundle grants are additive only and never independently grant report access, report export, or report print.
5. Administrator is an explicit known-capability set. Unknown and future bits are denied until this contract is revised.
6. `CanExportReports` is planned as append-only bit 31 and AccessPolicy proto field 31.
7. `CanPrintReports` is planned as append-only bit 32 and AccessPolicy proto field 32.
8. Existing `UserRights` values and AccessPolicy proto fields 1-30 remain unchanged.
9. Old consumers that do not understand the new bits must deny export and print. SHR-032 owns additive implementation and rolling-upgrade tests.

## Managed-user target scope

- Operator has no managed-user target scope.
- Supervisor may inspect and mutate Operator targets only.
- Supervisor may create only enabled Operator accounts without Lab/QA or Service/Maintenance specialist bundles.
- Supervisor edits must retain the Operator base role and existing specialist-bundle state; Supervisor role changes are denied.
- Administrator may manage Operator, Supervisor, and Administrator targets, subject to self-access and final-active-Administrator safeguards.
- Unknown target roles, requested roles, scope-policy IDs, or target/scope mismatches fail closed before mutation.

## Report policy

- Operator has no report access.
- Supervisor and Administrator may enter the report surface, generate Equipment/Event/User reports, view completed reports, export, and print.
- Generation and viewing share `CanAccessReports` but retain distinct stable operation identities.
- Export and print require `CanExportReports` and `CanPrintReports`, respectively.
- Supervisor and Administrator may manage print and auto-print settings through `CanEnableDisablePrinting`.
- Only Administrator may edit the controlled SSI statement through `CanEditSecurityFooter`.
- Generation is authorized before source retrieval. Export and print recheck authoritative policy immediately before their irreversible boundary.

## Presentation contract

- When report-surface access is denied, navigation is hidden, deep links are rejected, protected report content is removed, focus returns to a stable target, and neutral denial status is announced.
- On an authorized report surface, an operation-specific denied or unmet-prerequisite generation/export/print/settings/SSI action remains non-authorizing and disabled with persistent accessible guidance outside the disabled control, while retaining the authorized report content.
- Report-surface or completed-content access denial removes content. Reauthentication, logout, revocation, and policy-service loss also remove displayed content because the product can no longer establish report access.
- Hidden elements are absent from keyboard and automation traversal.
- Logout, revocation, policy loss, and policy-service failure remove displayed protected report content immediately and require fresh authorization and generation.
- Non-security prerequisites remain distinct from authorization denial.
- No localized UI text is part of the contract. Products map the stable guidance, retry, focus, and announcement codes to localized accessible presentation.

## Guidance alignment

The stable guidance and retry codes align with published SHR-014A:

- `authorization-denied` / `do-not-retry`
- `reauthenticate` / `reauthenticate`
- `retry-when-ready` / `retry`
- `correct-input` / `correct-request`
- `unknown-code` / `do-not-retry`

Allowed decisions use `none` / `none`. Unknown future roles, operations, policy states, guidance codes, schema versions, and bits use the fail-closed `unknown-code` projection.

## Evidence and authority

- FRD requirement 133 and Appendix C Table C-1 govern access-level capability intent.
- The dated owner attestation in `story.md` normalizes Appendix C into three selectable product roles and approves the v1 report matrix.
- The current User Management resolver is evidence for existing named capabilities and compatibility-bundle contents only; unsafe precedence, bundle-only grants, future-bit Administrator masks, and disabled report access are explicitly not carried forward.
- Security confirmation remains required before SHR-032 production enablement and product release.

The artifacts contain no credentials, user data, report data, role display localization, machine identifiers, or product-specific routes.

## Validation

From the agent-system root:

```powershell
& .\agent-os\specs\2026-11-18-shr-030-capability-matrix\validate-capability-matrix.ps1
```

The validator is read-only outside this directory. It confirms exact alignment with the published Common.Reports SHR-014A operation catalog, the current User Management numeric/proto baseline, explicit report-presentation fixtures, and managed-user target-scope fixtures.
