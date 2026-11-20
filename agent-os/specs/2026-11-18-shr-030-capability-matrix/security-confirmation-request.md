# SHR-030 Security Confirmation Request

## Purpose

Security confirmation is the remaining gate before SHR-032 may enable the accepted User Management report policy. This request binds approval to exact reviewed artifacts and does not contain credentials, production user data, or the controlled SSI statement text.

## Accepted evidence

- Published agent-system commit: `ff84aed2b0f5eb238c2d12ab1444b5f264a66344`
- Reviewer Integration verdict: GO
- Matrix decisions: 2,340 unique rows (`3 roles x 4 bundle sets x 39 operations x 5 policy states`)
- Audit operation alignment: 39/39 against published SHR-014A

| Artifact | SHA-256 |
|---|---|
| `capability-matrix.v1.json` | `609c4f45523c193203b30d96c5f83d5335e88cf5e00f171b0d296a59a521a7aa` |
| `capability-matrix.v1.csv` | `02af7118dd1870268cc5705d328826e8795bd8777692f9cd1d50bc8ede23de7d` |
| `capability-catalog.v1.json` | `50dd4ecfda7b1524d44834306ad36ecc107eae953bce1cf610916168d77cb509` |
| `fixtures/fail-closed-inputs.v1.json` | `08a4869126f1e868e5d3b65bf95269f1bdbe2f92688b02d62da38664c14b8d9b` |

## Requested confirmations

Security should explicitly approve or reject each item:

1. Operator receives no report access; Supervisor and Administrator receive report generation/view access.
2. Supervisor and Administrator receive dedicated export and print capabilities.
3. Append-only assignments are approved: `CanExportReports` at rights bit 31 / AccessPolicy field 31 and `CanPrintReports` at rights bit 32 / AccessPolicy field 32.
4. Supervisor and Administrator may manage print and auto-print settings; only Administrator may edit the controlled SSI statement.
5. QA/Service bundles require a valid base role and never grant report access, export, or print independently.
6. Conflicting roles, bundle-only users, unknown roles, unknown bits, unsupported versions, and policy-service failure fail closed.
7. Administrator uses an explicit known-capability set rather than a future-bit mask.
8. Supervisor managed-user scope is limited to Operator targets without role or specialist-bundle mutation; Administrator safeguards preserve self-access and a final active Administrator.
9. Export and print recheck authoritative policy immediately before their irreversible boundary; cached UI state never authorizes an operation.
10. The production controlled SSI source is `dhs.printer-settings.ssi-statement`; Security has verified the normalized production statement and its content-derived revision through an approved internal channel. The statement text is not copied into this request.

## Approval record

Record the confirmation without adding sensitive SSI text:

- Security reviewer/authority:
- Review date and time zone:
- Verdict: `GO` / `NO-GO`
- Approved artifact commit and hashes:
- Controlled SSI revision confirmed: `yes` / `no`
- Conditions or rejected items:

`GO` makes SHR-032 development-ready. `NO-GO` keeps production report authorization disabled and must identify the exact matrix item or artifact requiring revision.
