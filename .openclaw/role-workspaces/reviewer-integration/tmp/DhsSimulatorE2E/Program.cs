using Google.Protobuf.WellKnownTypes;
using Grpc.Net.Client;
using Grpc.TripleQuadHardware;
using Grpc.UIToCore;
using Hardware.Instrument.MrmEtd.Communication.Service;

AppContext.SetSwitch("System.Net.Http.SocketsHttpHandler.Http2UnencryptedSupport", true);

using var coreChannel = GrpcChannel.ForAddress("http://127.0.0.1:7042");
using var hardwareChannel = GrpcChannel.ForAddress("http://127.0.0.1:7043");
using var simulatorChannel = GrpcChannel.ForAddress("http://127.0.0.1:7044");

var core = new SampleCollectionService.SampleCollectionServiceClient(coreChannel);
var hardware = new TripleQuadHardwareInterface.TripleQuadHardwareInterfaceClient(hardwareChannel);
var simulator = new instrumentSimulator.instrumentSimulatorClient(simulatorChannel);

var timeline = new List<string>();
var start = DateTimeOffset.Now;

static string Stamp(DateTimeOffset start) => $"+{(DateTimeOffset.Now - start).TotalSeconds,6:0.0}s";

async Task<(InstrumentStatus status, SampleCollectorState collector, StateChangeSubscriptionResponse hardwareState, InstrumentChangeSubscriptionResponse instrument, SimulatorState simState)> Snapshot(string label)
{
    var status = await core.GetCurrentInstrumentStatusAsync(new Empty());
    var collector = await core.GetCurrentSampleCollectorStateAsync(new Empty());
    var hardwareState = await hardware.GetCurrentStateAsync(new Empty());
    var instrument = await hardware.GetCurrentInstrumentAsync(new Empty());
    var simState = await simulator.GetStateAsync(new Empty());

    timeline.Add($"{Stamp(start)} {label}: core={status.Status.Message}/{status.Status.Severity}, sub={status.SubStatus.Message}/{status.SubStatus.Severity}, collection={collector.CollectionState}, collector={collector.CollectorState}, confidence={collector.IsRunningConfidenceCheck}, baseline={collector.NumberOfBaselineScans}, analysis={collector.NumberOfAnalysisScans}, cleardown={collector.NumberOfCleardownScans}, hw={hardwareState.CurrentState}, power={instrument.PowerState}, swab={instrument.SwabClampState}, cal={instrument.CalibrationState}, needCal={instrument.NeedToCalibrate}, readyVerify={instrument.ReadyToVerifyCalibration}, simCid={simState.IsCidOn}, simCidPressure={simState.CidPressure:0.###}");
    return (status, collector, hardwareState, instrument, simState);
}

async Task<T> WaitFor<T>(string label, Func<Task<T>> read, Func<T, bool> predicate, TimeSpan timeout, TimeSpan? interval = null)
{
    var deadline = DateTimeOffset.Now + timeout;
    Exception? lastError = null;
    while (DateTimeOffset.Now < deadline)
    {
        try
        {
            var value = await read();
            if (predicate(value))
            {
                return value;
            }
        }
        catch (Exception ex)
        {
            lastError = ex;
        }

        await Task.Delay(interval ?? TimeSpan.FromMilliseconds(500));
    }

    throw new TimeoutException($"Timed out waiting for {label}." + (lastError is null ? string.Empty : $" Last error: {lastError.GetType().Name}: {lastError.Message}"));
}

async Task<SampleCollectorState> WaitCollector(string label, Func<SampleCollectorState, bool> predicate, int seconds = 45)
{
    return await WaitFor(label, async () =>
    {
        var snap = await Snapshot(label);
        return snap.collector;
    }, predicate, TimeSpan.FromSeconds(seconds));
}

