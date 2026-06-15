# TripleQuadUI Tech Stack

## Repository Layout

- Git repo: `C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI`
- Legacy app reference: `C:\Git\DHS-GUI`
- Remote: `http://nbbil03-build.bdet.local/Git/Commercial/TripleQuadUI.git`
- Source strategy: one primary Bruker Detection repository with nested submodule-style/shared-library areas.

## Application

- Runtime/platform: .NET 9, with central versions in `global.json`, `Directory.Build.props`, `Directory.Build.targets`, and `Directory.Packages.props`.
- UI: local Uno Platform analyzer desktop application under `MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer`.
- Services: ASP.NET/Core-style local microservices and hosts under `MrmEtdMassSpecAnalyzer`, `CoreLogicLayer`, `HardwareLayer`, and shared service libraries.
- Service contracts: gRPC/protobuf and service clients where present.
- Configuration: `appsettings*.json` and `Properties/launchSettings.json` files across services and hosts.
- Primary solution build: `MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx`
- Target posture: Windows-only for now. The analyzer is a local desktop application plus local/service-hosted architecture.
- Development launch expectation: UI E2E testing should have a convenient profile that launches the Uno UI and all local microservices together.
- Production launch expectation: microservices run as Windows Services; the Uno UI is launched by the operator or auto-launched in kiosk mode as the only app on the machine.
- Development focus: local desktop UI, local/service-hosted processes, shared libraries, and instrument/service integration.

## Major Areas

- `MrmEtdMassSpecAnalyzer/` - analyzer UI and microservice host.
- `HardwareLayer/` - triple quadrupole hardware service/client, instrument communication, MS workstation integration, simulator, and hardware interfaces.
- `CoreLogicLayer/` - substance analyzer core service/client/models.
- `CommonLibraries/DataService/` - data service models, clients, imports, tests, and service.
- `CommonLibraries/Algorithms/` - analysis algorithms, Python interop, included Python tooling, machine-learning support, and related UI/common libraries. Embedded Python is product-critical for algorithms.
- `CommonLibraries/Services/MsWorkstationLog/` - MS workstation logging service and clients.
- `CommonLibraries.Uno/` - common Uno/platform libraries.

## Source Control

- The local `C:\Git\Commercial\MrmETDSpec` workspace is the source of truth for Agent OS context.
- The TripleQuadUI repo is the source of truth for application code only.
- Use feature branches from `master`; owner review and manual merge are required before `master`.
- Coordinate changes to shared contracts, props, package versions, generated code, appsettings, and hardware/service interfaces.
