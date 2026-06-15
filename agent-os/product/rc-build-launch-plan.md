# RC Build Quality And Launch Profile Plan

Coordinator Architect shaping output for BL-013 and BL-014 on 2026-06-11. Keep this planning artifact outside the Bruker Detection `TripleQuadUI.git` repo.

## Scope And Affected Projects

BL-013 affects the main solution build, focused service/UI/data/hardware/algorithm builds, package version files, warning cleanup targets, and an RC warning/vulnerability allowlist.

Likely application files if implementation proceeds:

- `Directory.Packages.props`
- `CommonLibraries/DataService/Directory.Packages.props`
- warning-producing source files in UI, common settings/data, hardware, core service, and DataService areas
- RC allowlist/signoff notes in `agent-os/product/rc-build-quality.md`; do not place RC planning/signoff docs in the TripleQuadUI repo

BL-014 affects developer launch orchestration for:

- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.csproj`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/Properties/launchSettings.json`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.MicroServices.Host/MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.MicroServices.Host/Program.cs`
- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.MicroServices.Host/Properties/launchSettings.json`
- microservice/appsettings files copied or read by the host
- `HardwareLayer/Simulator.App` only if RC needs the simulator UI to be launched by the same profile
- RC launch/runtime notes in `agent-os/product/rc-developer-launch.md`; keep TripleQuadUI repo changes limited to implementation assets such as scripts/config/code

## Architecture Decisions

- Use `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.slnx` as the canonical solution gate.
- Treat package/version files, appsettings, launch settings, service hosts, and proto contracts as high-coordination files. BL-013 and BL-014 should not run as uncoordinated parallel source edits.
- Do not change proto contracts, hardware semantics, simulator behavior, readiness thresholds, swab semantics, data persistence format, or algorithm behavior for these two stories unless a specific blocker is documented and reviewed.
- For BL-013, fix direct/top-level package vulnerabilities where package upgrades are low-risk and validated. Transitive vulnerabilities that require broad framework/Uno/runtime movement should go to the RC allowlist with rationale and Product Owner/Reviewer Integration approval.
- For BL-014, prefer the existing `MrmEtdMassSpecAnalyzer.MicroServices.Host` as the single backend launch unit. It already starts hardware service, core service, and simulator communication service in one process, using ports `7043`, `7042`, and loopback `7044`.
- DataService ownership decision from Brian on 2026-06-11: DataService should be started from `SubstanceAnalyzerCore.Service` because the substance analyzer core service is the only place DataService should be accessed from. Do not make the Uno UI, simulator app, or loose developer launch script access/start DataService directly except as an implementation detail behind the core service boundary.
- The RC launch profile should start backend services before the Uno desktop UI. The exact implementation can be a Visual Studio solution startup profile, a repo script, or both. If only one path is chosen, use a checked-in PowerShell launch script plus documented Visual Studio steps because it is reviewable and can enforce startup/health checks.
- Production posture for RC is documentation only: Windows-only runtime, future microservices hosted as Windows Services, Uno UI operator-launched or kiosk auto-launched, no production installer and no service installation in RC.

## Current Findings

Baseline from `agent-os/product/build-test-baseline.md`:

- UI desktop build passed with 286 warnings.
- Full solution build passed with 885 warnings.
- Focused core, hardware, instrument communication, simulator communication, and DataService tests passed.
- `DataService.Service.IntegrationTests` exits nonzero because all tests are skipped; treat as a reviewed scaffold behavior unless BL-013 chooses to repair the test harness.

Vulnerability scan on 2026-06-11:

- `SharpCompress` moderate advisory appears as direct `0.47.3` in DataService import and transitive `0.30.1` across many app/service projects.
- `Snappier` `1.0.0` high advisory is transitive across many app/service projects.
- `Tmds.DBus.Protocol` `0.21.2` high advisory appears in desktop/Common.OperatingSystem paths.
- `NuGet.Protocol`/`NuGet.Packaging` low advisory appears in DataService tooling and projects that pull NuGet libraries transitively.
- `System.Security.Cryptography.Xml` `8.0.2` and `9.0.0` high advisories appear transitively in several service/data/UI helper paths.