async Task<SensorDatum?> PollCidPressureMbar(TimeSpan timeout)
{
    var deadline = DateTimeOffset.Now + timeout;
    while (DateTimeOffset.Now < deadline)
    {
        var response = await hardware.GetCurrentStateAsync(new Empty());
        _ = response;

        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(3));
        using var call = hardware.SubscribeToSensorsChangedEvent(new Empty(), cancellationToken: cts.Token);
        try
        {
            while (await call.ResponseStream.MoveNext(cts.Token))
            {
                var sensor = call.ResponseStream.Current.SensorData
                    .FirstOrDefault(g => string.Equals(g.Name, "CIDV", StringComparison.OrdinalIgnoreCase))
                    ?.SensorData
                    .FirstOrDefault(s => string.Equals(s.Name, "CIDV_RB_PRES_MBAR", StringComparison.OrdinalIgnoreCase));
                if (sensor is not null)
                {
                    return sensor;
                }
            }
        }
        catch (OperationCanceledException)
        {
        }
        await Task.Delay(250);
    }

    return null;
}

static bool IsActiveAlert(SubstanceAlertInformation? alert)
{
    if (alert is null || string.IsNullOrWhiteSpace(alert.DetectionResultOverview))
    {
        return false;
    }

    if (alert.IsConfidenceCheck)
    {
        return !alert.PassedConfidenceCheck;
    }

    return !alert.DetectionResultOverview.Contains("No Threat", StringComparison.OrdinalIgnoreCase);
}

static string DescribeAlert(SubstanceAlertInformation? alert)
{
    if (alert is null)
    {
        return "<null>";
    }

    return $"sample={alert.SampleID}, hasDetected={alert.HasDetectedSubstance}, confidence={alert.IsConfidenceCheck}, passedConfidence={alert.PassedConfidenceCheck}, overview='{alert.DetectionResultOverview}', names=[{string.Join(", ", alert.DetectedSubstanceNames)}]";
}

async Task<SubstanceAlertInformation> ReadLiveAlertOnce(TimeSpan timeout)
{
    using var cts = new CancellationTokenSource(timeout);
    using var call = core.GetLiveSubstanceAlertSubscription(new SubscriptionRequest(), cancellationToken: cts.Token);
    if (!await call.ResponseStream.MoveNext(cts.Token))
    {
        throw new TimeoutException("Live alert subscription completed without a response.");
    }

    return call.ResponseStream.Current.SubstanceAlertInformation;
}

async Task<SubstanceAlertInformation> WaitAlert(string label, Func<SubstanceAlertInformation, bool> predicate, int seconds = 45)
{
    return await WaitFor(label, () => ReadLiveAlertOnce(TimeSpan.FromSeconds(5)), predicate, TimeSpan.FromSeconds(seconds), TimeSpan.FromMilliseconds(500));
}

async Task<SampleCollectorState> ReadCollectorState()
{
    return await core.GetCurrentSampleCollectorStateAsync(new Empty());
}

