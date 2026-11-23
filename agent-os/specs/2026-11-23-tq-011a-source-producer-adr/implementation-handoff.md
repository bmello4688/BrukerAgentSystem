# TQ-011B exact implementation handoff

## Authorization verdict

**Not Development-ready today.** TQ-011A selects `ForwardOnlyAtCutover`, so no migration child is required. TQ-011B is authorized for triad review and becomes Development-ready only after all gates below are recorded against immutable accepted commits. Unpublished SHR-011D1/2, the new mandatory SHR-011D3 activation/control-store contract, the trusted session bridge, and approved alarm/configuration mappers are real blockers, not implementation discretion.

## Required gates before branch creation

| Gate | Required evidence |
|---|---|
| TQ-011A publication | Exact accepted planning SHA plus independent Reviewer Integration GO. |
| SHR-011D1 | Accepted/published Common.Reports SHA; exact `IFdrsReportSourceQuery` symbols/signatures and conformance command match the ADR. |
| SHR-011D3 | Accepted/published D3c Common.Reports SHA containing exact product-neutral `IReportSourceControlStoreV1`, typed `Initial`/`Successor`/`Rollback`, canonical history, D2 lease contract, immutable attempt journal, strict receipt shapes, DataService provider/schema composition, and conformance commands from the [contract epic](../2026-11-23-shr-011d3-report-source-control-store/story.md). TQ-specific operation/domain/prefix semantics remain in the separately reviewed TQ profile implemented by TQ-011B. |
| SHR-011D2 | Accepted/published Common.Reports SHA descendant of D1 and D3c; exact `DataServiceFdrsReportSourceQuery` provider/project, D3 lease use, activation-history snapshot fingerprint/interval validation, and tests match the ADR. |
| actor/session | Accepted bridge contract/implementation SHA proving durable UserId/SessionId/attempt lifecycle and no token/display-name persistence. |
| alarm mapping | Named Bruker SME/owner approval, versioned controlled code/strength mapping, exhaustive unknown-value tests. |
| config identity | Accepted canonical `ConfigurationRevisionId` source available at sample acceptance, plus owner-approved successor-activation workflow for legitimate changes. |
| triad | Coordinator Architect, Domain Analyst, and User Experience explicitly mark TQ-011B Development-ready. |
| release ownership | Named TripleQuadUI product release owner for cutover/rollback, recorded before `T0`. |

If D1/D2/D3 publishes different public symbols or semantics, amend/re-review this ADR. Do not adapt silently.

## Repository/base/branch/worktree

- Repository: `C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI`
- Exact TripleQuadUI base: `26d3b174795384841b60eea987f97c7a711f8892`
- Branch: `feature/tq-011b-report-source-integration`
- Isolated worktree: `C:\Git\Commercial\MrmETDSpec\TripleQuadUI-tq011b-report-source`
- Baseline Reports gitlink: `fd705711aa17ab23e34efa1bcf52422ee50868fd`
- Baseline DataService gitlink (must remain unchanged): `ca36e9aabb149da9ff6d02e6707bd3df77224b38`
- Baseline Services gitlink: `14bd2025255d535ea1353aa4210679a535e781fe`

Branch from the exact base, not moving `master`. Before edits, verify a clean worktree and exact gitlinks. If the required trusted session bridge lives in Services, Coordinator Architect must record its separately accepted commit and explicitly authorize that gitlink advance; otherwise Services remains unchanged.

## Owned product paths

Primary new implementation/tests:

- `CoreLogicLayer/SubstanceAnalyzerCore.Service/Reporting/**`
- `Tests/Integration/SubstanceAnalyzerCore.Service.IntegrationTests/ReportSources/**`

Narrow integration edits only:

- `CoreLogicLayer/SubstanceAnalyzerCore.Service/ServiceHost.cs`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/SubstanceAnalyzerCore.Service.csproj`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleCollector.cs`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleCollectionManager.cs`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/Services/SampleCollectionService.cs` only if async admission must propagate through the existing service; no proto change
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/Services/SampleCollectionBackgroundService.cs`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.MicroServices.Host/MicroServicesHostedService.cs`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/appsettings.json` for a disabled/default `ReportsV1` schema only after Coordinator review; deployment zone value is not committed
- `Tests/Integration/SubstanceAnalyzerCore.Service.IntegrationTests/SubstanceAnalyzerCore.Service.IntegrationTests.csproj`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.slnx` only if an approved new test project requires it
- `CommonLibraries/Reports` gitlink advanced to the exact accepted SHR-011D2 descendant
- `CommonLibraries/Services` gitlink only under the explicit bridge condition above

Expected new classes are exactly:

