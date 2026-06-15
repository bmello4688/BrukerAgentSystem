# TripleQuadUI Solution Boundaries

This is the BL-001 local reference for scoping future TripleQuadUI feature work. It describes the current application repo at `C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI`; keep this planning document outside the Bruker Detection Git repo.

## Primary Entry Points

- Main solution: `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.slnx`.
- Analyzer UI app: `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.csproj`.
- Local service host: `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.MicroServices.Host/MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj`.
- Central build/version files: `global.json`, `Directory.Build.props`, `Directory.Build.targets`, and `Directory.Packages.props`.

## Application And Host Boundary

- `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer` is the Uno analyzer UI. It targets `net10.0-android`, `net10.0-ios`, and `net10.0-desktop`; current desktop work should treat `net10.0-desktop` as the focused UI target.
- The UI depends on service clients, not service internals: `SubstanceAnalyzerCore.Client`, `TripleQuadHardware.Client`, and shared algorithm/data/common libraries.
- UI folders worth knowing: `Presentation/Controls`, `Presentation/Models`, `Presentation/Converters`, `Styles`, `Strings`, `Models`, and platform-specific code under `Platforms`.
- `MrmEtdMassSpecAnalyzer.MicroServices.Host` composes local backend services for app runs. Its project references the substance analyzer core service, triple-quad hardware service, instrument communicator service, and instrument simulator service.
- The microservice host has its own `appsettings*.json` and `Properties/launchSettings.json`, plus copied service appsettings at runtime. Treat changes here as cross-service coordination work.

## Core Logic Boundary

- `CoreLogicLayer/SubstanceAnalyzerCore.Models` contains shared core/domain models used by the core service, clients, and tests.
- `CoreLogicLayer/SubstanceAnalyzerCore.Client` is the UI-facing gRPC client boundary for sample collection and core status.
- `CoreLogicLayer/SubstanceAnalyzerCore.Service` owns sample collection orchestration, analyzer state, confidence-check state, detection status, and the gRPC service implementation.
- Core service entry points are `Program.cs` and `ServiceHost.cs`; hosted/background behavior is in `SampleCollectionBackgroundService`; the gRPC endpoint maps `SampleCollectionService`.
- Core contract: `CoreLogicLayer/SubstanceAnalyzerCore.Service/Protos/sampleCollectionService.proto`. Changing it affects client generation, UI models, integration tests, and end-to-end tests.
- Core config: `CoreLogicLayer/SubstanceAnalyzerCore.Service/appsettings.json`, `appsettings.Development.json`, and `Properties/launchSettings.json`.

## Hardware And Simulator Boundary

- `HardwareLayer/TripleQuadHardwareInstrument` contains shared instrument/hardware contract models and protobufs. Its `Protos/instrumentCommon.proto` and `Protos/instrumentHardware.proto` are broad coordination points.
- `HardwareLayer/TripleQuadHardware.Client` is the app-facing gRPC client for instrument state and commands. It currently defaults to a localhost hardware service endpoint in client code.
- `HardwareLayer/TripleQuadHardware.Service` is the higher-level hardware gRPC service. Its `ServiceHost.cs` maps `TripleQuadHardwareService` and starts `TripleQuadHardwareBackgroundService`.
- `HardwareLayer/TripleQuadHardware.Service/Protos/tripleQuadHardware.proto` is the higher-level hardware service contract.
- `HardwareLayer/Hardware.Interface.Desorber` is the desorber interface boundary and references the shared instrument project.
- `HardwareLayer/Msws/Hardware.Interface.MsWorkstation` contains MS workstation integration code and settings. Treat it as hardware-sensitive.
- `HardwareLayer/Msws/Hardware.Instrument.MrmEtd` composes the desorber, MS workstation interface, and instrument communication client into an instrument implementation.
- `HardwareLayer/Msws/Hardware.Instrument.MrmEtd.Communication.Service` is the instrument communicator gRPC service. Its contract is `Protos/instrumentCommunicator.proto`.
- `HardwareLayer/Msws/Hardware.Instrument.MrmEtd.Communication.Client` is the client for the instrument communication service.
- `HardwareLayer/Msws/Hardware.Instrument.MrmEtd.Communication.Service.Sim` is the instrument simulator service. It exposes both simulator and simulator-control gRPC services from `Services/instrumentSimulator.proto` and uses simulator resources such as `Resources/fullscan-data.json` and `Resources/DefaultSensorReadbacks.json`.
- `HardwareLayer/Simulator.App` is the Windows simulator UI app. It references the simulator service project and has its own `appsettings.json`.
- Hardware/service config hotspots include every hardware `appsettings*.json`, `Properties/launchSettings.json`, and service `ServiceHost.cs`. Real hardware validation must stay separate from simulator validation.

## Data Service Boundary

- `CommonLibraries/DataService/DataService.Models` contains sample/scan data models and DataService protobuf contracts: `samples_grpc.proto` and `samples_grpc_data.proto`.
- `CommonLibraries/DataService/DataService.Service` is the sample/scan persistence service. It maps `SamplesGrpcService`, exposes repository implementations, and uses LiteDB/MongoDB/protobuf scan storage paths.
- `CommonLibraries/DataService/DataService.Common` contains shared data-service options/common helpers.
- `CommonLibraries/DataService/DataService.Clients`, `DataService.GrpcCodeFirstClient`, and `DataService.GrpcContractFirstClient` are client and example/test client boundaries.
- `CommonLibraries/DataService/DataService.Import` handles imports and has its own `appsettings*.json` and launch settings.
- `CommonLibraries/DataService/DataService.CreateProtos` is tooling around proto generation. Treat this as generated-contract coordination.
- DataService has its own `CommonLibraries/DataService/Directory.Packages.props`, so dependency changes may need coordination with the root package file.

