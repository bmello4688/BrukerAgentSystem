# TripleQuadUI Backlog

This backlog is local project-planning material for the agent system. Keep it outside the Bruker Detection `TripleQuadUI.git` repo.

## Backlog Rules

- Use feature branches from `master`.
- Brian reviews and manually merges accepted feature branches to `master`.
- Notify the active Discord `#brukerdev` channel when a branch is ready for review.
- Keep hardware/instrument behavior compatible with the legacy DHS-GUI application unless a story explicitly authorizes a change or documents a bug fix for review.
- Use `C:\Git\DHS-GUI` as the legacy behavior reference when rewrite requirements are unclear.
- Use `source\TripleQuadUI\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx` as the primary solution-level build entry point.
- Keep local planning/tooling references out of the Bruker Detection Git repo.
- Treat `ready` backlog items as ready for Coordinator Architect, Domain Analyst, and User Experience triad review, not ready for direct Feature Engineering implementation.
- Coordinator Architect, Domain Analyst, and User Experience decide whether a ready item needs more stories, updated acceptance criteria, domain/SME work, UX clarification, or contract-first planning.
- Send work to Feature Engineering only after the triad marks the item development-ready and the Coordinator Architect has defined branch/worktree ownership and validation expectations.

## Done

### BL-002: Establish Build And Test Baseline

Status: done. Main session completed the build/test baseline on 2026-06-10.

Output: `agent-os/product/build-test-baseline.md`.

Goal: determine which builds and tests are reliable locally before feature delivery begins.

Acceptance criteria:

- Run or document the expected command for `MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx`.
- Identify focused project-level build commands for common UI, service, algorithm, and hardware areas.
- List tests that can run locally without hardware, credentials, internal services, or special licenses.
- Record known blockers and workarounds.

### BL-003: Compare Legacy DHS-GUI Workflows

Status: done. Main session completed the legacy workflow comparison on 2026-06-10.

Output: `agent-os/product/legacy-workflow-comparison.md`.

Goal: identify the legacy workflows that TripleQuadUI must preserve or intentionally improve.

Acceptance criteria:

- Inventory major operator workflows in `C:\Git\DHS-GUI`.
- Map each workflow to the likely TripleQuadUI area or note that it is not yet implemented.
- Call out behavior that appears hardware/instrument-sensitive.
- Create candidate feature stories for gaps, rewrites, and intentional improvements.

### BL-004: Hardware And Simulator Guardrail Document

Status: done. Main session completed the hardware/simulator guardrail document on 2026-06-10.

Output: `agent-os/product/hardware-simulator-guardrails.md`.

Goal: define how feature work should handle hardware, simulator, and instrument behavior.

Acceptance criteria:

- Identify hardware-facing projects, simulator projects, service contracts, and MS workstation integration points.
- Document which changes require explicit owner review.
- Separate simulator validation from real hardware/manual validation.
- Capture failure modes that should be considered for future stories.

### BL-001: Map Solution And Project Boundaries

Status: done. Main session completed the boundary map on 2026-06-10.

Output: `agent-os/product/solution-boundaries.md`.

Goal: document the major solution, project, microservice, common-library, hardware, simulator, and data-service boundaries so future feature work can be scoped safely.

Acceptance criteria:

- Identify main projects under `MrmEtdMassSpecAnalyzer`, `HardwareLayer`, `CoreLogicLayer`, `CommonLibraries`, and `CommonLibraries.Uno`.
- Note which projects are app UI, service hosts, service clients, shared models, data service, algorithms, Python interop, simulator, or hardware-facing.
- Identify high-coordination files such as props, package versions, appsettings, proto contracts, generated code, and launch settings.
- Produce a short local reference document.

### BL-007: Refine Substance Alarm Silence And Clear Controls

Status: done. Brian reported BL-007 complete on 2026-06-08.

Goal: active substance alerts should remain visually unmistakable while giving the operator clear, stable actions for silencing audio and clearing the alert.

Stakeholder/user outcome:

- As an analyzer operator, I need active alarm controls that clearly distinguish silencing audio from clearing the alert, so I can reduce noise without accidentally believing the safety alert has been resolved.
- The safety-critical alarm remains obvious through a persistent red status header instead of flashing translucent controls.

