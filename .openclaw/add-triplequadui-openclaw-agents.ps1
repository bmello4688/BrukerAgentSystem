param(
    [string]$Model = "openai/gpt-5.5",
    [switch]$SkipSetup,
    [switch]$SkipAgentRegistration,
    [switch]$RecreateExistingAgents,
    [switch]$AcceptRisk
)

$ErrorActionPreference = "Stop"

$agentSystemRoot = Split-Path -Parent $PSScriptRoot
$applicationRepoRoot = Join-Path $agentSystemRoot "source\TripleQuadUI"
$scriptPath = Join-Path $PSScriptRoot "CreateOpenClawWorkspace.ps1"

& $scriptPath `
    -AgentSystemRoot $agentSystemRoot `
    -ApplicationRepoRoot $applicationRepoRoot `
    -Model $Model `
    -SkipSetup:$SkipSetup `
    -SkipAgentRegistration:$SkipAgentRegistration `
    -RecreateExistingAgents:$RecreateExistingAgents `
    -AcceptRisk:$AcceptRisk