Launch findings:

- Core service listens on `http://*:7042` and its client defaults to `http://localhost:7042`.
- Hardware service listens on `http://*:7043` and its client defaults to `http://localhost:7043`.
- Simulator communication service listens on `http://127.0.0.1:7044`; simulator UI defaults to `http://localhost:7044`.
- Individual `launchSettings.json` files still contain unrelated dynamic ASP.NET launch ports such as `5194`, `5268`, and `5101`; these are not the runtime service client ports.
- `MrmEtdMassSpecAnalyzer.MicroServices.Host/Program.cs` currently has `useSimulator = true` hard-coded and does not start `DataService.Service` directly.
- The microservice host project references core, hardware, real instrument communication, and simulator communication service projects. It does not directly reference `DataService.Service`, though DataService binaries/config appear in prior build output via dependent projects. BL-014 should wire DataService startup behind `SubstanceAnalyzerCore.Service`, not as an independent app-facing launch component.

## Branch And Ownership Plan

Use two branches unless BL-013 discovers that package edits are tiny:

- `feature/rc-build-quality-gate`: owned by Feature Engineer, with Coordinator Architect owning decisions on allowlist/defer scope and Reviewer Integration owning final gate review.
- `feature/rc-single-dev-launch-profile`: owned by Feature Engineer, after BL-013 has at least a stable focused/full build gate.

Recommended worktree layout:

- `C:\Git\Commercial\MrmETDSpec\worktrees\rc-build-quality-gate`
- `C:\Git\Commercial\MrmETDSpec\worktrees\rc-single-dev-launch-profile`

Before branching, verify the source repo state. Current source checkout reports `master...origin/master [ahead 3]` with no local app-file modifications; implementers should confirm those ahead commits are intended baseline before creating feature branches.

File ownership:

- BL-013 owns package files and RC quality docs during its implementation window.
- BL-014 owns launch settings, microservice host program/config, launch script/docs, and simulator app launch docs during its implementation window.
- No other RC story should edit shared package files, appsettings, launch settings, service host startup, proto contracts, or generated code while these are active without Coordinator approval.

Review-ready notification:

- Do not merge to `master`.
- When a branch is ready, notify `#brukerdev` with branch name, summary, validation commands/outcomes, allowlist items or launch smoke evidence, and review focus.

## Implementation Handoff

Feature Engineer for BL-013:

- Run the canonical baseline commands and capture warning/vulnerability output.
- Use `dotnet list "MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.slnx" package --vulnerable --include-transitive` as the vulnerability inventory.
- Try low-risk package updates first in central package files, especially direct DataService entries, then rebuild and run focused tests.
- Reduce warnings where the fix is local and semantics-preserving. Prioritize warnings in shared configuration/data paths, service startup, and nullability warnings near RC workflows.
- Produce an RC allowlist containing package/warning, affected projects, severity, reason deferred, compensating control, and owner/reviewer approval status.
- Update or reference the existing build/test baseline in RC signoff notes.

Feature Engineer for BL-014:

- Decide the concrete one-profile mechanism after testing local startup. Recommended default is a checked-in PowerShell script plus documented Visual Studio multi-startup/profile steps.
- Make backend startup explicit: microservice host first, wait for core/hardware/simulator gRPC health or ports, then launch Uno desktop.
- Ensure DataService is started and accessed through `SubstanceAnalyzerCore.Service` for persistence/history RC paths. Do not launch DataService as a separately documented developer/demo component unless it is strictly internal to core-service startup and health reporting.
- Replace or parameterize hard-coded simulator selection if the launch profile needs real/simulator modes later; for RC, simulator mode can remain the default if documented.
- Document startup order, ports, logs, health expectations, shutdown behavior, and common failure signs.
- Document production posture only; do not implement Windows Services or kiosk lockdown in RC.

Reviewer Integration:

- Review package upgrades for runtime behavior risk, especially Uno, compression/archive, DataService, Python/algorithm, and hardware/service transitive dependencies.
- Confirm allowlist rationale and require Product Owner decision for high-severity deferred vulnerabilities.
- Re-run the validation matrix on a clean checkout/worktree.
- For BL-014, perform a Windows launch smoke test and verify no production-service installation is required.

