# TQ-011A immutable evidence register

## Baseline rule

All product evidence below is read-only and commit-addressed. The checked-out TripleQuadUI superproject contained locally modified submodule worktrees, so this ADR used only the superproject tree and its recorded gitlinks. No dirty SHR-011D1/2 development file is cited.

Citation form is `repository@commit:path#Lx-Ly`. Line numbers were obtained from `git show <commit>:<path>`.

## TripleQuadUI superproject

Baseline: `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892`.

| Evidence | Immutable citation | ADR use |
|---|---|---|
| `ServiceHost` is the analyzer DI/composition root and maps only current gRPC/health routes. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/ServiceHost.cs#L18-L77` | Register producer/query provider in process; add no endpoint. |
| Analyzer project currently references algorithms, DataService client, UserManagement client, and hardware, but not Reports. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/SubstanceAnalyzerCore.Service.csproj#L33-L42` | TQ-011B owns narrow Reports project references/gitlink advance. |
| Current RPC `StartAnalysis` merely calls the collection manager synchronously. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/Services/SampleCollectionService.cs#L573-L580` | This is intent, not atomic Event acceptance. |
| Device insertion causes `BeginCollecting`; state entry creates the scan series and starts acquisition. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleCollector.cs#L307-L337`; `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleCollector.cs#L118-L163` | Refactor this exact transition to await FDRS acceptance first. |
| Current completion classifies, saves the legacy sample, then raises `SampleCollected` from an `async void` handler. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleCollectionManager.cs#L77-L95`; `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleCollectionManager.cs#L102-L164` | Refactor to awaited terminal producer workflow. |
| Current local sample number comes from settings/legacy metadata, wraps at `int.MaxValue`, and scan metadata uses `Environment.MachineName`. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleCollector.cs#L518-L565`; `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleCollector.cs#L594-L632` | Prohibit as Event/Machine identity. |
| Current legacy save chooses create/update by repository object ID. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleManager.cs#L36-L65` | Legacy repository is retained-data only, never report authority. |
| Current annotation is mutable `AnnotationData` copied into the legacy sample. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleAnnotator.cs#L7-L76`; `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/App/SampleDataAnalyzer.cs#L115-L136` | Do not serialize it into FDRS. |
| `AnnotationData` contains preparer/location/comments, substances, amounts, compounds, and units. | `Algorithms/Common@3d09c792059bbcdf129ccb1a75cc7317dd2317aa:Common.Data/ScanSeriesData.cs#L120-L147` | It is not an approved single report-annotation mapping. |
| Analyzer authorization resolves only an access policy from a bearer token. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/Security/ProtectedOperationAuthorization.cs#L8-L60` | Does not supply stable actor/session identity. |
| UI session stores username/token only; logout is local/revocation best effort. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/Presentation/Models/UserSession.cs#L3-L35`; `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer/Presentation/Models/SessionLogoutCoordinator.cs#L3-L26` | Trusted identity/session bridge is a hard gate. |
| Hardware client exposes health, current `DeviceSnapshot`, instrument-change subscription, and periodic `GetCurrentInstrumentAsync`; both server response paths construct a snapshot and call the same apply path. The snapshot has no reconciliation/provenance flag. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:HardwareLayer/TripleQuadHardware.Client/InstrumentManagerClient.cs#L65-L111`; `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:HardwareLayer/TripleQuadHardware.Client/InstrumentManagerClient.cs#L218-L275` | Exact implementable proof is health `Serving` plus a subsequent applied connected snapshot event; do not claim an unobservable “reconciled snapshot.” |
| Device snapshot contains serial and connection state, begins disconnected with empty serial, swaps the whole immutable record in `Apply`, and raises `DevicesChanged`. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:HardwareLayer/TripleQuadHardwareInstrument/InstrumentClientSnapshots.cs#L14-L23`; `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:HardwareLayer/TripleQuadHardwareInstrument/InstrumentClientSnapshots.cs#L52-L108`; `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:HardwareLayer/TripleQuadHardwareInstrument/BaseDeviceManager.cs#L17-L25` | Subscribe before health gating; initial/current reads alone are insufficient. No hardware change is authorized. |
| Workstation device manager updates and clears serial; its instrument time is a separate non-authoritative value. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:HardwareLayer/Msws/Hardware.Instrument.MrmEtd/MsWorkstationDeviceManager.cs#L22-L36`; `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:HardwareLayer/Msws/Hardware.Instrument.MrmEtd/MsWorkstationDeviceManager.cs#L74-L93` | Serial is authoritative; instrument/local time is not. |
| Analyzer starts before instrument communication and UserManagement; stop order is reversed. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.MicroServices.Host/MicroServicesHostedService.cs#L33-L87`; `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.MicroServices.Host/MicroServicesHostedService.cs#L89-L127` | Readiness/restart must wait for late dependencies. |
| Algorithm warmup is an analyzer background lifecycle step. | `TripleQuadUI@26d3b174795384841b60eea987f97c7a711f8892:CoreLogicLayer/SubstanceAnalyzerCore.Service/Services/SampleCollectionBackgroundService.cs#L14-L64` | Restart completion waits for warmup. |

