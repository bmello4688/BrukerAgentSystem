# RC Alarm Resilience And Consolidated Alert Workflow Plan

This document is local Agent OS planning material. Keep it outside the Bruker Detection TripleQuadUI Git repo.

## Starting Posture

BL-017 is development-ready as of 2026-06-15 after Coordinator Architect, User Experience, Domain Analyst, and Product Owner triad decisions. It builds on completed BL-007 alarm-control UI refinement and completed BL-016 simulator collection/persistence proof.

Current source checkout baseline:

- `C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI`
- Branch: `master`
- Baseline commit: `10d322a` (`Guard sensor percent calculations`)
- Source worktree was clean at BL-017 start.

## Product Goal

RC alarm handling must remain clear and resilient across navigation, restart/reconnect, repeated detections, and multiple-substance detections consolidated into one active alarm.

The operator outcome is: when a simulator sample produces a substance detection, the alarm stays unmistakable until explicitly cleared or until the operator inserts a new swab for the next sample; silencing audio never downgrades the visual alert; navigation or reconnect does not lose the active alert where practical for RC; and repeated/multiple detections are represented as one consolidated active alert.

## Current Code Surface

Primary UI surface:

- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/Presentation/Controls/SystemAlarmControl.xaml`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/Presentation/Controls/SystemStatusPanel.xaml`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/Presentation/Models/AppModel.cs`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/Presentation/Models/AudibleAlarmState.cs`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/Presentation/Converters/AudibleAlarmStatesToStringConverter.cs`

Primary service/core surface:

- `CoreLogicLayer/SubstanceAnalyzerCore.Service/Services/SampleCollectionService.cs`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleCollectionManager.cs`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleDataAnalyzer.cs`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SubstanceAnalysis.cs`
- `CoreLogicLayer/SubstanceAnalyzerCore.Service/Protos/sampleCollectionService.proto`
- `CoreLogicLayer/SubstanceAnalyzerCore.Client/SampleCollectionServiceClient.cs`

Primary validation surface:

- `Tests/EndToEnd/MrmEtdMassSpecAnalyzer.EndToEndTests/MicroServicesHarnessTests.cs`
- Existing service integration tests under `Tests/Integration/SubstanceAnalyzerCore.Service.IntegrationTests`
- UI build: `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.csproj -f net10.0-desktop`

## Initial Findings

- BL-007 alarm-control wording/layout appears already present in `SystemAlarmControl.xaml`: `Silence Audio`, `Audio Silenced`, `Clear Alert`, stable columns, and automation names.
- `AppModel` treats active non-confidence alerts as alarm status unless the detection overview contains `No Threat`; confidence-check alerts are active only when the confidence check did not pass.
- `SampleCollectionService` keeps the latest `_substanceAlertInformation` in memory and exposes it to new subscriptions through `GetLiveSubstanceAlertSubscription`.
- `SampleCollectionService.ClearAlert()` clears the service-side alert and publishes both alert and collector-state updates.
- `SampleCollectionManager.ClearAlarm()` clears the current `SubstanceAnalysis`, mutes audio, and raises alert change.
- Product Owner decision on 2026-06-15: inserting a new swab may auto-clear the prior active alarm. Operators cannot be prevented from inserting a new swab, and the system should not throw away any samples because the prior alarm-clear timing was imperfect.
- Product Owner decision on 2026-06-15 10:53 EDT: active-alert logic should have an explicit property indicating whether the sample was expected to be a confidence check. If it was expected to be a confidence check, `Passed`/`Success` must not raise an alarm; only a failed confidence check should alarm.
- Domain Analyst found this is legacy-compatible with DHS-GUI substance-alarm semantics: the live substance alarm is a single current alert, and a new swab insertion clears the prior live alarm before the next analysis.
- Restart survival is likely service-process dependent today: in-memory alert state survives UI navigation/reconnect to the same running service, but not a core service process restart unless it is rehydrated from persisted sample metadata or another durable source. Triad should define the RC practical target.

## Triad Questions

Coordinator Architect:

- Decide whether BL-017 should split into service-state resilience and UI/demo validation, or stay one branch.
- Decide branch/worktree ownership and whether implementation should touch UI only, core service only, or both.
- Define restart/reconnect target precisely: UI navigation, UI app restart reconnecting to same core service, core service restart, or all three.

User Experience:

- Confirm active alarm visual/state expectations after navigation away/back, mute, clear, and repeated detections.
- Confirm consolidated wording for one vs multiple detected substances. Current `AppModel` substatus uses `Detected {count} substances`.
- Treat the 2026-06-15 Product Owner decision as settled for RC: a new swab insertion may clear the prior active alarm. UX should focus on making that transition understandable and ensuring mute/clear states do not imply a stale alarm is resolved before either explicit clear or new sample start.

Domain Analyst:

- Domain input complete: DHS-GUI substance-alarm semantics support single live alert behavior, mute separate from clear, and prior-alarm auto-clear on new swab insertion.
- Flag any safety/regulatory expectation around persistent alerts, clear action, or restart survival.
- Confirm no hardware alarm semantics should change for RC.

Reviewer Integration:

- Later review should prove no local Agent OS references enter the Bruker repo, no broad user-management/audit model is introduced, and simulator-only validation is labeled separately from hardware/manual validation.

## Proposed Development Shape

