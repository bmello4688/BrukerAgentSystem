# Closed authorization outcomes and safe guidance

## Contract rules

- The outcome set is closed and serialized by the exact stable code below.
- Unknown enum values, strings, schema versions, or combinations map to `UnknownCodeOrVersion` and
  fail closed.
- `retry` is one of `None`, `CorrectRequest`, `Reauthenticate`, `RetryWhenReady`, or `ContactSupport`.
- Default operator text is localization input, not diagnostic text. It never includes a token,
  credential, username/user ID, session/correlation/configuration ID, machine identity, file path,
  endpoint, provider/store name, exception type/message/stack, rights mask, or role detail.
- Restricted diagnostics may contain approved opaque receipt references, but they are not interpolated
  into default operator text and follow the existing protected logging policy.

## Exhaustive table

| Stable code | Trigger | Readiness | Retry | Protected content | Default operator text |
|---|---|---|---|---|---|
| `Succeeded` | Exact operation completed with accepted audit terminal result | `Ready` | `None` | Retain per product-state contract | Operation completed. |
| `InvalidInput` | Required input is missing, malformed, or out of range before authorization/mutation | unchanged | `CorrectRequest` | Retain only if report-surface access remains valid | Check the highlighted information and try again. |
| `ReauthenticationRequired` | No token, expired token, restart-invalidated token, or authentication continuation ended | `Unavailable` | `Reauthenticate` | Remove | Sign in again to continue. |
| `Denied` | Valid current session lacks the exact required capability or target scope | `Ready` | `None` | Remove only for report-surface/completed-view denial; otherwise retain authorized content | You are not authorized to perform this operation. |
| `StaleSession` | Local session generation changed or a request completed against a superseded session | `Unavailable` | `Reauthenticate` | Remove | Your sign-in is no longer current. Sign in again. |
| `RevokedSession` | User/session was explicitly revoked or current-account validation rejects it | `Unavailable` | `Reauthenticate` | Remove | Your sign-in is no longer active. Sign in again. |
| `PolicyUnavailable` | Service health or policy RPC is unavailable/timeout and no authoritative decision exists | `Unavailable` | `RetryWhenReady` | Remove | Reporting is temporarily unavailable. Try again when the service is ready. |
| `MigrationIncomplete` | Activation/manifests/reconciliation are absent or any exact threshold failed | `Unavailable` when activated; otherwise `Disabled` | `ContactSupport` | Remove | Reporting setup is not complete. Contact support. |
| `IdentityOrPolicyConflict` | Duplicate/mismatched actor claim, session, machine/scope, role, rights, manifest, or revision | `Unavailable` | `ContactSupport` | Remove | Reporting cannot continue because required security information is inconsistent. Contact support. |
| `UnknownCodeOrVersion` | Unknown outcome, role/right bit, operation, contract, manifest schema, mode, or product/service version | `Unavailable` | `ContactSupport` | Remove | Reporting cannot continue with this software version. Contact support. |
| `Canceled` | Operator cancellation was accepted before the irreversible boundary, with required audit terminal handling complete | unchanged | `None` | Retain only while current report access remains valid | Operation canceled. |
| `SupportRequired` | Closed failure is not safely recoverable by correction, reauthentication, or readiness retry | `Unavailable` for authorization/migration failures | `ContactSupport` | Remove for authorization uncertainty | The operation could not be completed. Contact support. |

## Precedence

When more than one condition is observed, select exactly one outcome in this order:

1. `UnknownCodeOrVersion`
2. `IdentityOrPolicyConflict`
3. `MigrationIncomplete`
4. `RevokedSession`
5. `StaleSession`
6. `ReauthenticationRequired`
7. `PolicyUnavailable`
8. `Denied`
9. `InvalidInput`
10. `Canceled`
11. `SupportRequired`
12. `Succeeded`

An irreversible effect that may already have occurred is not rewritten to `Canceled`, `Denied`, or
`PolicyUnavailable`. It follows the SHR-014C two-dimensional effect/audit outcome and uses
`SupportRequired` only when the product cannot safely present the normal typed result.

## Disclosure fixtures

For every default operator string, tests inject representative sensitive values into all diagnostic
inputs and assert that rendered text contains none of them and none of these labels or shapes:

- bearer/JWT segments, temporary credentials, recovery/setup material;
- identity/session/correlation/configuration/machine values;
- absolute/UNC/URI paths and host/port text;
- exception/provider/store type names, messages, or stack frames;
- role names, right names/masks, or account counts.

Unknown localization keys fall back to the safe `SupportRequired` text, never raw exception text.
