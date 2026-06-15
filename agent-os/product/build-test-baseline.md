# TripleQuadUI Build And Test Baseline

This is the BL-002 local reference. It records the Windows build/test baseline discovered on 2026-06-10. Keep this file outside the Bruker Detection Git repo.

## Environment

- OS: Windows 10.0.22631 x64.
- Primary SDK observed: .NET SDK `10.0.202`.
- Additional SDKs installed: `6.0.402`, `7.0.200`, `8.0.101`, `9.0.100`, `9.0.203`.
- Installed workloads include Android, iOS, MAUI, MAUI Windows, tvOS, and wasm tools.
- Repo `global.json` pins Uno SDK `6.4.31` and does not pin a .NET SDK version.
- Root central build files: `global.json`, `Directory.Build.props`, `Directory.Build.targets`, `Directory.Packages.props`.
- DataService also has `CommonLibraries/DataService/Directory.Packages.props`.

## Canonical Commands

Run from `C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI`.

```powershell
dotnet --info
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx" --no-restore
```

Focused build commands:

```powershell
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.csproj" -f net10.0-desktop --no-restore
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.MicroServices.Host\MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj" --no-restore
dotnet build "CoreLogicLayer\SubstanceAnalyzerCore.Service\SubstanceAnalyzerCore.Service.csproj" --no-restore
dotnet build "HardwareLayer\TripleQuadHardware.Service\TripleQuadHardware.Service.csproj" --no-restore
dotnet build "HardwareLayer\Simulator.App\Simulator.App.csproj" --no-restore
dotnet build "CommonLibraries\DataService\DataService.Service\DataService.Service.csproj" --no-restore
dotnet build "CommonLibraries\Algorithms\Algorithms.Python\Algorithms.Python.csproj" --no-restore
```

Focused tests that ran locally:

```powershell
dotnet test "Tests\Unit\SubstanceAnalyzerCore.Models.UnitTests\SubstanceAnalyzerCore.Models.UnitTests.csproj" --no-build --logger "console;verbosity=minimal"
dotnet test "Tests\Integration\SubstanceAnalyzerCore.Service.IntegrationTests\SubstanceAnalyzerCore.Service.IntegrationTests.csproj" --no-build --logger "console;verbosity=minimal"
dotnet test "Tests\Integration\TripleQuadHardware.Service.IntegrationTests\TripleQuadHardware.Service.IntegrationTests.csproj" --no-build --logger "console;verbosity=minimal"
dotnet test "Tests\Integration\InstrumentCommunication.Service.IntegrationTests\InstrumentCommunication.Service.IntegrationTests.csproj" --no-build --logger "console;verbosity=minimal"
dotnet test "Tests\Integration\InstrumentCommunication.Service.Sim.IntegrationTests\InstrumentCommunication.Service.Sim.IntegrationTests.csproj" --no-build --logger "console;verbosity=minimal"
dotnet test "CommonLibraries\DataService\DataService.Tests\DataService.Tests.csproj" --no-build --logger "console;verbosity=minimal"
```

## Observed Results

- UI desktop build passed: `286 Warning(s)`, `0 Error(s)`.
- Full solution build passed: `885 Warning(s)`, `0 Error(s)`.
- `SubstanceAnalyzerCore.Models.UnitTests`: passed, 1 total.
- `SubstanceAnalyzerCore.Service.IntegrationTests`: passed, 6 total.
- `TripleQuadHardware.Service.IntegrationTests`: passed, 6 total.
- `InstrumentCommunication.Service.IntegrationTests`: passed, 1 total.
- `InstrumentCommunication.Service.Sim.IntegrationTests`: passed, 1 total.
- `DataService.Tests`: passed, 113 total.
- `DataService.Service.IntegrationTests`: process exited nonzero because zero tests ran; the single `ScaffoldExists` test is skipped. Treat this as a scaffold/test-runner behavior, not an implementation failure.

## Known Warnings And Blockers

- Package vulnerability warnings observed for `SharpCompress`, `Snappier`, `Tmds.DBus.Protocol`, and `NuGet.Protocol` through transitive or direct package references.
- Many nullability warnings exist in common settings, common data, hardware, common operating system, UI, and core service code.
- Standalone `CommonLibraries/Algorithms/Algorithms.sln` is not reliable as a baseline:
  - Missing `CommonLibraries/Algorithms/pythonnet/src/runtime/Python.Runtime.csproj`.
  - `Python.Included/Python.Deployment` fails with invalid nullable value for C# 7.3.
- Algorithm projects included by the main solution can build through the main `.slnx`; do not use the standalone Algorithms solution as the first validation gate until BL-010 addresses Python/algorithm reliability.
- E2E tests should not be treated as routine local baseline yet; they require UI/service/simulator orchestration and belong with BL-009 launch-profile work.

## Build Reliability Gate

For a normal feature branch, claim local validation only after:

- The relevant focused project build passes.
- The main solution build passes when the change touches shared models, contracts, packages, service hosts, or cross-layer behavior.
- Relevant focused tests pass, or the story documents why a test area is not applicable.
- Simulator validation is clearly labeled separately from real hardware/manual validation.
- Existing warnings are not worsened unless the reviewer explicitly accepts the tradeoff.

## Follow-Up Stories

- BL-008 should use this baseline as the starting point for a more formal build reliability gate.
- BL-009 should define the dev UI E2E launch profile before E2E is required as a routine validation step.
- BL-010 should resolve or document Python/algorithm build and smoke-test expectations.
