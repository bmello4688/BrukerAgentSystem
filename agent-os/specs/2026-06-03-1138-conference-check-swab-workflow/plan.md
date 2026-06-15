# Conference-Check Swab Workflow Plan

## Recommended Role Flow

1. Domain Analyst compares DHS-GUI and current TripleQuadUI behavior.
2. Coordinator Architect identifies source boundaries and likely message/UI/persistence path.
3. Feature Engineer implements the smallest fix that connects simulator swab insertion to status, workflow UI, and persistence.
4. Reviewer Integration verifies status behavior, simulator validation, persistence, and repo secrecy.

## Investigation Tasks

- Trace simulator conference-check swab insertion from DHS-GUI Compound Analyzer 2 into the instrument service.
- Trace current TripleQuadUI status update pipeline during startup, sleep, login/wake, ready, calibration, and conference-check flow.
- Find where simulator data reaches collection/substance-training UI today.
- Identify why visible simulator data does not trigger collection workflow state.
- Identify scan series repository/database write and recall path.

## Implementation Hypotheses

- The simulator and scan-data path are functioning, but `VerifyCalibration` does not start collection when baseline is ready and the swab closes.
- `SetConfidenceCheck()` and `StartAnalysis()` currently only take effect while management state is `SampleCollecting`, so confidence-check verification can be blocked before analysis starts.
- Collection/substance-training displays scan data directly through the graph stream, which can make simulator data visible while workflow progress and persistence stay idle.
- Persistence requires a completed collection event that may not be raised for confidence-check swabs if collection never starts.

## Validation Plan

- Run focused build/test for touched projects.
- Run `dotnet build .\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx` from `source\TripleQuadUI` when shared contracts or UI/service boundaries are touched.
- Validate with DHS-GUI Compound Analyzer 2 simulator connected to instrument service.
- Use Inspect or FlaUInspect to compare visible UI Automation state between DHS-GUI and TripleQuadUI where helpful.
- Use Appium Windows driver for repeatable UI workflow checks if manual inspection is not enough.
- Confirm system status updates during conference-check swab insertion.
- Confirm Uno UI progress/timing updates.
- Confirm scan series/sample is saved and recallable.
- Record real-hardware validation as not run unless Brian explicitly performs or requests it.