async Task<SubstanceAlertInformation> CollectThreatSample(string label, string substanceName)
{
    await WaitCollector($"{label} baseline ready", c =>
        c.CollectionState == "SampleCollecting" &&
        c.CollectorState == "CollectingBaseline" &&
        c.ReadyToCollectSample &&
        c.NumberOfBaselineScans >= 10, 60);
    await Snapshot($"{label} ready");

    var setScanType = await simulator.SetScanTypeAsync(new StringValue { Value = "MRM" });
    var setSubstance = await simulator.SetSubstanceAsync(new StringValue { Value = substanceName });
    timeline.Add($"{Stamp(start)} {label} simulator setup: setScanTypeMRM={setScanType.Value}, setSubstance={substanceName}:{setSubstance.Value}");

    await core.StartAnalysisAsync(new AnalysisControlRequest { IsConfidenceCheck = false });
    timeline.Add($"{Stamp(start)} {label} command: StartAnalysis(false)");

    var insert = await simulator.InsertSampleAsync(new Empty());
    timeline.Add($"{Stamp(start)} {label} command: InsertSample={insert.Value}");

    await WaitCollector($"{label} collecting sample", c => c.CollectorState == "CollectingSample" && c.NumberOfAnalysisScans >= 1, 30);
    await WaitCollector($"{label} waiting for removal", c => c.CollectorState == "WaitingForSwabRemoval" && c.NumberOfAnalysisScans >= c.MaxScansPerAnalysis, 60);
    await Snapshot($"{label} analysis complete");

    await WaitFor($"{label} simulator removal ready", async () =>
    {
        var snap = await Snapshot($"{label} removal poll");
        return snap;
    }, snap => snap.instrument.SwabClampState.ToString() == "SwabNeedsToBeRemoved" && snap.simState.CanRemoveSwab, TimeSpan.FromSeconds(20));

    var remove = await simulator.RemoveSampleAsync(new BoolValue { Value = false });
    timeline.Add($"{Stamp(start)} {label} command: RemoveSample={remove.Value}");

    await WaitCollector($"{label} baseline after removal", c =>
        c.CollectionState == "SampleCollecting" &&
        c.CollectorState == "CollectingBaseline" &&
        c.ReadyToCollectSample &&
        c.NumberOfBaselineScans >= 10, 60);
    await Snapshot($"{label} post remove ready");

    var alert = await WaitAlert($"{label} active alert", IsActiveAlert, 45);
    timeline.Add($"{Stamp(start)} {label} active alert: {DescribeAlert(alert)}");

    return alert;
}

if (args.Length > 0 && args[0] == "query")
{
    await WaitFor("services to answer", () => core.GetCurrentSampleCollectorStateAsync(new Empty()).ResponseAsync, _ => true, TimeSpan.FromSeconds(10));
    await Snapshot("query");
    var metadata = await core.GetCollectedSamplesMetadataAsync(new Empty());
    var confidence = metadata.Samples.Where(s => s.IsConfidenceCheck).OrderByDescending(s => s.SampleNumber).ToList();
    timeline.Add($"{Stamp(start)} metadata query: total={metadata.Samples.Count}, confidence={confidence.Count}");
    var latest = confidence.FirstOrDefault();
    if (latest is not null)
    {
        timeline.Add($"{Stamp(start)} latest confidence: id={latest.Id}, sample={latest.SampleNumber}, scanType={latest.ScanType}, detected={latest.NumberOfDetectedSubstances}, display={latest.DisplayName}");
    }

    foreach (var line in timeline)
    {
        Console.WriteLine(line);
    }

    return;
}

if (args.Length > 0 && args[0] == "substances")
{
    var substances = await simulator.GetSubstancesAsync(new Empty());
    var hasConfidenceCheck = substances.Values.Contains("Confidence Check");
    Console.WriteLine($"substances={substances.Values.Count}");
    Console.WriteLine($"hasConfidenceCheck={hasConfidenceCheck}");
    Console.WriteLine($"first={string.Join(", ", substances.Values.Take(10))}");
    return;
}