- `IAnalyzerReportSourceProducerV1` / `AnalyzerReportSourceProducerV1`
- `AnalyzerReportSourceQueryFacadeV1`
- `ReportSourceReadinessGateV1`
- SHR-011D3 `ReportSourceActivationBindingV1` consumer/validator (do not duplicate the contract locally)
- `MachineIdentityProviderV1`
- `ReportingZoneBindingV1`
- `ReportSourceReconcilerV1`
- `ReportSourceLifecycleHostedServiceV1`
- immutable `Trusted*V1` input records and the closed local outcome mapper

## Protected paths/behavior

Do not change:

- Uno/UI/view models, report UI/renderers/printers;
- `.proto` files, generated clients, or add any HTTP/Kestrel/gRPC report endpoint;
- Common.DataService source/schema/provider or its gitlink;
- Common.Reports FDRS/query contracts/provider source in the product story;
- hardware interfaces, simulator protocol, instrument behavior, acquisition algorithms/classifier internals;
- legacy sample files/data, existing FDRS records, high-water state, imports, or activation history;
- solution-wide props/packages unless a separate reviewed story owns them.

The only hardware behavior interaction is read-only identity observation and gating sample admission until FDRS acceptance. Any change to physical instrument behavior requires separate owner review.

## Implementation order

1. Pin accepted Reports (and conditional Services) gitlinks; add analyzer/test project references.
2. Implement pure machine, canonical zone bytes/hash, trusted time, activation interval, source-component, and all fourteen outcome validations.
3. Implement SHR-011D3 consumer and producer facade. Use only published closed enums/CBE-v1 helpers and vectors; journal the exact intent before every repository call. Only the producer/lifecycle dispatcher resolves/retries pending operations.
4. Implement readiness gate/lifecycle/reconciler, disabled by default, in the frozen startup order: at actual `StartAsync` entry capture startup UUID/occurrence; construct source; initialize D3/FDRS; await health plus subsequent connected snapshot; bind zone/config/contracts; load activation or commit generation 1 with `T0 = captured occurrence`; resolve pending operations; recover sample/session; append restart start at exactly T0 for generation 1 while still disabled; warm, reconcile, and run conformance; append successful `RestartCompleted` and persist its accepted receipt; enable writers, then queries.
5. Wire trusted session/config/alarm dependencies; prove prohibited fields cannot enter drafts/logs and legitimate configuration change requires a successor activation.
6. Refactor exact sample admission/completion hooks to await intent and persistence; derive correlations from durable logical IDs and keep Event ID/correlation stable.
7. Register D2 and D3 providers plus query facade in `ServiceHost`; prove no endpoint/direct schema access.
8. Add host startup-attempt UUID/`OccurredUtc` handoff without changing hardware service/protocol/behavior.
9. Run cutover/reactivation/restart/rollback/concurrency/cancellation/disclosure tests, then project and solution validation.

## Required focused tests

Add tests under `ReportSources/**` for:

- machine hash known vectors, invalid serial, case distinction, initial snapshot rejected, health-before-subscription event ordering, connected event-applied snapshot accepted and latched; a different valid serial before activation and a second distinct valid serial during one activation attempt each map only to `MachineMismatch` without replacing the latch; equal-machine duplicate/conflicting activation claims map to `IdentityCollision`; later serial change maps to `MachineMismatch`;
- canonical zone byte-for-byte vectors and both published hashes; every `TimeZoneInfo` property including `BaseUtcOffsetDelta`/`NoDaylightTransitions`; invalid ID; DST ambiguous/invalid boundaries; rule fingerprint change;
- clock UTC/default/backstep behavior and deterministic `TimeProvider` injection;
- authoritative source name and assembly informational version; readiness default disabled and every gate/mixed-version failure;
- activation typed mode/reason matrix, initial/exact retry/collision/pointer corruption/successor/config-only transition/typed zero-write rollback/post-write compatibility; only equal-machine multiple-active or duplicate/conflicting activation claims map to `IdentityCollision`, every different valid activation machine maps to `MachineMismatch`, and missing/corrupt transition evidence maps only to `SourceGap`;
- CBE-v1 independent preimage/hash/UUID vectors; all nine operation kinds/eight phase tokens/logical-ID grammars; draft fields/list/null normalization; durable operation/correlation retry across every crash boundary;
- generation-1 `T0` equals the captured restart occurrence, first restart-start occurrence equals T0, no pre-T0 operation/record; accepted sample start before acquisition; rejection/ambiguous acceptance prevents acquisition;
- exactly one terminal for Clear/Alarm/Failure, same Event ID, no wrap/reuse, cancellation after commit;
- interrupted Event failure before recovery session end; duplicate restart/session/annotation retry;
- trusted UserId/SessionId exact join; denied/open/incomplete/completed sessions; no username/token/time join;
- annotation Unknown, explicit append/correction, 512/513 scalars, redacted diagnostics;
- exhaustive approved alarm map and unknown code/strength; no detected names/quantity/score;
- D1 conformance including empty, exact Event not found, ordering ties, paging/cursor/lease/limit/cancellation cases listed in the volume report;
- forward-only range before/at `T0`, unexpected preactivation/import state, no legacy reader call;
- duplicates/gaps/conflicting terminals/orphan sessions/incomplete restarts/machine/zone/config mismatch, proving every syntactically valid machine-ID difference in request, hardware, record, and activation maps only to `MachineMismatch`, including a different valid serial before activation and a second distinct valid serial during one attempt, while duplicate/conflicting equal-machine claims map to `IdentityCollision` and missing/corrupt activation/source evidence maps to `SourceGap`;
- exact frozen startup/restart ordering and readiness only after storage, binding, pending-operation recovery, warmup, reconciliation, conformance, successful `RestartCompleted`, and its accepted receipt; prove `RestartStarted` alone leaves writers and queries disabled, then writers precede queries;
- exhaustive disjoint fourteen-trigger matrix and precedence, including invalid identity while readiness is disabled; all four valid-machine-difference origins, a different valid serial before activation, and a second distinct valid serial during one attempt even when an identity-claim conflict or source corruption also exists; equal-machine multiple-active versus missing activation evidence; lease expiry `RestartQuery`; and both `LimitExceeded` variants; every non-ready outcome has no value and passes disclosure scan;
- rollback with no write and post-write compatibility block.

