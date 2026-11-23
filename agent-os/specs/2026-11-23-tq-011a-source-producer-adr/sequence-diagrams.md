# TQ-011A sequence diagrams

## 1. Accepted sample, terminal commit, and snapshot query

```mermaid
sequenceDiagram
    participant HW as Hardware snapshot
    participant SC as SampleCollector admission
    participant P as IAnalyzerReportSourceProducerV1
    participant R as IFdrsRepository
    participant A as Analyzer workflow
    participant Q as AnalyzerReportSourceQueryFacadeV1
    participant D2 as IFdrsReportSourceQuery

    HW->>SC: device insertion, reconciled machine
    SC->>P: AcceptSampleAsync(stable actor/session/config, trusted UTC, correlation)
    P->>R: StartSampleAsync(StartSampleCommand)
    R-->>P: AcceptedSample(EventId, correlation, receipt)
    P-->>SC: accepted
    SC->>A: enter collection and acquire
    A->>A: classify + approved result/alarm mapping
    A->>P: CompleteSampleAsync(same EventId/correlation, terminal UTC)
    P->>R: CompleteSampleAsync(CompleteSampleCommand)
    R-->>P: committed terminal receipt
    P-->>A: completed
    opt explicit authorized annotation exists
        A->>P: AddEventAnnotationAsync(target Event, stable author/session)
        P->>R: AppendRecordAsync(EventAnnotationAddedPayload)
        R-->>P: committed append receipt
    end
    Q->>Q: require Ready + exact machine/zone/T0
    Q->>D2: QueryEquipment/Event/UserAsync(request, page)
    D2-->>Q: one immutable D1 page/result
    Q-->>A: Ready with complete value, or closed zero-value outcome
```

The legacy scan save is outside the report atomicity boundary. If it yields a safe opaque retained-data reference in time, that reference may be included in terminal completion; it cannot determine Event identity or report visibility.

## 2. Cutover and activation

```mermaid
sequenceDiagram
    participant O as Named release owner
    participant H as Host/analyzer
    participant G as Readiness gate
    participant R as FDRS repository
    participant D2 as Published D2 provider

    O->>H: deploy exact approved product + gitlinks, disabled
    H->>G: Disabled
    O->>H: quiesce sample admission and report requests
    H->>R: initialize/capability check
    H->>H: validate D1/D2 SHA, machine hash, zone rules, clock, session bridge, alarm map, config
    H->>R: prove no active sample/session and zero legacy/import state
    alt any check fails
        H->>G: keep Disabled; closed zero-value outcome
    else all checks pass
        H->>R: commit activation record(T0, versions, machine, zone fingerprint, config)
        H->>G: WritersEnabled, QueriesDisabled
        H->>R: deterministic producer/reconciliation probes
        H->>D2: D1 conformance query probes
        alt exact reconciliation and probes pass
            H->>G: Ready
        else mismatch/gap/unknown
            H->>G: Disabled
        end
    end
```

There is no stage in which queries are enabled before compatible writers or in which legacy data is consulted.

## 3. Ambiguous acceptance and process restart

```mermaid
sequenceDiagram
    participant SC as Sample admission
    participant P as Producer
    participant R as IFdrsRepository
    participant S as Startup/reconciliation
    participant G as Readiness gate

    SC->>P: AcceptSampleAsync(correlation C)
    P->>R: StartSampleAsync(C)
    R--xP: commit acknowledgement ambiguous
    P-->>SC: acceptance unconfirmed; do not collect
    P->>G: disable new starts and queries
    Note over P,R: never create a replacement correlation or ID
    S->>G: Disabled on restart
    S->>R: Initialize + resolve deterministic receipt C
    alt start committed and Event open
        S->>R: RecoverInterruptedSampleAsync(same machine/Event -> Failure)
    else start not committed
        S->>R: prove no Event/receipt for C
    else resolution unavailable/conflicting
        S->>G: SourceUnavailable/SourceGap
    end
    S->>R: reconcile high-water, terminals, receipts, session links
    alt zero discrepancies
        S->>G: enable after remaining startup gates
    else any discrepancy
        S->>G: remain Disabled
    end
```

## 4. Session lifecycle and crash ordering

```mermaid
sequenceDiagram
    participant U as Trusted UserManagement bridge
    participant P as Producer
    participant R as IFdrsRepository
    participant S as Startup recovery

    U->>P: RecordSessionStartedAsync(UserId, attempt correlation, UTC)
    P->>R: append session-started
    alt denied
        U->>P: RecordSessionAccessDecisionAsync(Denied, controlled code, no SessionId)
        P->>R: append denied decision
    else granted
        U->>P: RecordSessionAccessDecisionAsync(Granted, stable SessionId)
        P->>R: append granted decision
        Note over U,R: accepted Events store this exact SessionId
        alt normal logout and no active sample
            U->>P: RecordSessionEndedAsync(Logout, exact UTC)
            P->>R: append session-ended
        else process crashes with active sample
            S->>R: recover Event as Failure using same EventId
            R-->>S: committed terminal
            S->>P: RecordSessionEndedAsync(Recovery, interrupted failure recorded)
            P->>R: append recovery session end/incomplete evidence
        end
    end
```

No username, token, time-overlap join, or fabricated end time is used.

## 5. Rollback decision

```mermaid
flowchart TD
    A[Disable readiness and sample admission] --> B{T0 committed?}
    B -- No --> C[Stop; revert TQ commit and Reports gitlink]
    B -- Yes --> D[Run exact reconciliation]
    D --> E{Any accepted post-T0 write?}
    E -- No --> F[Named owner approves pre-write rollback]
    F --> C
    E -- Yes --> G[Preserve all FDRS records]
    G --> H[Deploy last compatible producer/provider or roll forward]
    H --> I[Reconcile; re-enable only when exact checks pass]
```

After a post-`T0` write, rollback never deletes/reinterprets records and never returns to legacy report reads.