## Required Validation Matrix

Build-only:

```powershell
dotnet --info
dotnet restore "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx"
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx" --no-restore
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.csproj" -f net10.0-desktop --no-restore
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.MicroServices.Host\MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj" --no-restore
dotnet build "HardwareLayer\Simulator.App\Simulator.App.csproj" --no-restore
```

Focused services/tests:

```powershell
dotnet build "CoreLogicLayer\SubstanceAnalyzerCore.Service\SubstanceAnalyzerCore.Service.csproj" --no-restore
dotnet build "HardwareLayer\TripleQuadHardware.Service\TripleQuadHardware.Service.csproj" --no-restore
dotnet build "CommonLibraries\DataService\DataService.Service\DataService.Service.csproj" --no-restore
dotnet build "CommonLibraries\Algorithms\Algorithms.Python\Algorithms.Python.csproj" --no-restore
dotnet test "Tests\Unit\SubstanceAnalyzerCore.Models.UnitTests\SubstanceAnalyzerCore.Models.UnitTests.csproj" --no-build --logger "console;verbosity=minimal"
dotnet test "Tests\Integration\SubstanceAnalyzerCore.Service.IntegrationTests\SubstanceAnalyzerCore.Service.IntegrationTests.csproj" --no-build --logger "console;verbosity=minimal"
dotnet test "Tests\Integration\TripleQuadHardware.Service.IntegrationTests\TripleQuadHardware.Service.IntegrationTests.csproj" --no-build --logger "console;verbosity=minimal"
dotnet test "Tests\Integration\InstrumentCommunication.Service.IntegrationTests\InstrumentCommunication.Service.IntegrationTests.csproj" --no-build --logger "console;verbosity=minimal"
dotnet test "Tests\Integration\InstrumentCommunication.Service.Sim.IntegrationTests\InstrumentCommunication.Service.Sim.IntegrationTests.csproj" --no-build --logger "console;verbosity=minimal"
dotnet test "CommonLibraries\DataService\DataService.Tests\DataService.Tests.csproj" --no-build --logger "console;verbosity=minimal"
```

Vulnerability gate:

```powershell
dotnet list "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx" package --vulnerable --include-transitive
```

Launch/simulator smoke:

- Start the single RC developer launch profile on Windows.
- Verify backend health/ports for core `7042`, hardware `7043`, and simulator communication `7044`.
- Launch Uno desktop through the profile.
- Launch or connect the simulator UI if required.
- Log in, wake/reach readiness, and run the first simulator-driven RC path far enough to prove services are connected.

Safety-sensitive checks:

- No hardware semantic changes in BL-013/BL-014 without explicit review.
- Simulator validation must be labeled separately from real hardware/manual validation.
- Confirm launch profile uses localhost/loopback only and does not expose development service ports beyond the local machine unless intentionally reviewed.
- Confirm package upgrades do not change scan archive format, algorithm output, service contracts, or instrument communication behavior.
- Confirm DataService access remains behind the substance analyzer core service boundary; UI and simulator paths should not call or launch DataService directly.

## Risks And Rollback

- Package upgrades can change compression/archive behavior, Uno desktop runtime behavior, or DataService tooling. Roll back individual package version edits if focused tests or launch smoke regress.
- High-severity transitive vulnerabilities may require upstream packages or platform movement not appropriate for RC. Allowlist only with rationale and reviewer/Product Owner acceptance.
- Current warning volume is high. BL-013 should reduce meaningful warnings but not chase broad nullability cleanup that risks behavior changes.
- The launch host currently may not start DataService through the core-service boundary. BL-014 must implement or document core-owned DataService startup before declaring the profile RC-ready.
- The current source repo is ahead of `origin/master`; branch creation should confirm whether those commits are the intended baseline.
- If BL-013 and BL-014 collide in appsettings/launch/package files, pause BL-014 source edits until BL-013 package changes are reviewed, then rebase the launch branch.