Recorded superproject gitlinks at the baseline:

| Path | Commit |
|---|---|
| `CommonLibraries/Algorithms` | `5f9bdca1b1fdb369f06f6aeefea57a4c37787f09` |
| nested Algorithms `Common` | `3d09c792059bbcdf129ccb1a75cc7317dd2317aa` |
| `CommonLibraries/DataService` | `ca36e9aabb149da9ff6d02e6707bd3df77224b38` |
| `CommonLibraries/Reports` | `fd705711aa17ab23e34efa1bcf52422ee50868fd` |
| `CommonLibraries/Services` | `14bd2025255d535ea1353aa4210679a535e781fe` |

### Reporting-zone absence check

The immutable search below returned no production match in the analyzer service for a reporting-zone option or `TimeZoneInfo` resolution:

```text
git grep -n -E "TimeZoneInfo|ReportingZone|reporting.zone" \
  26d3b174795384841b60eea987f97c7a711f8892 -- \
  CoreLogicLayer/SubstanceAnalyzerCore.Service
<no matches>
```

Therefore the ADR introduces the explicit `ReportsV1:ReportingZoneId` integration contract; it does not claim an existing zone source.

## Published Common.Reports

Baseline: `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc`.

| Evidence | Immutable citation | ADR use |
|---|---|---|
| `StartSampleCommand`/`CompleteSampleCommand` carry machine, UTC boundary, stable actor/session, config, result/reasons; `IFdrsRepository` exposes exact writer/query methods. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Fdrs.Application/FdrsPersistenceContracts.cs#L25-L70` | Exact producer delegation. |
| DataService FDRS repository owns versioned collections, capacity, `TimeProvider`, and initialization. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Persistence.DataService/DataServiceFdrsRepository.cs#L12-L91` | Storage/provider ownership and readiness. |
| Published FDRS schema lists machine state, record, event, cleanup, query snapshot, import, receipt, and quarantine collections; it contains no activation-binding or product-operation-journal collection. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Persistence.DataService/DataServiceFdrsRepository.cs#L12-L84` | Durable activation/T0 and retry ownership require SHR-011D3; analyzer-local invention is prohibited. |
| Published `IFdrsRepository` exposes initialization and FDRS record/sample/query operations only; no activation create/read/reactivate/rollback API exists. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Fdrs.Application/FdrsPersistenceContracts.cs#L56-L70` | Names the exact prerequisite gap rather than treating an in-memory binding as durable. |
| Start allocates the next ID and commits record/aggregate/state in one transaction, with ambiguous-commit resolution. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Persistence.DataService/DataServiceFdrsRepository.cs#L93-L181` | Atomic acceptance/receipt rule. |
| Completion and recovery close the same Event in transactions; recovery uses `Failure`. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Persistence.DataService/DataServiceFdrsRepository.cs#L184-L265` | Terminal/restart recovery behavior. |
| Alarm needs approved encoded code/strength; an `Alarm` terminal requires at least one reason. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Fdrs.Contracts/Payloads.cs#L6-L16`; `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Fdrs.Contracts/Payloads.cs#L33-L77` | SME mapper is a readiness gate. |
| Typed restart and session payloads define lifecycle semantics. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Fdrs.Contracts/Payloads.cs#L80-L155` | Exact append payload ownership. |
| Annotation requires stable target/author/session/time and normalizes/redacts content. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Fdrs.Contracts/Payloads.cs#L209-L214`; `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Fdrs.Contracts/Payloads.cs#L316-L365` | Explicit append-only annotation only. |
| Sample lifecycle/annotation drafts require stable user/session fields. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Fdrs.Contracts/FdrsPrimitives.cs#L42-L75` | Current UI identity cannot be used. |
| Controlled IDs are lowercase stable codes. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.Fdrs.Contracts/FdrsPrimitives.cs#L174-L203` | Versioned hashed machine mapping. |
| Canonical report Event/session/equipment/user fields are immutable. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.ReportDomain/ReportSnapshots.cs#L20-L90`; `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.ReportDomain/ReportSnapshots.cs#L92-L149` | Field/source map. |
| Existing report source DTOs expose Equipment/Event/User projections. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:Reports.ReportService.Contracts/ReportSourceContracts.cs#L6-L58` | Projection compatibility evidence. |
| TripleQuad inventory explicitly identifies missing atomic start, durable session ID, approved alarm mapping, and unsafe legacy values. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:docs/fdrs/v1/current-state-mapping.md#L61-L108` | Forward-only choice and gates. |
| FDRS defines Event/lifecycle boundaries, exact terminal semantics, stable identities, and no usernames/tokens. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:docs/fdrs/v1/contract.md#L5-L27`; `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:docs/fdrs/v1/contract.md#L31-L54` | Producer and recovery invariants. |
| Disclosure policy prohibits names/quantities/scores/raw diagnostics and visibility expansion. | `Common.Reports@664a09a9427cf2ade7fc155a1844c6505890c2bc:docs/fdrs/v1/disclosure.md#L1-L31` | Outcome/log/export guidance. |

