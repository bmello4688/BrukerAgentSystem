# RC Build Quality Gate

This note captures the BL-013 release-candidate build quality gate: focused package cleanup, warning cleanup, remaining vulnerability/warning allowlist, and validation commands.

## Package Changes

The following direct vulnerable packages were updated in `CommonLibraries/DataService/Directory.Packages.props`:

| Package | Previous | Updated | Reason |
| --- | --- | --- | --- |
| `NuGet.Protocol` | `7.3.0` | `7.6.0` | Removes the direct low-severity NuGet advisory from `DataService.GrpcCodeFirstClient`. |
| `SharpCompress` | `0.47.3` | `0.49.1` | Removes the direct moderate `SharpCompress` advisory from `DataService.Import`. |

No broad Uno, platform, runtime, simulator, hardware, algorithm, or service-host package moves were made for this gate.

## Warning Cleanup

The duplicated settings validator attributes in `CommonLibraries.Uno/Common.Settings` and `CommonLibraries/Algorithms/Common/Common.Data` now use nullable-compatible `ValidationAttribute.IsValid(object? value)` overrides and nullable caller-member names. This removes the local validator nullability warnings without changing validation behavior.

## Vulnerability Allowlist

Approval status: Brian approved the deferred warning/vulnerability allowlist and BL-013 merge on 2026-06-11.

| Package/advisory | Affected projects | Severity | Reason deferred | Compensating control | Approval status |
| --- | --- | --- | --- | --- | --- |
| `SharpCompress` `0.30.1` / GHSA-6c8g-7p36-r338 | UI, core service, hardware service/client, simulator, algorithm/data projects, DataService transitive paths | Moderate | Remaining exposure is transitive through upstream packages. Forcing a solution-wide transitive override or broad parent-package movement risks compression/archive and runtime behavior during RC. | Direct DataService `SharpCompress` was updated. Keep archive/import paths under focused DataService tests and RC simulator validation. | Approved by Brian, 2026-06-11 |
| `Snappier` `1.0.0` / GHSA-pggp-6c3x-2xmx | UI, core service, hardware service/client, simulator, algorithm/data projects, DataService transitive paths | High | Transitive dependency tied to the same compression/archive graph. A broad override needs integration review because scan archive/import behavior is RC-critical. | No direct `Snappier` use was found in source. Keep data import/export and simulator-created scan validation in the RC gate. | Approved by Brian, 2026-06-11 |
| `Tmds.DBus.Protocol` `0.21.2` / GHSA-xrw6-gwf8-vvr9 | `MrmEtdMassSpecAnalyzer` desktop target and `Common.OperatingSystem` desktop target | High | Comes through platform/runtime dependencies. Updating the Uno/platform stack is outside BL-013's low-risk RC scope. | RC runtime is Windows-only. DBus is not part of the Windows operator path; verify desktop launch on Windows in BL-014. | Approved by Brian, 2026-06-11 |
| `NuGet.Protocol`/`NuGet.Packaging` `6.12.1` / GHSA-g4vj-cjjj-v7hg | Microservice host, core service, DataService service/clients/tests, proto tooling paths | Low | Remaining instances are transitive through tooling/build-time dependencies after the direct `NuGet.Protocol` reference was updated. | Direct code-first client package was updated. Treat remaining low-severity toolchain exposure as deferred unless Reviewer Integration identifies a safe parent update. | Approved by Brian, 2026-06-11 |
| `System.Security.Cryptography.Xml` `8.0.2`/`9.0.0` / GHSA-37gx-xxp4-5rgx and GHSA-w3x6-4m5h-cxqf | Microservice host, core service, DataService service/clients/tests, algorithm UI/common UI paths | High | Transitive dependency. Forcing XML crypto versions across services/UI requires integration review because it changes security library binding across multiple app layers. | No direct XML crypto use was found in BL-013 changes. Keep service/data tests in the RC gate and revisit with Reviewer Integration if binding overrides are acceptable. | Approved by Brian, 2026-06-11 |

## Warning Allowlist

Remaining compiler warnings are mostly pre-existing nullability warnings in larger model/import/service areas. They are deferred because broad nullability cleanup in scan models, import transforms, hardware/service state, and UI view models can alter runtime assumptions during RC.

| Warning area | Affected projects | Reason deferred | Approval status |
| --- | --- | --- | --- |
| Data import nullability | `DataService.Import` | Import transform code is large and data-shape-sensitive; fix only with targeted import/export tests. | Approved by Brian, 2026-06-11 |
| Scan/data model initialization nullability | `Common.Data`, `DataService.Models`, algorithm/data dependents | Models are serialized/deserialized across persistence and algorithm paths; broad annotation changes need data compatibility review. | Approved by Brian, 2026-06-11 |
| Core service collection/alarm nullability and unused members | `SubstanceAnalyzerCore.Service` | Touches RC workflow state and alarm/collection behavior; defer to workflow stories unless a specific defect is found. | Approved by Brian, 2026-06-11 |
| UI view-model and generated/Uno warnings | `MrmEtdMassSpecAnalyzer`, algorithm UI/common UI | Broad UI warning cleanup is outside BL-013 and may overlap BL-014/RC workflow validation. | Approved by Brian, 2026-06-11 |

## Validation Evidence

Commands run from repository root:

```powershell
dotnet --info
dotnet restore "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx"
dotnet list "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx" package --vulnerable --include-transitive
dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx" --no-restore
dotnet build "CommonLibraries.Uno\Common.Settings\Common.Settings.csproj" --no-restore
dotnet build "CommonLibraries\Algorithms\Common\Common.Data\Common.Data.csproj" --no-restore
dotnet build "CommonLibraries\DataService\DataService.Service\DataService.Service.csproj" --no-restore
dotnet build "CommonLibraries\DataService\DataService.Import\DataService.Import.csproj" --no-restore
```

Observed results on 2026-06-11:

- .NET SDK `10.0.202` on Windows `10.0.22631`.
- Restore passed; direct `NuGet.Protocol` and direct `SharpCompress` vulnerability warnings were removed after package updates.
- Full solution build before BL-013 edits passed with `1062 Warning(s)`, `0 Error(s)`.
- Full solution build after BL-013 edits passed with `641 Warning(s)`, `0 Error(s)`.
- Focused `Common.Settings`, `Common.Data`, and `DataService.Service` builds passed with `0 Warning(s)`, `0 Error(s)` after cleanup.
- Focused `DataService.Import` build passed with existing nullability warnings and `0 Error(s)`.
- Focused tests passed:
  - `SubstanceAnalyzerCore.Models.UnitTests`: 1 passed.
  - `SubstanceAnalyzerCore.Service.IntegrationTests`: 6 passed.
  - `TripleQuadHardware.Service.IntegrationTests`: 6 passed.
  - `InstrumentCommunication.Service.IntegrationTests`: 1 passed.
  - `InstrumentCommunication.Service.Sim.IntegrationTests`: 1 passed.
  - `DataService.Tests`: 113 passed.
- A parallel focused build attempt hit a transient local file lock on `Common.Settings.dll` from `VBCSCompiler`/Microsoft Defender. `dotnet build-server shutdown` cleared it, and sequential reruns passed.