Priority: high usability refinement for the substance-alert workflow. This is not a blocker for the current functional alarm workflow, but should be completed before final UX review/demo of the alarm controls.

Size: 1 point. Localized UI/XAML refinement with simulator validation.

Affected area:

- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/Presentation/Controls/SystemAlarmControl.xaml`
- Review surrounding status header styling in `SystemStatusPanel.xaml` only if contrast or layout regressions are found.

Acceptance criteria:

- Active alarm header remains persistent, red, and non-flashing.
- `Silence Audio` mutes sound but does not clear, hide, or visually downgrade the active alert.
- Muted state clearly communicates that audio is silenced while the alert remains active.
- `Clear Alert` removes the active alert and returns the system to Ready when the backend reports clear.
- Controls have stable layout, clear action labels, keyboard focus visibility, and accessible automation names.
- Simulator demo verifies active alarm, silence, muted-active, clear, return-to-Ready, and ability to trigger a new alarm after clearing.

Implementation guidance:

- Remove the `AlarmOn` visual-state storyboard that animates the whole `SystemAlarmControl` opacity forever.
- Rename the left action from `Alarm` to `Silence Audio`.
- Rename the right action from `Clear` to `Clear Alert`.
- In `AlarmMuted`, show the left control as disabled/status-like text `Audio Silenced`; keep `Clear Alert` enabled.
- If audio is unavailable while an alert is active, use `Audio Unavailable` or `Audio Off`; keep `Clear Alert` enabled.
- Fix `clearAlarmButton` from `Grid.Column="3"` to `Grid.Column="2"` if still present.
- Add automation names such as `AutomationProperties.Name="Silence audible alarm"` and `AutomationProperties.Name="Clear active substance alert"`.
- If motion is retained, limit it to a subtle icon or accent pulse only; do not animate button text or the whole control.

Non-goals:

- No new acknowledgement/audit model.
- No gRPC/proto, service, hardware, algorithm, data, or persistence changes.
- Do not change substance detection, alarm triggering, muting, or clearing semantics beyond labels/states/layout.
- Do not introduce formal `Acknowledge & Clear` wording unless Brian explicitly wants operator acknowledgement modeled later.

Risks and notes:

- Safety-sensitive UI: avoid visuals that imply the alert is resolved when only audio is silenced.
- Current product wording decision: use `Clear Alert`; reserve `Acknowledge & Clear` for a future formal acknowledgement workflow.
- Hardware-sensitive: no hardware behavior change expected.
- Contract-first: no.
- SME-dependent: no, unless implementation uncovers ambiguous alarm semantics.

Validation:

- Run a focused build for the app project, then the solution when practical:
  - `dotnet build MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.csproj -f net10.0-desktop`
  - `dotnet build MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx`
- Run or request simulator validation for active alarm, silence, muted-active, clear, return-to-Ready, and new alarm after clear.

### BL-006: Conference-Check Swab Collection Drives System Status And Workflow UI

Status: done. Brian reported BL-006 complete on 2026-06-08, including prior recall-path and simulator-validation follow-up.

Goal: when the simulator inserts a swab marked as a conference check, TripleQuadUI should relay swab-inserted/system-status messages, drive the collection workflow UI/progress state, and persist the resulting sample/scan series so it can be recalled later.

Current observed behavior:

- First application startup appears to start procedure flow and enter sleep mode correctly.
- Login wakes the app/instrument and the ready/calibration flow begins.
- Calibration verification requires a conference check.
- Simulator data appears under the Uno UI collection/substance-training area.
- Swab inserted messages are not being relayed into system status.
- The expected collection workflow is not triggering: progress bar, timing/scan progress, and operator feedback are missing or stale.
- End result should be collected sample data stored in the scan series repository/database and recallable later.

Likely references:

- Current app: `C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI`
- Legacy/simulator reference: `C:\Git\DHS-GUI`
- Simulator: DHS-GUI Compound Analyzer 2 simulator connected to the instrument service.

Acceptance criteria:

- Conference-check swab insertion from the simulator is detected by the instrument/status pipeline.
- System status relays the swab inserted and collection-state messages expected by the operator workflow.
- Uno UI collection/substance-training views transition into sample collection when the conference-check swab is inserted.
- Collection progress, elapsed/remaining timing, and scan/progress indicators update during simulated collection.
- Completed sample is saved to the scan series repository/database.
- Saved scan series/sample can be recalled later.
- Simulator validation path is documented separately from real-instrument validation.

Risks and notes:

- Hardware/instrument behavior is sensitive and should preserve DHS-GUI-compatible semantics unless a bug is found.
- Domain Analyst should compare the DHS-GUI workflow before implementation.
- Coordinator Architect should identify whether the issue is in instrument service messaging, status propagation, UI state binding, collection workflow orchestration, or persistence.
- Reviewer Integration should verify no local tooling references enter the Bruker repo.

## Ready To Shape

### BL-013: RC Build Quality Gate And Warning/Vulnerability Allowlist

Status: done. Brian approved the warning/vulnerability allowlist on 2026-06-11, and the BL-013 branch set was fast-forward merged to local `master` in the parent repo plus nested DataService and Algorithms/Common repos. RC quality evidence is documented in `agent-os/product/rc-build-quality.md`; Coordinator Architect shaping output is `agent-os/product/rc-build-launch-plan.md`.

Goal: RC validation should prove the solution builds and tests reliably while cleaning warnings/vulnerabilities where reasonable and explicitly allowlisting anything deferred.

Priority/order: RC-1. This gates all RC implementation work.

Size: 5 points. Cross-solution quality work with package and warning review risk.

Affected areas: solution build, focused tests, package references, warning-producing projects, local RC validation docs.

Acceptance criteria:

- Focused builds and the full solution build pass.
- Relevant focused tests pass or have reviewed blockers.
- Package vulnerability warnings are fixed where reasonable.
- Compiler/analyzer warnings are reduced where reasonable.
- Remaining warnings/vulnerabilities are captured in a reviewed RC allowlist with rationale.
- Existing build/test baseline is updated or referenced by the RC signoff notes.

Non-goals:

- No broad architecture cleanup unrelated to RC quality.
- No dependency upgrades that change runtime behavior without Reviewer Integration and Coordinator approval.

Validation: canonical build/test commands from `agent-os/product/build-test-baseline.md`, plus reviewer approval of the allowlist.

Roles: Coordinator Architect, Feature Engineer, Reviewer Integration, Product Owner for defer/allowlist decisions.

### BL-014: RC Single Developer Launch Profile And Runtime Posture

Status: done. Brian approved merge on 2026-06-11; `feature/rc-single-dev-launch-profile` was fast-forward merged into local `master` at commit `d716ddc`. Branch diff contained `scripts/launch-rc-dev.ps1` plus `.cmd` wrappers for tracked parent-repo PowerShell scripts; focused backend/UI builds, PowerShell backend-only launch smoke, and cmd-wrapper backend-only launch smoke passed. Full simulator UI demo remains a downstream RC signoff item. Coordinator Architect shaping output: `agent-os/product/rc-build-launch-plan.md`.

Goal: RC should launch through one developer/demo profile that starts the Uno UI, required microservices, and simulator dependencies; production Windows Service posture is documented but not implemented for RC.

Priority/order: RC-2. Needed before reliable live simulator signoff.

Size: 5 points. Cross-service launch orchestration with configuration risk.

Affected areas: UI host, microservice hosts, simulator service/app, launch settings, appsettings, service startup order, health/log visibility.

Acceptance criteria:

- A single developer launch profile starts all RC-required local components.
- Startup order and service health expectations are documented.
- The profile supports the RC demo path without manual service hunting.
- Production posture documents Windows-only runtime, future Windows Services, and operator/kiosk UI launch assumptions.
- E2E test/demo dependencies are clear and do not require production service installation.

Non-goals:

- No production installer.
- No installable Windows Services for RC.
- No kiosk lockdown implementation.
- No Linux support.

Validation: local Windows launch smoke test through the profile, then the RC simulator demo path.

Roles: Coordinator Architect, Feature Engineer, Reviewer Integration.

### BL-015: RC Algorithm And Embedded Python Proof

Status: done. Completed on 2026-06-11 after BL-016A removed the shared simulator/core `WaitingForSwabRemoval` blocker. Focused algorithm/Python builds passed; BL-016A service E2E passed `MicroServicesHarnessTests` `6/6` and proved persisted confidence-check sample reanalysis with `IsConfidenceCheck=true`, `PassedConfidenceCheck=true`, and `DetectionResultOverview="Confidence Check: Passed"`. Fixture proof is deferred because simulator-driven E2E now provides RC proof; SME parity remains a BL-019 final signoff input. Evidence and routing notes are in `agent-os/product/rc-algorithm-python-proof.md`.

Goal: RC needs confidence that algorithms and embedded Python work and are testable, including evidence comparable to the other application where practical.

Priority/order: RC-3. Can run in parallel with launch/history work if source ownership is separate.

Size: 5 points, potentially 8 if Python packaging/runtime blockers require code fixes.

Affected areas: algorithm projects, Python interop, fixtures/data files, simulator detection path, tests, algorithm parity evidence.

Acceptance criteria:

- Existing unit/integration tests prove algorithm invocation or new focused tests are added.
- A known fixture/data file produces expected substance results, or a reviewed blocker is documented.
- A simulator-driven sample produces expected detection output in the UI, or a reviewed blocker is documented.
- SME/manual parity review against the other application is completed or explicitly scheduled before RC signoff.
- Python/algorithm validation failures are visible and do not silently degrade detection workflows.

Non-goals:

- No model retraining.
- No algorithm behavior change unless explicitly reviewed.
- No unsupported package/version upgrades.

Validation: focused algorithm/Python build/tests, fixture test, simulator detection output, SME/manual review evidence.

Roles: Domain Analyst, Feature Engineer, Reviewer Integration, Bruker SME, Product Owner for proof tradeoffs.

### BL-016: RC Collection, Readiness, Fault Recovery, And Persistence Workflow

Status: split by triad review on 2026-06-11. BL-016A is done: Reviewer Integration approved committed branch `feature/rc-confidence-check-recovery-persistence` at `01c5e2d`, and the approved changes were fast-forwarded into local `source/TripleQuadUI` `master` for owner review. BL-016B is done: Reviewer Integration approved `feature/rc-normal-collection-readiness-persistence` at `8b386f8`, and the approved changes were fast-forwarded into local `source/TripleQuadUI` `master` for owner review. BL-016C remains queued as the remaining follow-up slice. Split plan and handoff details are in `agent-os/product/rc-collection-readiness-recovery-plan.md`.

Goal: RC must demonstrate login, wake/readiness, confidence-check and normal sample collection, fault/not-ready/recovery paths, persistence, and recallability through simulator validation.

Priority/order: RC-4. Depends on BL-014 enough to run the workflow and BL-015 enough to validate detection output.

Size: 8 points. Cross UI, service, simulator, persistence, and status workflow.

Affected areas: login/access gating, system status/readiness, sample collection UI/service, simulator swab/fault paths, persistence/repository, archived recall integration.

Acceptance criteria:

- Login gates access to the RC workflow.
- System wakes and reaches readiness through the simulator path.
- Confidence-check swab drives collection progress and persists completed sample data.
- Normal non-confidence sample collection completes and persists sample data.
- Fault/not-ready/recovery paths show clear operator status and recover to a usable state.
- Persisted samples from the RC simulator flow can be recalled.
- Simulator validation is labeled separately from later hardware/manual validation.

Domain/UX triad decisions:

- Split BL-016 into three implementation slices: BL-016A confidence-check recovery/persistence unblock, BL-016B normal collection/readiness/persistence, and BL-016C fault recovery plus minimal recall validation.
- Treat `WaitingForSwabRemoval` as the first blocker slice. If simulator removal succeeds but the core/UI remains in `WaitingForSwabRemoval`, BL-016 is not development-complete unless the workflow transitions to a clear recoverable fault state with next action.
- Preserve DHS-GUI semantics where possible, but allow UX to improve clarity: top-level verification can remain `Verify calibration`, while substatus/action text should say what the operator can do next, such as insert confidence-check swab, collecting sample, remove swab, failed calibration, or retry confidence check.
- Minimal recall belongs in BL-016 only to prove that just-created simulator samples are persisted, selectable, graph-loadable, and reanalyzable. Broad history, clear, export, archive migration, and filtering polish remain BL-018 scope.
- Simulator evidence must be labeled simulator-only RC validation; hardware/manual validation remains separate and post-RC.

UX evidence criteria from triad review:

- Login visibly gates the RC workflow before operator access.
- Wake/readiness shows clear status progression: connecting/waking, waiting for instrument, verify calibration/confidence check required, ready.
- Confidence-check and normal collection both show insert swab, baseline progress, analysis progress, cleardown/analyzing, remove swab, completion, and return to a usable state.
- Confidence-check pass/fail is visible to the operator/reviewer, not only in service logs.
- Fault/not-ready/recovery states show cause and next action, especially failed calibration and confidence-check retry.
- Completed simulator samples are visibly persisted with metadata, confidence-check flag where applicable, detection output, and scan data.
- Minimal recall is included: a just-created simulator sample can be selected/recalled/re-analyzed enough to prove persistence.
- Simulator validation is explicitly labeled simulator-only RC validation; hardware/manual validation remains post-RC.
- Broad history clear/export remains BL-018 scope.

Development slices:

- BL-016A: done. Confidence-check post-analysis swab removal, recovery, and persistence unblock passed Reviewer Integration validation on branch `feature/rc-confidence-check-recovery-persistence` at `01c5e2d`.
- BL-016B: done. Login/readiness plus normal non-confidence sample collection and persistence passed Reviewer Integration on branch `feature/rc-normal-collection-readiness-persistence` at `8b386f8`, then fast-forward merged into local `master`.
- BL-016C: released to Feature Engineering after BL-016B merge. Fault/not-ready/recovery states plus minimal recall/reanalysis proof for simulator-created samples. Recommended branch/worktree: `feature/rc-fault-recovery-minimal-recall` / `C:\Git\Commercial\MrmETDSpec\worktrees\rc-fault-recovery-minimal-recall`.

Non-goals:

- No real hardware signoff for RC.
- No migrated legacy archive recall.
- No unrelated maintenance/device/desorber UI.

Validation: live simulator workflow plus focused core/hardware/DataService tests.

Roles: Coordinator Architect, Domain Analyst, and User Experience for triad review; Feature Engineer only after development-ready handoff; Reviewer Integration for validation/review.

### BL-017: RC Alarm Resilience And Consolidated Alert Workflow

Status: review-fix validation. Started triad shaping on 2026-06-15; Coordinator Architect, User Experience, Domain Analyst, and Product Owner input incorporated on 2026-06-15. Initial implementation reached Reviewer Integration no-go at `4d685ed` because confidence-check pass/fail UI semantics still depended on `HasDetectedSubstance`. Follow-up now adds explicit expected-confidence-check alert semantics per Product Owner guidance. Shaping output and handoff are in `agent-os/product/rc-alarm-resilience-plan.md`.

Goal: RC alarm handling must remain clear and resilient across navigation, restart/reconnect, repeated detections, and multiple-substance detections consolidated into one alarm.

Priority/order: RC-5. Builds on completed BL-007 and depends on simulator/algorithm paths for triggering.

Size: 5 points. Safety-sensitive UI/service state workflow.

Affected areas: alarm/status UI, app model/state hydration, core service alert state, audible alarm state, simulator detection path.

Acceptance criteria:

- Alarm triggers and displays detected substance information.
- Silence audio does not clear, hide, or visually downgrade the active alert.
- Clear alert returns system to Ready when backend state is clear.
- Alarm persists across navigation/page changes.
- Alarm survives service/UI restart or reconnect where practical for RC.
- Repeated or multiple-substance detections consolidate into one alarm for RC.
- Inserting a new swab for the next sample may auto-clear the prior live substance alarm; the transition must be understandable to the operator, and the system must continue collecting/persisting the new sample rather than discarding it because of alarm-clear timing.

Non-goals:

- No new formal acknowledgement/audit model.
- No separate multi-alarm queue for RC.
- No hardware alarm semantics change.

Validation: simulator alarm demo, restart/reconnect smoke where practical, focused UI/service tests if available.

Roles: User Experience, Feature Engineer, Reviewer Integration, Domain Analyst if semantics are unclear.

Current shaping notes:

- BL-007 alarm-control wording/layout appears already present.
- Product Owner decision on 2026-06-15: preserve legacy-compatible new-swab auto-clear. Operators cannot be prevented from inserting the next swab, and the product should not throw away samples because of alarm-clear timing.
- Product Owner decision on 2026-06-15 10:53 EDT: alert payloads should distinguish whether the sample was expected to be a confidence check. Expected confidence checks should not raise alarms for `Passed`/`Success`; they should alarm only when the confidence check fails.
- Triad restart/reconnect target: navigation/model resubscription plus UI restart/reconnect to the same running core service. Core service process restart persistence is out of RC unless Product Owner explicitly approves durable alert rehydration.
- Development handoff: one branch/worktree, `feature/rc-alarm-resilience-consolidated-alert` / `C:\Git\Commercial\MrmETDSpec\worktrees\rc-alarm-resilience-consolidated-alert`, from source `master` at `10d322a`.

### BL-018: RC History Recall, Clear, And Local Export

Status: ready to shape. Created from the 2026-06-10 RC interview.

Goal: RC must recall simulator-created scans and support clear/export history operations for logged-in operators.

Priority/order: RC-6. Depends on BL-016 persistence enough to create recallable data.

Size: 8 points. Data-service/repository plus UI workflow with destructive operations.

Affected areas: history/archived recall UI, scan repository/database, DataService clients/service, export path, clear-history commands, confirmation/error states.

Acceptance criteria:

- Recall scans created in the current TripleQuadUI simulator flow.
- Clear selected scan/sample.
- Clear all history before a selected date.
- Clear all history.
- Export selected or scoped history to a local folder.
- Logged-in operator can perform clear/export for RC.
- UI clearly distinguishes destructive actions and supports cancel/confirmation/error states.

Non-goals:

- No legacy DHS-GUI archive import/recall.
- No deployed legacy archive location support.
- No USB/removable drive requirement.
- No report generation.
- Supervisor-only permissions are deferred until user management exists.

Validation: DataService/repository tests, UI smoke for destructive flows, live simulator-created data demo.

Roles: Product Owner, Domain Analyst, User Experience, Coordinator Architect, Feature Engineer, Reviewer Integration.

### BL-019: RC Live Simulator Demo And Signoff Checklist

Status: ready to shape. Created from the 2026-06-10 RC interview.

Goal: RC signoff is a live simulator demo backed by enough validation evidence for Brian and Reviewer Integration to accept the candidate.

Priority/order: RC-7. Final release-candidate assembly story after RC-1 through RC-6 are ready.

Size: 3 points. Coordination and validation evidence.

Affected areas: RC demo script, validation notes, logs/screenshots where useful, status board handoff, backlog closure notes.

Acceptance criteria:

- Live simulator demo covers the minimum path in `agent-os/product/release-candidate-scope.md`.
- Build/test, warning/vulnerability allowlist, launch profile, algorithm proof, collection/alarm/history evidence are linked or summarized.
- Hardware/manual validation is explicitly marked post-RC.
- Remaining non-RC legacy gaps are parked.
- Branches/worktrees and validation commands are listed for Reviewer Integration.

Non-goals:

- No new feature implementation unless a demo blocker is found and separately scoped.

Validation: live simulator demo plus Reviewer Integration go/no-go.

Roles: Product Owner, Coordinator Architect, Reviewer Integration, Feature Engineers for any assigned branch evidence.

### BL-005: First Feature Candidate Interview

Goal: turn Brian's highest-priority application need into the first implementation-ready feature spec.

Acceptance criteria:

- Capture the user/operator goal.
- Identify affected UI, service, data, algorithm, hardware, and legacy-reference areas.
- Define acceptance criteria, non-goals, validation plan, and review focus.
- Decide whether Product Owner, Domain Analyst, User Experience, Coordinator Architect, Feature Engineer, and Reviewer Integration all need to participate.

### BL-008: Make Build Reliability The First Packaging And Deployment Gate

Status: ready to shape. Created from Brian's parking-lot interview answers on 2026-06-10.

Stakeholder goal and product outcome: developers and release owners need a repeatable Windows build baseline before packaging work expands, so implementation agents can validate changes consistently and avoid chasing environment noise.

Priority/order: 1 after BL-002 evidence is finalized. This should precede deeper packaging/deployment work.

Size: 3 points. Cross-project build documentation and validation, likely no product code unless the baseline exposes small fixes.

Affected areas:

- `MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx`
- Solution build props, package versions, appsettings, launch settings, test projects, and CI/local build documentation if present.

Acceptance criteria:

- Define the canonical Windows build command for the solution and at least one focused command for UI, service, algorithm/Python, data, and hardware/simulator areas.
- Record required SDK, Visual Studio workload, and local dependency assumptions.
- Identify failing or flaky projects/tests with owner-visible blockers and workarounds.
- Produce a short "build reliability gate" that future stories can cite before claiming validation.
- Update backlog/status-board references without adding local agent planning files to the Bruker repo.

Non-goals:

- No installer, release pipeline, or Windows Service packaging implementation.
- No Linux compatibility work.
- No broad dependency upgrades unless required to prove the build baseline and approved by Coordinator/Reviewer.

Validation approach:

- Run the canonical solution build on Windows.
- Run focused project builds/tests where available.
- Reviewer Integration verifies commands are reproducible or documents environment blockers.

Roles:

- Coordinator Architect, Feature Engineer, Reviewer Integration.
- Product Owner remains available for priority tradeoffs.

### BL-009: Define Windows-Only Runtime And Launch Profiles

Status: ready to shape. Created from Brian's parking-lot interview answers on 2026-06-10.

Stakeholder goal and product outcome: developers need a convenient one-profile local launch path for UI E2E testing, while production remains Windows-only with microservices running as Windows Services and the Uno UI operator-launched or kiosk auto-launched.

Priority/order: 2 after BL-008 and BL-002. Contract-first planning should come before implementation because launch settings, service hosting, and E2E assumptions cross project boundaries.

Size: 5 points if implemented; 2 points for contract/planning only.

Affected areas:

- UI host, microservice hosts, launch profiles, appsettings, Windows Service hosting configuration, E2E test harness, kiosk/auto-launch documentation.

Acceptance criteria:

- Document Windows as the only supported runtime target for now.
- Define the developer E2E launch profile behavior: starts the Uno UI and all required local microservices with appropriate simulator/local dependencies.
- Define production deployment behavior: microservices run as Windows Services; Uno UI is launched by the operator or auto-launched in kiosk mode as the only app on the machine.
- Identify shared settings, ports, service dependencies, startup ordering, logs, and health checks required by the profile.
- Split any code work into separate implementation stories if service-hosting or launch-profile changes are non-trivial.

Non-goals:

- No Linux support.
- No production installer or fleet-management implementation.
- No real kiosk lockdown implementation unless Brian explicitly prioritizes it.
- No hardware behavior changes.

Validation approach:

- Local Windows developer launch smoke test once implementation exists.
- Service startup order and health-check verification with simulator/local dependencies.
- Manual review of production assumptions by Coordinator Architect and Reviewer Integration.

Roles:

- Product Owner, Coordinator Architect, Feature Engineer, Reviewer Integration.
- User Experience only if kiosk/operator launch behavior affects visible UI states.

### BL-010: Treat Embedded Python As Product-Critical Algorithm And ML Infrastructure

Status: ready to shape. Created from Brian's parking-lot interview answers on 2026-06-10.

Stakeholder goal and product outcome: algorithm and machine-learning capability depends on embedded Python being reliable, versioned, testable, and deployable rather than incidental scaffolding.

Priority/order: 3 after build reliability is understood. Can run in parallel with data-history discovery if source ownership is separate.

Size: 5 points for discovery plus guardrails; likely 8+ if packaging/runtime changes are included.

Affected areas:

- Python interop projects, algorithm projects, `Python.Included` usage, ML model/resource loading, packaging/runtime dependencies, tests around Python-backed algorithms.

Acceptance criteria:

- Inventory current embedded Python entry points, package/version assumptions, model/resource paths, and failure modes.
- Define what must be validated for Python-backed algorithms before a feature branch is review-ready.
- Identify offline/deployment requirements for embedded Python and ML resources.
- Mark which Python/algorithm changes require Domain Analyst, SME, or owner review.
- Produce follow-up implementation stories for any reliability gaps found.

Non-goals:

- No algorithm behavior changes.
- No model retraining or ML accuracy claims.
- No package/version upgrades without a specific reliability reason and review.

Validation approach:

- Run existing Python/algorithm tests where available.
- Add or propose a smoke-test path for Python initialization and representative algorithm invocation.
- Reviewer Integration checks that failures are visible and do not silently degrade detection workflows.

Roles:

- Domain Analyst, Coordinator Architect, Feature Engineer, Reviewer Integration.
- Bruker SME required for algorithm correctness or ML model behavior changes.

### BL-011: Restore Archived Scan Recall As The First Data-History Workflow

Status: ready to shape. Created from Brian's parking-lot interview answers on 2026-06-10.

Stakeholder goal and product outcome: operators need to recall archived scans so previously collected sample data remains usable for review and workflow continuity.

Priority/order: 4 and highest among data/history work. Should follow BL-003 legacy comparison enough to confirm expected DHS-GUI behavior.

Size: 5 points. UI plus data/service workflow with persistence risk.

Affected areas:

- Scan series repository/database, archived scan query/retrieval path, collection/substance-training UI, data-service/client contracts, legacy DHS-GUI recall behavior.

Acceptance criteria:

- Compare DHS-GUI archived-scan recall behavior and identify expected operator path.
- List archived scan metadata required for search/selection and recall.
- Recall a saved scan series/sample into the appropriate UI workflow without corrupting active collection state.
- Handle missing, invalid, or unavailable archived data with clear operator feedback.
- Preserve separation between simulator validation and real-instrument/manual validation.

Non-goals:

- No report generation.
- No clearing/exporting history in this story.
- No changes to raw detection algorithms or hardware collection behavior.

Validation approach:

- Seed or create representative saved scan data through simulator/local data path.
- Verify recall from persisted storage into UI.
- Run focused data-service/repository tests plus UI smoke validation where possible.

Roles:

- Product Owner, Domain Analyst, User Experience, Coordinator Architect, Feature Engineer, Reviewer Integration.
- Bruker SME if legacy recall semantics or regulatory expectations are unclear.

### BL-012: Add Clear-History And Export-History Data Operations

Status: ready to shape. Created from Brian's parking-lot interview answers on 2026-06-10.

Stakeholder goal and product outcome: operators or support users need controlled ways to clear local scan history and export history for external analysis/support, after archived recall is stable.

Priority/order: 5 after BL-011. Export may be split from clear-history if data ownership, permissions, or audit behavior are uncertain.

Size: 5 points for both operations if contracts are clear; split into two 3-point stories if implementation paths diverge.

Affected areas:

- Data/history UI, scan series repository/database, export format/target, file picker or service API, operator permissions/confirmation flow, legacy DHS-GUI behavior.

Acceptance criteria:

- Define who can clear history and what confirmation is required.
- Clear selected or all local history according to the agreed scope without affecting active scans.
- Export selected history with sufficient metadata and data files for the intended support/review workflow.
- Show success/failure states and preserve operator clarity around irreversible actions.
- Log or surface errors without exposing sensitive local paths unnecessarily.

Non-goals:

- No report generation.
- No cloud upload, email, or external transfer automation.
- No broad archive schema redesign unless required and approved.
- No hardware or algorithm behavior changes.

Validation approach:

- Repository/data-service tests for delete/export behavior.
- UI smoke validation for confirmation, cancellation, success, and error paths.
- Manual review of exported artifact contents and sensitive-data exposure.

Roles:

- Product Owner, Domain Analyst, User Experience, Coordinator Architect, Feature Engineer, Reviewer Integration.
- Bruker SME if deletion/export retention expectations are regulated or customer-specific.

## Parking Lot

- Report generation remains parked and lowest priority until Brian confirms product need.