## Algorithms And Python Boundary

- `CommonLibraries/Algorithms/Algorithms.Models` contains algorithm data models.
- `CommonLibraries/Algorithms/Algorithms.Preprocessing` contains preprocessing logic and depends on algorithm models.
- `CommonLibraries/Algorithms/Algorithms.Python` connects algorithms to Python-backed execution and references `Python.Interop`.
- `CommonLibraries/Algorithms/Python.Interop` is the Python interop layer.
- `CommonLibraries/Algorithms/Bruker Analysis` appears to contain Bruker analysis implementation/resources, including `Resources/SubstanceLibrary.json`.
- `CommonLibraries/Algorithms/Algorithms.UI` and `CommonLibraries/Algorithms/Common/Common.UI.Mvvm` are UI/shared presentation helpers used by algorithm-facing surfaces.
- `CommonLibraries/Algorithms/Python.Included` contains embedded Python deployment/installer projects and older-target examples/tests. Changes here are packaging/runtime-sensitive and should be isolated from normal feature work.
- `InstallEmbeddedPython/InstallEmbeddedPython.csproj` is a root-level executable for Python installation and references `Python.Interop`.

## Common Libraries Boundary

- `CommonLibraries/Algorithms/Common/Common` is a general shared utility project.
- `CommonLibraries/Algorithms/Common/Common.Data` is shared data infrastructure used by the analyzer app and data layer; it references `CommonLibraries.Uno/Common.Settings`.
- `CommonLibraries/Algorithms/Common/Common.IO` contains shared IO helpers.
- `CommonLibraries.Uno/Common.OperatingSystem` is a multi-target Uno/platform library.
- `CommonLibraries.Uno/Common.Settings` handles shared settings and references the common algorithm library.
- `CommonLibraries.Uno/Common.Tasks` contains shared task helpers.
- `CommonLibraries/Services/MsWorkstationLog` is a separate gRPC logging service family: service, client, and test client. Its contract is `MsWorkstationLog.proto`.

## Tests Boundary

- `Tests/Unit/SubstanceAnalyzerCore.Models.UnitTests` covers core model behavior.
- `Tests/Integration/TestInfrastructure` provides shared integration-test helpers and gRPC health/client support.
- `Tests/Integration/SubstanceAnalyzerCore.Service.IntegrationTests` covers the core service.
- `Tests/Integration/TripleQuadHardware.Service.IntegrationTests` covers the hardware service.
- `Tests/Integration/InstrumentCommunication.Service.IntegrationTests` covers the instrument communication service.
- `Tests/Integration/InstrumentCommunication.Service.Sim.IntegrationTests` covers the simulator service.
- `Tests/Integration/DataService.Service.IntegrationTests` covers the data service.
- `Tests/EndToEnd/MrmEtdMassSpecAnalyzer.EndToEndTests` references all major gRPC contracts and should be treated as cross-boundary validation.

## High-Coordination Files

- Build/version coordination: `global.json`, `Directory.Build.props`, `Directory.Build.targets`, `Directory.Packages.props`, plus `CommonLibraries/DataService/Directory.Packages.props`.
- Main solution membership: `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.slnx`.
- App and service configuration: all checked-in `appsettings*.json` and `Properties/launchSettings.json` files under the app, host, core service, hardware services, simulator, DataService, and MsWorkstationLog service.
- Proto contracts: `sampleCollectionService.proto`, `tripleQuadHardware.proto`, `instrumentCommon.proto`, `instrumentHardware.proto`, `instrumentCommunicator.proto`, `instrumentSimulator.proto`, `samples_grpc.proto`, `samples_grpc_data.proto`, and `MsWorkstationLog.proto`.
- Generated artifacts: anything under `bin/` or `obj/`, generated protobuf C# files, NuGet-generated props/targets, and static web asset props should not be edited directly.
- Hardware-sensitive code: `HardwareLayer/Msws`, `HardwareLayer/TripleQuadHardware.Service`, `HardwareLayer/TripleQuadHardwareInstrument`, and `HardwareLayer/Hardware.Interface.Desorber`.
- Simulator-sensitive code: `HardwareLayer/Msws/Hardware.Instrument.MrmEtd.Communication.Service.Sim`, `HardwareLayer/Simulator.App`, and simulator resource JSON files.
- Persistence-sensitive code: DataService repositories, data models, import tooling, archive/export paths, and scan protobuf files.

## Scoping Guidance For Future Stories

- UI-only stories should usually stay in `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer` and client-facing models unless the service contract needs new data.
- Workflow/status stories usually cross UI models, `SubstanceAnalyzerCore.Client`, `SubstanceAnalyzerCore.Service`, and one or more hardware clients/services.
- Instrument readiness, swab, pressure, calibration, and MS workstation behavior are hardware-sensitive. Compare `C:\Git\DHS-GUI` before changing semantics.
- Simulator validation is not real hardware validation. Document which path was used.
- Proto, package, build props, appsettings, service host, and shared model changes should be treated as cross-team coordination work.