if (args.Length > 0 && args[0] == "alarm")
{
    await WaitFor("services to answer", () => core.GetCurrentSampleCollectorStateAsync(new Empty()).ResponseAsync, _ => true, TimeSpan.FromSeconds(45));
    await Snapshot("alarm initial");

    await core.ClearAlertAsync(new Empty());
    var clearedInitial = await WaitAlert("initial clear no-alert", alert => !IsActiveAlert(alert), 20);
    var initialState = await ReadCollectorState();
    timeline.Add($"{Stamp(start)} initial clear alert: {DescribeAlert(clearedInitial)}, muted={initialState.IsAudioAlarmMuted}");

    var firstAlert = await CollectThreatSample("first", "Black powder");
    var firstState = await ReadCollectorState();
    timeline.Add($"{Stamp(start)} first alarm state: active={IsActiveAlert(firstAlert)}, muted={firstState.IsAudioAlarmMuted}");

    await core.MuteAlarmAsync(new Empty());
    var mutedState = await WaitFor("muted collector state", ReadCollectorState, s => s.IsAudioAlarmMuted, TimeSpan.FromSeconds(10));
    var mutedAlert = await WaitAlert("active alert remains after mute", IsActiveAlert, 10);
    timeline.Add($"{Stamp(start)} after mute: muted={mutedState.IsAudioAlarmMuted}, activeAlert={IsActiveAlert(mutedAlert)}, alert={DescribeAlert(mutedAlert)}");

    await core.ClearAlertAsync(new Empty());
    var clearedAlert = await WaitAlert("cleared no-alert", alert => !IsActiveAlert(alert), 20);
    var clearedState = await ReadCollectorState();
    timeline.Add($"{Stamp(start)} after clear: muted={clearedState.IsAudioAlarmMuted}, activeAlert={IsActiveAlert(clearedAlert)}, alert={DescribeAlert(clearedAlert)}");

    var secondAlert = await CollectThreatSample("second", "Black powder");
    var secondState = await ReadCollectorState();
    timeline.Add($"{Stamp(start)} second alarm state: active={IsActiveAlert(secondAlert)}, muted={secondState.IsAudioAlarmMuted}, alert={DescribeAlert(secondAlert)}");

    var pass =
        IsActiveAlert(firstAlert) &&
        mutedState.IsAudioAlarmMuted &&
        IsActiveAlert(mutedAlert) &&
        !IsActiveAlert(clearedAlert) &&
        clearedState.IsAudioAlarmMuted &&
        IsActiveAlert(secondAlert) &&
        !secondState.IsAudioAlarmMuted;

    Console.WriteLine(pass ? "RESULT: PASS" : "RESULT: FAIL");
    foreach (var line in timeline)
    {
        Console.WriteLine(line);
    }

    if (!pass)
    {
        Environment.ExitCode = 2;
    }

    return;
}

if (args.Length > 0 && args[0] == "alertquery")
{
    var state = await ReadCollectorState();
    var alert = await ReadLiveAlertOnce(TimeSpan.FromSeconds(10));
    Console.WriteLine($"muted={state.IsAudioAlarmMuted}");
    Console.WriteLine($"active={IsActiveAlert(alert)}");
    Console.WriteLine($"alert={DescribeAlert(alert)}");
    return;
}

if (args.Length > 0 && args[0] == "trigger")
{
    await WaitFor("services to answer", () => core.GetCurrentSampleCollectorStateAsync(new Empty()).ResponseAsync, _ => true, TimeSpan.FromSeconds(45));
    await Snapshot("trigger initial");
    var alert = await CollectThreatSample("trigger", "Black powder");
    var state = await ReadCollectorState();
    Console.WriteLine(IsActiveAlert(alert) ? "RESULT: PASS" : "RESULT: FAIL");
    timeline.Add($"{Stamp(start)} trigger final: muted={state.IsAudioAlarmMuted}, alert={DescribeAlert(alert)}");
    foreach (var line in timeline)
    {
        Console.WriteLine(line);
    }

    if (!IsActiveAlert(alert))
    {
        Environment.ExitCode = 2;
    }

    return;
}

if (args.Length > 0 && args[0] == "training")
{
    await WaitFor("services to answer", () => core.GetCurrentSampleCollectorStateAsync(new Empty()).ResponseAsync, _ => true, TimeSpan.FromSeconds(10));
    await Snapshot("training initial");

    var setScanType = await simulator.SetScanTypeAsync(new StringValue { Value = "MRM" });
    var setSubstance = await simulator.SetSubstanceAsync(new StringValue { Value = "Black powder" });
    timeline.Add($"{Stamp(start)} simulator setup: setScanTypeMRM={setScanType.Value}, setSubstanceBlackPowder={setSubstance.Value}");

    await core.StartAnalysisAsync(new AnalysisControlRequest { IsConfidenceCheck = false });
    timeline.Add($"{Stamp(start)} command: StartAnalysis(false)");

    await WaitCollector("training baseline ready", c =>
        c.CollectionState == "SampleCollecting" &&
        c.CollectorState == "CollectingBaseline" &&
        c.ReadyToCollectSample &&
        c.NumberOfBaselineScans >= 10, 30);
    await Snapshot("training ready");

    var insert = await simulator.InsertSampleAsync(new Empty());
    timeline.Add($"{Stamp(start)} command: InsertSample={insert.Value}");

    await WaitCollector("training collecting sample", c => c.CollectorState == "CollectingSample" && c.NumberOfAnalysisScans >= 5, 30);
    await Snapshot("training mid-analysis");

    foreach (var line in timeline)
    {
        Console.WriteLine(line);
    }

    return;
}

