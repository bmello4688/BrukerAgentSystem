param(
    [string]$BoardPath = "C:\Git\Commercial\MrmETDSpec\agent-os\product\status-board.md",
    [string]$StatePath = "C:\Git\Commercial\MrmETDSpec\agent-os\product\status-board.watcher.json",
    [string]$LastContentPath = "C:\Git\Commercial\MrmETDSpec\agent-os\product\status-board.watcher.last.txt",
    [string]$DiscordChannel = "channel:1511474561932071072"
)

$ErrorActionPreference = "Stop"

function Get-Sha256Hex {
    param([string]$Text)

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
    }
    finally {
        $sha.Dispose()
    }
}

function Read-State {
    if (-not (Test-Path -LiteralPath $StatePath)) {
        return [ordered]@{}
    }

    $raw = Get-Content -LiteralPath $StatePath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [ordered]@{}
    }

    $object = $raw | ConvertFrom-Json
    $state = [ordered]@{}
    foreach ($property in $object.PSObject.Properties) {
        $state[$property.Name] = $property.Value
    }

    return $state
}

function Write-State {
    param([System.Collections.IDictionary]$State)

    $json = $State | ConvertTo-Json -Depth 8
    Set-Content -LiteralPath $StatePath -Value $json -Encoding UTF8
}

function Format-StatusLineForDiscord {
    param([string]$Line)

    $clean = $Line.Trim()
    $clean = $clean -replace '^\-\s+', ''

    if ($clean -match '^\[[^\]]+\]\s+-\s+') {
        return "- $clean"
    }

    if ($clean -match '^(?<timestamp>\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}\s+[A-Z]{2,4})\s+-\s+(?<agent>[^-:]+?)\s+-\s+(?<status>.+)$') {
        return "- [$($Matches.agent.Trim())] - $($Matches.status.Trim())"
    }

    return "- $clean"
}

function Get-ChangedLineSummary {
    param(
        [string]$Previous,
        [string]$Current
    )

    $sensitive = '(?i)(secret|token|password|credential|api[_-]?key|private contact|runtime id|transcript)'
    $previousLines = @()
    if (-not [string]::IsNullOrEmpty($Previous)) {
        $previousLines = $Previous -split "`r?`n"
    }
    $currentLines = $Current -split "`r?`n"

    $added = Compare-Object -ReferenceObject $previousLines -DifferenceObject $currentLines |
        Where-Object { $_.SideIndicator -eq "=>" } |
        ForEach-Object { [string]$_.InputObject } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -notmatch $sensitive } |
        Select-Object -First 20

    if ($added.Count -gt 0) {
        return (($added | ForEach-Object { Format-StatusLineForDiscord -Line $_ }) -join [Environment]::NewLine)
    }

    $sections = $currentLines |
        Where-Object { $_ -match '^##\s+' } |
        ForEach-Object { $_ -replace '^##\s+', '' } |
        Select-Object -First 8

    if ($sections.Count -gt 0) {
        return "Changed sections: " + ($sections -join ", ")
    }

    return "The board changed, but no concise line diff was available."
}

function Notify-BoardChanged {
    $content = Get-Content -LiteralPath $BoardPath -Raw
    $hash = Get-Sha256Hex -Text $content
    $state = Read-State

    if ($state.lastPrintedSha256 -eq $hash) {
        return
    }

    $previousContent = ""
    if (Test-Path -LiteralPath $LastContentPath) {
        $previousContent = Get-Content -LiteralPath $LastContentPath -Raw
    }

    $summary = Get-ChangedLineSummary -Previous $previousContent -Current $content
    $message = "Shared Status Board Updated" + [Environment]::NewLine + [Environment]::NewLine + $summary
    & openclaw message send --channel discord --target $DiscordChannel --message $message | Out-Null

    $state.lastPrintedSha256 = $hash
    $state.lastPrintedAt = (Get-Date).ToString("o")
    $state.lastSummary = $summary
    $state.watcherPid = $PID
    $state.watcherMode = "local-file-system-watcher"
    Write-State -State $state
    [System.IO.File]::WriteAllText($LastContentPath, $content, [System.Text.Encoding]::UTF8)
}

$board = Get-Item -LiteralPath $BoardPath
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $board.DirectoryName
$watcher.Filter = $board.Name
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite, Size'
$watcher.EnableRaisingEvents = $true

try {
    Notify-BoardChanged

    while ($true) {
        $change = $watcher.WaitForChanged(
            [System.IO.WatcherChangeTypes]'Changed, Created, Renamed',
            1000
        )

        if ($change.TimedOut) {
            continue
        }

        Start-Sleep -Milliseconds 750
        try {
            Notify-BoardChanged
        }
        catch {
            $state = Read-State
            $state.lastWatcherErrorAt = (Get-Date).ToString("o")
            $state.lastWatcherError = $_.Exception.Message
            $state.watcherPid = $PID
            $state.watcherMode = "local-file-system-watcher"
            Write-State -State $state
        }
    }
}
finally {
    $watcher.Dispose()
}