## Published Common.DataService

Baseline: `Common.DataService@ca36e9aabb149da9ff6d02e6707bd3df77224b38` (the TripleQuadUI-recorded gitlink).

| Evidence | Immutable citation | ADR use |
|---|---|---|
| Transaction abstraction has explicit conflict/unavailable/corruption/ambiguous/canceled results, partition version, and ambiguous resolver. | `Common.DataService@ca36e9aabb149da9ff6d02e6707bd3df77224b38:DataService.Storage.Abstractions/StorageContracts.cs#L133-L178` | Reconciliation and fail-closed mapping. |
| Product/provider boundary is `ITransactionalDocumentStore`; transactions query/insert/replace/delete within one partition. | `Common.DataService@ca36e9aabb149da9ff6d02e6707bd3df77224b38:DataService.Storage.Abstractions/StorageContracts.cs#L180-L217` | D2 may use this; product code may not. |
| Legacy sample client loads all metadata and exposes CRUD/export/last-number operations, not stable snapshot queries. | `Common.DataService@ca36e9aabb149da9ff6d02e6707bd3df77224b38:DataService.Clients/ISamplesRepositoryClient.cs#L49-L128` | Reject legacy reader and on-demand dual read. |

## Unpublished dependencies

SHR-011D1 is expected to publish `Reports.ReportSources.Contracts`/`IFdrsReportSourceQuery`. SHR-011D3 must publish `IReportSourceControlStoreV1`, typed atomic transition modes/reasons, CBE-v1 identity/draft vectors, its DataService provider, activation collections/history reads, and durable closed-kind operation journal exactly as frozen in its [contract-first story](../2026-11-23-shr-011d3-report-source-control-store/story.md). SHR-011D2 must then publish the provider as a descendant of accepted D1 and D3, binding activation-history fingerprint/interval validation into each immutable snapshot. At the time of this package, no independently accepted commit was available for any of them. TQ-011B must record exact accepted SHAs, symbol confirmation, and conformance commands before development. This register intentionally contains no SHA or line citation to dirty draft worktrees.