if (args.Length > 0 && args[0] == "remove")
{
    var remove = await simulator.RemoveSampleAsync(new BoolValue { Value = false });
    Console.WriteLine($"remove={remove.Value}");
    await Snapshot("after remove command");
    foreach (var line in timeline)
    {
        Console.WriteLine(line);
    }

    return;
}

try
{
await WaitFor("services to answer", () => core.GetCurrentSampleCollectorStateAsync(new Empty()).ResponseAsync, _ => true, TimeSpan.FromSeconds(45));

var before = await core.GetCollectedSamplesMetadataAsync(new Empty());
var beforeConfidence = before.Samples.Count(s => s.IsConfidenceCheck);
timeline.Add($"{Stamp(start)} metadata before: total={before.Samples.Count}, confidence={beforeConfidence}");

await Snapshot("initial");

await hardware.WakeUpInstrumentAsync(new Empty());
timeline.Add($"{Stamp(start)} command: WakeUpInstrument");

await WaitCollector("wake/baseline", c => c.CollectionState == "VerifyCalibration" && c.CollectorState == "CollectingBaseline" && c.NumberOfBaselineScans >= 1, 60);
await Snapshot("after wake");

var substances = await simulator.GetSubstancesAsync(new Empty());
var hasConfidenceCheck = substances.Values.Contains("Confidence Check");
var setScanType = await simulator.SetScanTypeAsync(new StringValue { Value = "MRM" });
var setSubstance = await simulator.SetSubstanceAsync(new StringValue { Value = "Confidence Check" });
timeline.Add($"{Stamp(start)} simulator setup: substances={substances.Values.Count}, hasConfidenceCheck={hasConfidenceCheck}, setScanTypeMRM={setScanType.Value}, setSubstanceConfidenceCheck={setSubstance.Value}");

await WaitCollector("baseline ready", c => c.CollectionState == "VerifyCalibration" && c.CollectorState == "CollectingBaseline" && c.NumberOfBaselineScans >= 10, 90);
await Snapshot("baseline ready");

var cid = await PollCidPressureMbar(TimeSpan.FromSeconds(15));
if (cid is not null)
{
    timeline.Add($"{Stamp(start)} CIDV_RB_PRES_MBAR: value={cid.Value:0.###}, lower={cid.LowerLimit:0.###}, upper={cid.UpperLimit:0.###}, ideal={cid.IdealSetpoint:0.###}, outOfRange={cid.IsOutOfRange}");
}
else
{
    timeline.Add($"{Stamp(start)} CIDV_RB_PRES_MBAR: no sensor snapshot observed");
}

var insert = await simulator.InsertSampleAsync(new Empty());
timeline.Add($"{Stamp(start)} command: InsertSample={insert.Value}");

await WaitCollector("collecting sample", c => c.CollectorState == "CollectingSample" && c.NumberOfAnalysisScans >= 1, 30);
await Task.Delay(TimeSpan.FromSeconds(2));
await Snapshot("after insert +2s");

await WaitCollector("analysis complete", c => c.CollectorState == "WaitingForSwabRemoval" && c.NumberOfAnalysisScans >= 23, 60);
await Snapshot("analysis complete");

await WaitFor("simulator ready for removal", async () =>
{
    var snap = await Snapshot("simulator ready for removal");
    return snap;
}, snap => snap.instrument.SwabClampState.ToString() == "SwabNeedsToBeRemoved" && snap.simState.CanRemoveSwab, TimeSpan.FromSeconds(15));
await Snapshot("remove ready");

var remove = await simulator.RemoveSampleAsync(new BoolValue { Value = false });
timeline.Add($"{Stamp(start)} command: RemoveSample={remove.Value}");

await WaitCollector("post remove", c => c.CollectionState == "SampleCollecting" && c.CollectorState == "CollectingBaseline" && !c.IsRunningConfidenceCheck, 90);
await Snapshot("after remove");

await WaitCollector("normal baseline ready", c =>
    c.CollectionState == "SampleCollecting" &&
    c.CollectorState == "CollectingBaseline" &&
    !c.IsRunningConfidenceCheck &&
    c.ReadyToCollectSample &&
    c.NumberOfBaselineScans >= 10, 60);
await Snapshot("normal ready to analyze");

await WaitFor("saved confidence metadata", async () => await core.GetCollectedSamplesMetadataAsync(new Empty()), r => r.Samples.Count(s => s.IsConfidenceCheck) >= beforeConfidence + 1, TimeSpan.FromSeconds(45));
var after = await core.GetCollectedSamplesMetadataAsync(new Empty());
var afterConfidence = after.Samples.Count(s => s.IsConfidenceCheck);
var newConfidence = after.Samples
    .Where(s => s.IsConfidenceCheck)
    .OrderByDescending(s => s.SampleNumber)
    .FirstOrDefault();

timeline.Add($"{Stamp(start)} metadata after: total={after.Samples.Count}, confidence={afterConfidence}, confidenceDelta={afterConfidence - beforeConfidence}");
if (newConfidence is not null)
{
    timeline.Add($"{Stamp(start)} saved sample: id={newConfidence.Id}, sample={newConfidence.SampleNumber}, scanType={newConfidence.ScanType}, detected={newConfidence.NumberOfDetectedSubstances}, display={newConfidence.DisplayName}");
}

var finalCore = await core.GetCurrentInstrumentStatusAsync(new Empty());
var finalCollector = await core.GetCurrentSampleCollectorStateAsync(new Empty());
var finalHardware = await hardware.GetCurrentInstrumentAsync(new Empty());
var pass =
    hasConfidenceCheck &&
    setScanType.Value &&
    setSubstance.Value &&
    insert.Value &&
    remove.Value &&
    afterConfidence == beforeConfidence + 1 &&
    newConfidence is not null &&
    newConfidence.ScanType == "MRM" &&
    newConfidence.NumberOfDetectedSubstances > 0 &&
    finalCollector.CollectionState == "SampleCollecting" &&
    finalCollector.CollectorState == "CollectingBaseline" &&
    !finalCollector.IsRunningConfidenceCheck &&
    finalCollector.ReadyToCollectSample &&
    finalCollector.NumberOfBaselineScans >= 10 &&
    finalHardware.CalibrationState.ToString() == "NoCalibrationNeeded" &&
    finalCore.Status.Message == "SampleCollecting";

Console.WriteLine(pass ? "RESULT: PASS" : "RESULT: FAIL");
foreach (var line in timeline)
{
    Console.WriteLine(line);
}

if (!pass)
{
    Environment.ExitCode = 2;
}
}
catch (Exception ex)
{
    Console.WriteLine("RESULT: FAIL");
    Console.WriteLine($"EXCEPTION: {ex.GetType().Name}: {ex.Message}");
    try
    {
        await Snapshot("failure snapshot");
    }
    catch (Exception snapshotEx)
    {
        timeline.Add($"{Stamp(start)} failure snapshot unavailable: {snapshotEx.GetType().Name}: {snapshotEx.Message}");
    }

    foreach (var line in timeline)
    {
        Console.WriteLine(line);
    }

    Environment.ExitCode = 2;
}
