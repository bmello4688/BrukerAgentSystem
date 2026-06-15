param(
    [Alias("RepoRoot")]
    [string]$AgentSystemRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ApplicationRepoRoot,
    [string]$OpenClawWorkspaceRoot,
    [string]$Model = "openai/gpt-5.5",
    [switch]$SkipSetup,
    [switch]$SkipAgentRegistration,
    [switch]$RecreateExistingAgents,
    [switch]$AcceptRisk
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Get-NormalizedPath {
    param([Parameter(Mandatory)][object]$Path)

    $pathText = if ($Path -is [array]) {
        [string]($Path | Select-Object -Last 1)
    } else {
        [string]$Path
    }

    $pathText = $pathText.Trim()
    $providerPath = $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($pathText)
    [System.IO.Path]::GetFullPath($providerPath)
}

function Invoke-OpenClaw {
    param([Parameter(Mandatory)][string[]]$Arguments)

    & openclaw @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "openclaw $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Copy-IfPresent {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$DestinationPath
    )

    if (Test-Path -LiteralPath $SourcePath -PathType Leaf) {
        Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
    }
}

$agentSystemRootPath = Get-NormalizedPath $AgentSystemRoot
if (-not (Test-Path -LiteralPath $agentSystemRootPath -PathType Container)) {
    throw "Agent system root does not exist: $agentSystemRootPath"
}

if (-not $ApplicationRepoRoot) {
    $ApplicationRepoRoot = Join-Path $agentSystemRootPath "source\TripleQuadUI"
}
$applicationRepoRootPath = Get-NormalizedPath $ApplicationRepoRoot
if (-not (Test-Path -LiteralPath $applicationRepoRootPath -PathType Container)) {
    throw "Application repo root does not exist: $applicationRepoRootPath"
}

if (-not $OpenClawWorkspaceRoot) {
    $OpenClawWorkspaceRoot = Join-Path $agentSystemRootPath ".openclaw\role-workspaces"
}
$workspaceRootPath = Get-NormalizedPath $OpenClawWorkspaceRoot

$openClawCommand = Get-Command openclaw -ErrorAction SilentlyContinue
if (-not $openClawCommand) {
    throw "OpenClaw CLI was not found on PATH. Install OpenClaw or open a shell where 'openclaw' is available."
}

$rolePromptDir = Join-Path $agentSystemRootPath ".orchestration\agents"
$sharedWorkspaceDir = Join-Path $agentSystemRootPath ".openclaw\workspace"
$roles = @(
    @{
        Id = "product-owner"
        DisplayName = "Product Owner"
        DashboardName = "TripleQuadUI(product-owner)"
        Prompt = "product-owner.md"
    },
    @{
        Id = "domain-analyst"
        DisplayName = "Domain Analyst"
        DashboardName = "TripleQuadUI(domain-analyst)"
        Prompt = "domain-analyst.md"
    },
    @{
        Id = "user-experience"
        DisplayName = "User Experience"
        DashboardName = "TripleQuadUI(user-experience)"
        Prompt = "user-experience.md"
    },
    @{
        Id = "coordinator-architect"
        DisplayName = "Coordinator Architect"
        DashboardName = "TripleQuadUI(coordinator-architect)"
        Prompt = "coordinator-architect.md"
    },
    @{
        Id = "feature-engineer"
        DisplayName = "Feature Engineer"
        DashboardName = "TripleQuadUI(feature-engineer)"
        Prompt = "feature-engineer.md"
    },
    @{
        Id = "reviewer-integration"
        DisplayName = "Reviewer Integration"
        DashboardName = "TripleQuadUI(reviewer-integration)"
        Prompt = "reviewer-integration.md"
    }
)

foreach ($role in $roles) {
    $promptPath = Join-Path $rolePromptDir $role.Prompt
    if (-not (Test-Path -LiteralPath $promptPath -PathType Leaf)) {
        throw "Missing role prompt for $($role.Id): $promptPath"
    }
}

New-Item -ItemType Directory -Path $workspaceRootPath -Force | Out-Null