Use synthetic controlled data only. Hardware/simulator qualification verifies only the serial/readiness transition and sample admission sequencing; it does not relax contract tests.

## Validation commands

From the TQ-011B worktree root, record exact output for:

```powershell
dotnet test .\Tests\Integration\SubstanceAnalyzerCore.Service.IntegrationTests\SubstanceAnalyzerCore.Service.IntegrationTests.csproj -c Release
dotnet build .\CoreLogicLayer\SubstanceAnalyzerCore.Service\SubstanceAnalyzerCore.Service.csproj -c Release
dotnet test .\CommonLibraries\Reports\Common.Reports.sln -c Release
dotnet build .\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx -c Release
git diff --check
git status --short --branch
```

Also run exact D1, D2, and D3 conformance commands documented by their accepted publications. If the Common.Reports solution filename/command differs at publication, record the published command and update this handoff through review before execution.

Required non-build evidence:

- `git diff --submodule=log` shows only authorized gitlink movement;
- search proves no new `MapGrpcService`, Kestrel listener, proto, direct provider collection, `Environment.MachineName`, ambient local time, token/username persistence, or legacy report read;
- dependency/disclosure scans from D1/D2/D3 pass;
- simulator identity/admission/restart smoke proves health plus post-health applied connected observation; real hardware validation is required before site enablement because the serial source is hardware-sensitive. No hardware source/protocol change is authorized.

## Readiness disablement

The shipped default is disabled. The gate has only `Disabled`, `WritersEnabledQueriesDisabled`, and `Ready`; no degraded/partial mode. Any failed dependency, mixed version, pending/unresolved operation, reconciliation discrepancy, hardware/zone/source/config/activation change, or provider integrity result atomically returns to `Disabled`. Re-enable requires the applicable runbook and, where binding fields changed, an owner-authorized SHR-011D3 successor activation; service restart alone does not clear a failure.

## Gitlink and runtime rollback

- Pre-T0: revert the TQ-011B commit and compatible gitlinks. Proven zero accepted/pending writes after T0: retain history and call typed D3 `Rollback/ZeroWriteRollback` with current predecessor and named compatible target; atomically close current as rolled back and create a copied active successor at a new T0, or remain disabled. Restore Reports to `fd705711aa17ab23e34efa1bcf52422ee50868fd` only when that baseline reads the retained D3 history; otherwise deploy the last compatible Reports SHA. Restore Services conditionally and keep DataService gitlink unchanged.
- Post-write: do not restore an incompatible Reports/producer set. Preserve data and deploy the last compatible accepted SHAs or a reviewed roll-forward.
- No rollback deletes/rewrites FDRS/control or legacy data, resets IDs, edits activation history/T0, or enables fallback.
- The **named TripleQuadUI product release owner recorded in the deployment/cutover record** owns the rollback decision. TQ-011B cannot be released with an unnamed/generic owner.

## Required implementation handoff back to review

1. Behavior changed, including exact `T0`/history/readiness behavior.
2. Files/projects/gitlinks changed with before/after SHAs.
3. Commands/outcomes above plus skipped hardware/site validation and reason.
4. Contract, hardware, safety, security, disclosure, and no-new-transport evidence.
5. Known risks/follow-ups, named rollback owner, and Reviewer Integration GO/no-go.
