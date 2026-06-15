# Conference-Check Swab Workflow References

- Current app repo: `C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI`
- Legacy/simulator reference: `C:\Git\DHS-GUI`
- Primary solution: `source\TripleQuadUI\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx`
- Simulator described by Brian: DHS-GUI Compound Analyzer 2 simulator connected to the instrument service.

## Search Terms For Investigation

- conference check
- swab inserted
- collection
- substance training
- scan series
- calibration
- sleep
- wake
- simulator
- instrument status

## Initial Source Anchors

- Current manager: `source\TripleQuadUI\CoreLogicLayer\SubstanceAnalyzerCore.Service\App\SampleCollectionManager.cs`
- Current collector: `source\TripleQuadUI\CoreLogicLayer\SubstanceAnalyzerCore.Service\App\SampleCollector.cs`
- Current service snapshots: `source\TripleQuadUI\CoreLogicLayer\SubstanceAnalyzerCore.Service\Services\SampleCollectionService.cs`
- Current status model: `source\TripleQuadUI\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer\Presentation\Models\AppModel.cs`
- Current training collection model: `source\TripleQuadUI\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer\Presentation\Models\CollectSamplesForSubstanceTrainingModel.cs`
- Legacy analyzer reference: `C:\Git\DHS-GUI\CommonLibraries\DataAnalyzer.Core\LiveScanSeriesAnalyzer.cs`

## Local UI Inspection And Automation Tools

- Windows SDK Inspect: `C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\inspect.exe`
- FlaUInspect: `C:\Users\brian.mello\AppData\Local\Microsoft\WinGet\Packages\FlaUI.FlaUInspect_Microsoft.Winget.Source_8wekyb3d8bbwe\FlaUInspect.exe`
- Appium CLI: `appium`
- Appium Windows driver: `windows@5.4.1`, automationName `Windows`