Recommended branch/worktree after triad marks development-ready:

- Branch: `feature/rc-alarm-resilience-consolidated-alert`
- Worktree: `C:\Git\Commercial\MrmETDSpec\worktrees\rc-alarm-resilience-consolidated-alert`

Triad decision:

- Use one branch/worktree for RC.
- Do not split service-state resilience from UI/demo validation unless implementation discovers core-service restart rehydration is required and practical.
- RC restart/reconnect target is navigation/page-model resubscription plus UI app restart/reconnect to the same running core service.
- Core service process restart persistence is out of RC for BL-017 and should be documented as a limitation unless Product Owner explicitly approves durable alert rehydration.
- Preserve legacy-compatible new-swab auto-clear for live substance alarms.
- Do not discard or skip the next sample because prior alarm-clear timing was imperfect.

Recommended scope:

- Preserve BL-007 UI labels and layout.
- Add or strengthen service/E2E proof for simulator-triggered alarm, mute, clear, return to Ready, and subsequent new alarm.
- Preserve new-swab auto-clear of the prior live alarm so collection can proceed without discarding samples due to alarm-clear timing.
- Preserve distinct expected-confidence-check semantics so passed confidence checks can report detected confidence compounds without being treated as active alarms.
- Prove active alert survives UI navigation/model re-subscription by using current alert retrieval/subscription behavior where practical.
- Prove reconnect to a running service gets the current active alert from `GetLiveSubstanceAlertSubscription` initial emission and/or `GetCurrentSubstanceAlert`.
- Consolidate repeated/multiple detections into one active alarm state for RC, without adding a multi-alarm queue.
- Only add durable rehydration after core service restart if triad decides it is practical and required for RC.

Recommended non-goals:

- No new formal acknowledgement/audit model.
- No separate multi-alarm queue.
- No supervisor permissions or user-management dependency.
- No hardware alarm semantics change.
- No report generation, history clear/export, or broad archive work.

## Draft Acceptance Evidence

- Simulator sample triggers an active alarm with detected substance information.
- `Silence Audio` mutes the audible alarm but leaves alarm status active and visually severe.
- `Clear Alert` clears the active alert and returns the system to Ready when backend state is clear.
- Inserting a new swab for the next sample may auto-clear the prior live alarm; the transition must be understandable to the operator, and the new sample must still be collected/persisted rather than discarded because of alarm-clear timing.
- Navigation/page-model resubscription does not lose the active alert.
- UI reconnect to the same running service receives the current active alert.
- Restart/reconnect behavior is proven to the triad-defined RC practical target and any deeper restart limitation is documented.
- Repeated or multiple-substance detections are shown as one consolidated active alert for RC.
- A second alarm can trigger after clearing the first.

## Validation

Expected focused validation after implementation:

```powershell
dotnet build "CoreLogicLayer\SubstanceAnalyzerCore.Service\SubstanceAnalyzerCore.Service.csproj" --no-restore
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.MicroServices.Host\MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj" --no-restore
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.csproj" -f net10.0-desktop --no-restore
dotnet test "Tests\Integration\SubstanceAnalyzerCore.Service.IntegrationTests\SubstanceAnalyzerCore.Service.IntegrationTests.csproj" --no-restore --logger "console;verbosity=minimal"
$env:RUN_BRUKER_SERVICE_E2E_TESTS="true"
dotnet test "Tests\EndToEnd\MrmEtdMassSpecAnalyzer.EndToEndTests\MrmEtdMassSpecAnalyzer.EndToEndTests.csproj" --filter "FullyQualifiedName~MicroServicesHarnessTests" --logger "console;verbosity=minimal"
```

Run `scripts\launch-rc-dev.ps1 -NoBuild -StopAfterReady -StartupTimeoutSeconds 90` if launch/runtime configuration changes, or before BL-019 signoff.

## Open Risks

- Alarm rehydration after core service process restart may require a persistence decision; this could expand scope beyond a 5-point RC story.
- New-swab auto-clear is now a Product Owner decision for RC; validation still needs to prove this does not hide a current detection unexpectedly and does not discard the next sample.
- Simulator data must reliably trigger a non-confidence substance detection; if the available simulator substance does not produce alarm output, Feature Engineering may need to select a known positive sample or add test-only fixture control without changing classifier behavior.

## Feature Engineering Handoff

Development is ready to start on `feature/rc-alarm-resilience-consolidated-alert` from source `master` at `10d322a`.

File ownership claims:

- UI alarm/status surface: `SystemAlarmControl.xaml`, `SystemStatusPanel.xaml`, `AppModel.cs`, `AudibleAlarmState.cs`, and the audible alarm state converter only if needed.
- Core/service alert surface: `SampleCollectionService.cs`, `SampleCollectionManager.cs`, `SampleDataAnalyzer.cs`, and related client/proto only if the existing service contract cannot prove reconnect behavior.
- Validation: focused service integration tests and `MicroServicesHarnessTests.cs`.

Implementation guardrails:

- Keep Agent OS planning material out of the TripleQuadUI repo.
- Do not add a queue, acknowledgement/audit workflow, supervisor permission model, or broad history/reporting behavior.
- Do not change hardware alarm semantics.
- Prefer proving existing subscription/current-alert replay before changing service contracts.
- If a proto/client contract change becomes necessary, pause for Coordinator approval before editing generated/shared contract files.