foreach ($role in $roles) {
    $roleWorkspace = Join-Path $workspaceRootPath $role.Id
    New-Item -ItemType Directory -Path $roleWorkspace -Force | Out-Null

    Copy-IfPresent -SourcePath (Join-Path $sharedWorkspaceDir "IDENTITY.md") -DestinationPath (Join-Path $roleWorkspace "IDENTITY.md")
    Copy-IfPresent -SourcePath (Join-Path $sharedWorkspaceDir "SOUL.md") -DestinationPath (Join-Path $roleWorkspace "SOUL.md")
    Copy-IfPresent -SourcePath (Join-Path $sharedWorkspaceDir "TOOLS.md") -DestinationPath (Join-Path $roleWorkspace "TOOLS.md")
    Copy-IfPresent -SourcePath (Join-Path $sharedWorkspaceDir "USER.md") -DestinationPath (Join-Path $roleWorkspace "USER.md")
    Copy-IfPresent -SourcePath (Join-Path $sharedWorkspaceDir "MEMORY.md") -DestinationPath (Join-Path $roleWorkspace "MEMORY.md")

    $rolePrompt = Get-Content -LiteralPath (Join-Path $rolePromptDir $role.Prompt) -Raw
    $agentsPath = Join-Path $roleWorkspace "AGENTS.md"
    @"
# TripleQuadUI $($role.DisplayName)

This is an OpenClaw isolated-agent workspace generated from:

- Agent system root: $agentSystemRootPath
- Application Git repo: $applicationRepoRootPath
- Role prompt: .orchestration/agents/$($role.Prompt)

Use the agent system root as the source of truth for product context, standards, orchestration files, and role prompts.
When working on application code, operate in $applicationRepoRootPath unless the user explicitly names a different path.
Do not commit the agent system files to the Bruker Detection repo.

$rolePrompt
"@ | Set-Content -LiteralPath $agentsPath -Encoding UTF8
}

if (-not $SkipSetup) {
    $configuredWorkspace = $null
    $configuredWorkspaceOutput = & openclaw config get agents.defaults.workspace 2>$null
    if ($LASTEXITCODE -eq 0 -and $configuredWorkspaceOutput) {
        $configuredWorkspace = Get-NormalizedPath $configuredWorkspaceOutput
    }

    if ($configuredWorkspace -eq $agentSystemRootPath) {
        Write-Host "OpenClaw default workspace already configured: $agentSystemRootPath"
    } elseif ($configuredWorkspace) {
        Write-Host "Updating OpenClaw default workspace: $agentSystemRootPath"
        Invoke-OpenClaw -Arguments @("config", "set", "agents.defaults.workspace", $agentSystemRootPath)
        Invoke-OpenClaw -Arguments @("config", "validate")
    } elseif ($AcceptRisk) {
        Write-Host "Creating OpenClaw config and default workspace: $agentSystemRootPath"
        Invoke-OpenClaw -Arguments @(
            "onboard",
            "--workspace", $agentSystemRootPath,
            "--non-interactive",
            "--accept-risk",
            "--auth-choice", "skip",
            "--skip-channels",
            "--skip-daemon",
            "--skip-health",
            "--skip-ui"
        )
    } else {
        throw "OpenClaw is not configured yet. Run OpenClaw onboarding first, or rerun this script with -AcceptRisk to let it create baseline config with auth skipped."
    }
}

if (-not $SkipAgentRegistration) {
    $agentsJson = & openclaw agents list --json
    if ($LASTEXITCODE -ne 0) {
        throw "openclaw agents list --json failed with exit code $LASTEXITCODE"
    }
    $agentsJsonText = $agentsJson -join [Environment]::NewLine
    $existingAgents = foreach ($agent in ($agentsJsonText | ConvertFrom-Json)) {
        $agent
    }

    foreach ($role in $roles) {
        $roleWorkspace = Join-Path $workspaceRootPath $role.Id
        $existing = $existingAgents | Where-Object { $_.id -eq $role.Id } | Select-Object -First 1

        if ($existing) {
            $existingWorkspace = Get-NormalizedPath $existing.workspace
            $expectedWorkspace = Get-NormalizedPath $roleWorkspace
            if ($existingWorkspace -eq $expectedWorkspace) {
                Write-Host "OpenClaw agent already registered: $($role.Id)"
                $existingDashboardName = if ($existing.PSObject.Properties.Name -contains "identityName") {
                    $existing.identityName
                } else {
                    $existing.name
                }
                if ($existingDashboardName -ne $role.DashboardName) {
                    Write-Host "Updating OpenClaw agent display name: $($role.Id) -> $($role.DashboardName)"
                    Invoke-OpenClaw -Arguments @(
                        "agents", "set-identity",
                        "--agent", $role.Id,
                        "--name", $role.DashboardName
                    )
                }
                continue
            }

            if (-not $RecreateExistingAgents) {
                Write-Warning "OpenClaw agent '$($role.Id)' already exists with workspace '$existingWorkspace'. Expected '$expectedWorkspace'. Rerun with -RecreateExistingAgents to delete and recreate that registration."
                continue
            }

            Write-Host "Recreating OpenClaw agent with corrected workspace: $($role.Id)"
            Invoke-OpenClaw -Arguments @("agents", "delete", $role.Id, "--force")
        }

        Write-Host "Adding OpenClaw agent: $($role.Id)"
        Invoke-OpenClaw -Arguments @(
            "agents", "add", $role.Id,
            "--workspace", $roleWorkspace,
            "--model", $Model,
            "--non-interactive"
        )
        Invoke-OpenClaw -Arguments @(
            "agents", "set-identity",
            "--agent", $role.Id,
            "--name", $role.DashboardName
        )
    }
}

Write-Host ""
Write-Host "Configured OpenClaw agents:"
Invoke-OpenClaw -Arguments @("agents", "list")
