[CmdletBinding()]
param(
    [string]$CommonReportsPath = 'C:\Git\Common.Reports',
    [string]$TripleQuadUiPath = 'C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { $failures.Add($Message) }
}

function Assert-Equal($Expected, $Actual, [string]$Message) {
    if ($Expected -ne $Actual) { $failures.Add("$Message Expected '$Expected', actual '$Actual'.") }
}

function Get-Sha256([string]$Path) {
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return (([BitConverter]::ToString($sha256.ComputeHash([IO.File]::ReadAllBytes($Path))) -replace '-', '').ToLowerInvariant())
    }
    finally {
        $sha256.Dispose()
    }
}

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('shr030-' + [Guid]::NewGuid().ToString('N'))
try {
    & (Join-Path $root 'generate-capability-matrix.ps1') -OutputDirectory $tempRoot | Out-Null
    $generatedFiles = @(
        'capability-catalog.v1.json',
        'capability-matrix.v1.json',
        'capability-matrix.v1.csv',
        'fixtures\role-aliases.v1.csv',
        'fixtures\fail-closed-inputs.v1.json',
        'fixtures\dhs-capability-decisions.v1.json',
        'fixtures\triple-quad-ui-capability-decisions.v1.json'
    )
    foreach ($relativePath in $generatedFiles) {
        $expectedPath = Join-Path $root $relativePath
        $actualPath = Join-Path $tempRoot $relativePath
        Assert-True (Test-Path -LiteralPath $expectedPath) "Missing committed artifact $relativePath."
        if ((Test-Path -LiteralPath $expectedPath) -and (Test-Path -LiteralPath $actualPath)) {
            Assert-Equal (Get-Sha256 $actualPath) (Get-Sha256 $expectedPath) "Generated artifact differs: $relativePath."
        }
    }

    $catalog = Get-Content -Raw (Join-Path $root 'capability-catalog.v1.json') | ConvertFrom-Json
    $matrix = Get-Content -Raw (Join-Path $root 'capability-matrix.v1.json') | ConvertFrom-Json
    $csvRows = @(Import-Csv (Join-Path $root 'capability-matrix.v1.csv'))

    Assert-Equal 1 $catalog.schemaVersion 'Catalog schema version mismatch.'
    Assert-Equal 'bruker.user-management.capability-matrix.v1' $catalog.policyId 'Policy ID mismatch.'
    Assert-Equal 39 @($catalog.operations).Count 'Operation catalog must contain all SHR-014A operations.'
    Assert-Equal 33 @($catalog.capabilities).Count 'Capability catalog must contain 31 published and two planned capabilities.'
    Assert-Equal 3 @($catalog.roles).Count 'Exactly three selectable base roles are allowed.'
    Assert-Equal 4 @($catalog.bundles).Count 'Four bundle-set combinations are required.'
    Assert-Equal 5 @($catalog.policyStates).Count 'Five typed policy states are required.'
    Assert-Equal 11 @($catalog.targetScopePolicies).Count 'Target-scope policy catalog is incomplete.'
    Assert-Equal 11 @($catalog.targetScopePolicies.id | Select-Object -Unique).Count 'Target-scope policy IDs must be unique.'
    $selectableTargetRoles = @('operator','supervisor','administrator')
    foreach ($targetPolicy in $catalog.targetScopePolicies) {
        foreach ($targetRole in @($targetPolicy.allowedCurrentTargetRoles) + @($targetPolicy.allowedRequestedTargetRoles)) {
            Assert-True ($targetRole -in $selectableTargetRoles) "Target-scope policy $($targetPolicy.id) contains unknown role '$targetRole'."
        }
    }
    foreach ($operation in $catalog.operations) {
        foreach ($baseRole in $selectableTargetRoles) {
            $scopeId = $operation.targetScopePolicyByRole.$baseRole
            Assert-True (-not [string]::IsNullOrWhiteSpace($scopeId)) "Operation $($operation.operationId) has no target scope for $baseRole."
            Assert-True (@($catalog.targetScopePolicies | Where-Object { $_.id -eq $scopeId }).Count -eq 1) "Operation $($operation.operationId) has unknown target scope '$scopeId' for $baseRole."
            if ($operation.auditOrdinal -le 30) {
                Assert-Equal 'not-applicable' $scopeId "Non-user operation $($operation.operationId) must not declare managed-user target scope."
            }
            else {
                Assert-True ($scopeId -ne 'not-applicable') "Managed-user operation $($operation.operationId) must declare target scope for $baseRole."
            }
        }
    }

    $expectedRows = 3 * 4 * 39 * 5
    Assert-Equal $expectedRows $matrix.rowCount 'Canonical matrix rowCount mismatch.'
    Assert-Equal $expectedRows @($matrix.rows).Count 'Canonical JSON matrix is not exhaustive.'
    Assert-Equal $expectedRows $csvRows.Count 'CSV matrix is not exhaustive.'

    $keys = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($row in $matrix.rows) {
        $key = "$($row.baseRole)|$($row.bundleSet)|$($row.operationId)|$($row.policyState)"
        Assert-True ($keys.Add($key)) "Duplicate matrix decision $key."
        Assert-True ($row.roleDecision -in @('allowed','denied')) "Invalid role decision in $key."
        Assert-True ($row.effectiveDecision -in @('allowed','denied','reauthentication-required','policy-unavailable','prerequisite-unmet')) "Invalid effective decision in $key."
        Assert-True (-not [string]::IsNullOrWhiteSpace($row.guidanceCategory)) "Missing guidance in $key."
        Assert-True (-not [string]::IsNullOrWhiteSpace($row.retryDisposition)) "Missing retry disposition in $key."
        Assert-True (-not [string]::IsNullOrWhiteSpace($row.presentationProjection)) "Missing presentation projection in $key."
        Assert-True (-not [string]::IsNullOrWhiteSpace($row.targetScopePolicyId)) "Missing target-scope policy in $key."
        Assert-True (@($catalog.targetScopePolicies | Where-Object { $_.id -eq $row.targetScopePolicyId }).Count -eq 1) "Unknown target-scope policy in $key."
    }
    Assert-Equal $expectedRows $keys.Count 'Composite matrix key coverage mismatch.'

    $csvJson = @($csvRows | ForEach-Object {
        "$($_.baseRole)|$($_.bundleSet)|$($_.operationId)|$($_.policyState)|$($_.roleDecision)|$($_.targetScopePolicyId)|$($_.effectiveDecision)|$($_.guidanceCategory)|$($_.retryDisposition)|$($_.presentationProjection)|$($_.protectedContentDisposition)|$($_.focusDisposition)|$($_.statusAnnouncement)"
    })
    $canonicalJson = @($matrix.rows | ForEach-Object {
        "$($_.baseRole)|$($_.bundleSet)|$($_.operationId)|$($_.policyState)|$($_.roleDecision)|$($_.targetScopePolicyId)|$($_.effectiveDecision)|$($_.guidanceCategory)|$($_.retryDisposition)|$($_.presentationProjection)|$($_.protectedContentDisposition)|$($_.focusDisposition)|$($_.statusAnnouncement)"
    })
    Assert-Equal (($canonicalJson | Sort-Object) -join "`n") (($csvJson | Sort-Object) -join "`n") 'CSV and canonical JSON decisions differ.'

    $reportOperationIds = @(
        'report-surface-access','equipment-report-generation','event-report-generation',
        'user-report-generation','completed-report-view','report-export','report-print'
    )
    foreach ($operationId in $reportOperationIds) {
        foreach ($bundle in @($catalog.bundles.id)) {
            $operator = $matrix.rows | Where-Object { $_.operationId -eq $operationId -and $_.baseRole -eq 'operator' -and $_.bundleSet -eq $bundle -and $_.policyState -eq 'allowed' }
            $supervisor = $matrix.rows | Where-Object { $_.operationId -eq $operationId -and $_.baseRole -eq 'supervisor' -and $_.bundleSet -eq $bundle -and $_.policyState -eq 'allowed' }
            $administrator = $matrix.rows | Where-Object { $_.operationId -eq $operationId -and $_.baseRole -eq 'administrator' -and $_.bundleSet -eq $bundle -and $_.policyState -eq 'allowed' }
            Assert-Equal 'denied' $operator.roleDecision "Operator must be denied $operationId with $bundle."
            Assert-Equal 'allowed' $supervisor.roleDecision "Supervisor must be allowed $operationId with $bundle."
            Assert-Equal 'allowed' $administrator.roleDecision "Administrator must be allowed $operationId with $bundle."
        }
    }

    foreach ($bundle in @($catalog.bundles.id)) {
        $supervisorSsi = $matrix.rows | Where-Object { $_.operationId -eq 'ssi-statement-edit' -and $_.baseRole -eq 'supervisor' -and $_.bundleSet -eq $bundle -and $_.policyState -eq 'allowed' }
        $administratorSsi = $matrix.rows | Where-Object { $_.operationId -eq 'ssi-statement-edit' -and $_.baseRole -eq 'administrator' -and $_.bundleSet -eq $bundle -and $_.policyState -eq 'allowed' }
        Assert-Equal 'denied' $supervisorSsi.roleDecision "Supervisor must be denied SSI editing with $bundle."
        Assert-Equal 'allowed' $administratorSsi.roleDecision "Administrator must be allowed SSI editing with $bundle."
    }

    $reportActionAndSettingsIds = @(
        'equipment-report-generation','event-report-generation','user-report-generation',
        'report-export','report-print','print-settings-change','auto-print-settings-change','ssi-statement-edit'
    )
    $operationSpecificDeniedRows = @($matrix.rows | Where-Object {
        $_.operationId -in $reportActionAndSettingsIds -and
        $_.policyState -in @('allowed','denied') -and
        $_.effectiveDecision -eq 'denied'
    })
    Assert-True ($operationSpecificDeniedRows.Count -gt 0) 'Missing operation-specific denied report action/settings decisions.'
    foreach ($row in $operationSpecificDeniedRows) {
        Assert-Equal 'retain' $row.protectedContentDisposition "Operation-specific denial must retain authorized report content for $($row.baseRole)|$($row.operationId)|$($row.policyState)."
    }
    $contentAccessDeniedRows = @($matrix.rows | Where-Object {
        $_.operationId -in @('report-surface-access','completed-report-view') -and
        $_.policyState -in @('allowed','denied') -and
        $_.effectiveDecision -eq 'denied'
    })
    foreach ($row in $contentAccessDeniedRows) {
        Assert-Equal 'remove' $row.protectedContentDisposition "Report-content access denial must remove protected content for $($row.baseRole)|$($row.operationId)|$($row.policyState)."
    }

    $adminAllowed = @($matrix.rows | Where-Object { $_.baseRole -eq 'administrator' -and $_.bundleSet -eq 'none' -and $_.policyState -eq 'allowed' -and $_.roleDecision -eq 'allowed' })
    Assert-Equal 39 $adminAllowed.Count 'Administrator must use an explicit complete v1 operation set.'

    $aliases = @(Import-Csv (Join-Path $root 'fixtures\role-aliases.v1.csv'))
    Assert-Equal 10 $aliases.Count 'Alias fixture count mismatch.'
    Assert-Equal 3 @($aliases | Where-Object { $_.normalizedRole -in @('operator','supervisor','administrator') } | Select-Object -ExpandProperty normalizedRole -Unique).Count 'Alias fixtures must cover all base roles.'
    Assert-True (@($aliases | Where-Object { $_.input -eq 'Commissioning' -and $_.valid -eq 'False' }).Count -eq 1) 'Commissioning must not become a selectable base role.'

    $failClosed = Get-Content -Raw (Join-Path $root 'fixtures\fail-closed-inputs.v1.json') | ConvertFrom-Json
    Assert-Equal 13 @($failClosed.cases).Count 'Fail-closed fixture count mismatch.'
    foreach ($case in $failClosed.cases) { Assert-Equal 'deny' $case.expected "Fail-closed case $($case.id) does not deny." }
    Assert-Equal 'unknown-code' $failClosed.fallback.guidanceCategory 'Unknown-code fallback mismatch.'
    Assert-Equal 'do-not-retry' $failClosed.fallback.retryDisposition 'Unknown-code retry mismatch.'

    Assert-Equal 7 @($failClosed.presentationCases).Count 'Presentation fixture count mismatch.'
    foreach ($case in $failClosed.presentationCases) {
        Assert-Equal 'supervisor' $case.baseRole "Presentation fixture $($case.id) must use a report-authorized Supervisor."
        Assert-Equal $true $case.requiresReportAccess "Presentation fixture $($case.id) must require independent report access."
        $reportAccess = @($matrix.rows | Where-Object {
            $_.baseRole -eq $case.baseRole -and $_.bundleSet -eq 'none' -and
            $_.operationId -eq 'report-surface-access' -and $_.policyState -eq 'allowed'
        })
        Assert-Equal 1 $reportAccess.Count "Presentation fixture $($case.id) report-access proof did not resolve uniquely."
        if ($reportAccess.Count -eq 1) {
            Assert-Equal 'allowed' $reportAccess[0].roleDecision "Presentation fixture $($case.id) base role lacks report-access capability."
            Assert-Equal 'allowed' $reportAccess[0].effectiveDecision "Presentation fixture $($case.id) cannot establish an authorized report surface."
        }
        $matches = @($matrix.rows | Where-Object {
            $_.baseRole -eq $case.baseRole -and $_.bundleSet -eq 'none' -and
            $_.operationId -eq $case.operationId -and $_.policyState -eq $case.policyState
        })
        Assert-Equal 1 $matches.Count "Presentation fixture $($case.id) did not resolve uniquely."
        if ($matches.Count -eq 1) {
            Assert-Equal $case.expectedRoleDecision $matches[0].roleDecision "Role decision mismatch for presentation fixture $($case.id)."
            Assert-Equal 'denied' $matches[0].effectiveDecision "Presentation fixture $($case.id) must resolve to a denial."
            Assert-Equal $case.expectedProjection $matches[0].presentationProjection "Presentation projection mismatch for $($case.id)."
            Assert-Equal $case.expectedContentDisposition $matches[0].protectedContentDisposition "Protected-content disposition mismatch for $($case.id)."
        }
        if ($case.denialSource -eq 'policy') {
            Assert-Equal 'denied' $case.policyState "Policy-denial fixture $($case.id) must use the denied policy state."
            Assert-Equal 'allowed' $case.expectedRoleDecision "Policy-denial fixture $($case.id) must prove role authorization before policy denial."
        }
        elseif ($case.denialSource -eq 'role') {
            Assert-Equal 'allowed' $case.policyState "Role-denial fixture $($case.id) must use the allowed policy state."
            Assert-Equal 'denied' $case.expectedRoleDecision "Role-denial fixture $($case.id) must prove capability denial."
        }
        else {
            $failures.Add("Presentation fixture $($case.id) has unknown denial source '$($case.denialSource)'.")
        }
    }

    Assert-Equal 4 @($failClosed.targetScopeCases).Count 'Target-scope fixture count mismatch.'
    foreach ($case in $failClosed.targetScopeCases) {
        $matches = @($matrix.rows | Where-Object {
            $_.baseRole -eq $case.baseRole -and $_.bundleSet -eq 'none' -and
            $_.operationId -eq $case.operationId -and $_.policyState -eq 'allowed'
        })
        Assert-Equal 1 $matches.Count "Target-scope fixture $($case.id) did not resolve uniquely."
        if ($matches.Count -eq 1) {
            Assert-Equal $case.expectedRoleDecision $matches[0].roleDecision "Role decision mismatch for $($case.id)."
            Assert-Equal $case.expectedTargetScopePolicyId $matches[0].targetScopePolicyId "Target-scope policy mismatch for $($case.id)."
        }
    }

    $supervisorCreateScope = $catalog.targetScopePolicies | Where-Object { $_.id -eq 'supervisor-create-operator-no-specialist' }
    Assert-Equal 'operator' ($supervisorCreateScope.allowedRequestedTargetRoles -join ',') 'Supervisor create scope must allow only Operator targets.'
    Assert-Equal $false $supervisorCreateScope.mayChangeSpecialistCapabilities 'Supervisor create scope must prohibit specialist capabilities.'
    $supervisorEditScope = $catalog.targetScopePolicies | Where-Object { $_.id -eq 'supervisor-edit-operator-no-access-mutation' }
    Assert-Equal 'operator' ($supervisorEditScope.allowedCurrentTargetRoles -join ',') 'Supervisor edit scope must allow only Operator targets.'
    Assert-Equal 'operator' ($supervisorEditScope.allowedRequestedTargetRoles -join ',') 'Supervisor edit scope must retain the Operator role.'
    Assert-Equal $false $supervisorEditScope.mayChangeBaseRole 'Supervisor edit scope must prohibit role changes.'
    Assert-Equal $false $supervisorEditScope.mayChangeSpecialistCapabilities 'Supervisor edit scope must prohibit specialist-capability changes.'
    $administratorMutationScope = $catalog.targetScopePolicies | Where-Object { $_.id -eq 'administrator-selectable-target-mutation' }
    Assert-Equal 'deny' $administratorMutationScope.selfAccessMutation 'Administrator managed-user mutations must deny self-access mutation.'
    Assert-Equal 'preserve' $administratorMutationScope.finalActiveAdministrator 'Administrator managed-user mutations must preserve a final active Administrator.'

    $matrixHash = Get-Sha256 (Join-Path $root 'capability-matrix.v1.json')
    $failClosedHash = Get-Sha256 (Join-Path $root 'fixtures\fail-closed-inputs.v1.json')
    $dhs = Get-Content -Raw (Join-Path $root 'fixtures\dhs-capability-decisions.v1.json') | ConvertFrom-Json
    $tq = Get-Content -Raw (Join-Path $root 'fixtures\triple-quad-ui-capability-decisions.v1.json') | ConvertFrom-Json
    foreach ($fixture in @($dhs, $tq)) {
        Assert-Equal $matrixHash $fixture.canonicalMatrixSha256 "$($fixture.productId) fixture hash mismatch."
        Assert-Equal '../capability-matrix.v1.json' $fixture.decisionSource "$($fixture.productId) decision source mismatch."
        Assert-Equal $failClosedHash $fixture.failClosedSha256 "$($fixture.productId) fail-closed fixture hash mismatch."
        Assert-Equal $expectedRows $fixture.scenarioCount "$($fixture.productId) scenario count mismatch."
        Assert-Equal ((@($catalog.operations.operationId) | Sort-Object) -join ',') ((@($fixture.operations) | Sort-Object) -join ',') "$($fixture.productId) operation coverage mismatch."
    }
    Assert-Equal $dhs.canonicalMatrixSha256 $tq.canonicalMatrixSha256 'DHS and TripleQuadUI parity hashes differ.'
    Assert-Equal $dhs.failClosedSha256 $tq.failClosedSha256 'DHS and TripleQuadUI fail-closed hashes differ.'
    Assert-Equal ($dhs.semanticFields -join ',') ($tq.semanticFields -join ',') 'DHS and TripleQuadUI semantic fields differ.'
    Assert-Equal 'unknown-code' $dhs.unknownCodeFallback.guidanceCategory 'DHS unknown-code fallback mismatch.'
    Assert-Equal 'unknown-code' $tq.unknownCodeFallback.guidanceCategory 'TripleQuadUI unknown-code fallback mismatch.'

    $auditTaxonomyPath = Join-Path $CommonReportsPath 'Reports.Fdrs.Contracts\AuditTaxonomy.cs'
    Assert-True (Test-Path -LiteralPath $auditTaxonomyPath) "Missing published SHR-014A taxonomy at $auditTaxonomyPath."
    if (Test-Path -LiteralPath $auditTaxonomyPath) {
        $auditSource = Get-Content -Raw $auditTaxonomyPath
        foreach ($operation in $catalog.operations) {
            $pattern = '(?m)^\s*' + [Regex]::Escape($operation.auditName) + '\s*=\s*' + $operation.auditOrdinal + ',?\s*$'
            Assert-True ([Regex]::IsMatch($auditSource, $pattern)) "SHR-014A operation mismatch: $($operation.auditName)=$($operation.auditOrdinal)."
        }
    }

    $rightsPath = Join-Path $TripleQuadUiPath 'CommonLibraries\Services\UserManagement\UserManagement.Service\UserRights.cs'
    $protoPath = Join-Path $TripleQuadUiPath 'CommonLibraries\Services\UserManagement\Protos\UserManagement.proto'
    Assert-True (Test-Path -LiteralPath $rightsPath) "Missing UserRights source at $rightsPath."
    Assert-True (Test-Path -LiteralPath $protoPath) "Missing User Management proto at $protoPath."
    if ((Test-Path -LiteralPath $rightsPath) -and (Test-Path -LiteralPath $protoPath)) {
        $rightsSource = Get-Content -Raw $rightsPath
        $protoSource = Get-Content -Raw $protoPath
        foreach ($capability in @($catalog.capabilities | Where-Object { $_.status -like 'published*' -and $_.status -notlike '*bundle-marker*' })) {
            if ($capability.bit -le 28) {
                $pattern = [Regex]::Escape($capability.id) + '\s*=\s*1UL\s*<<\s*' + $capability.bit
                Assert-True ([Regex]::IsMatch($rightsSource, $pattern)) "Published capability bit changed: $($capability.id)."
            }
        }
        Assert-True (-not [Regex]::IsMatch($rightsSource, 'CanExportReports\s*=')) 'SHR-030 must not modify UserRights source.'
        Assert-True (-not [Regex]::IsMatch($rightsSource, 'CanPrintReports\s*=')) 'SHR-030 must not modify UserRights source.'
        Assert-True (-not [Regex]::IsMatch($protoSource, 'can_export_reports')) 'SHR-030 must not modify the proto.'
        Assert-True (-not [Regex]::IsMatch($protoSource, 'can_print_reports')) 'SHR-030 must not modify the proto.'
    }

    $schemaPath = Join-Path $root 'capability-matrix.v1.schema.json'
    Assert-True (Test-Path -LiteralPath $schemaPath) 'Missing canonical matrix JSON schema.'
    if (Test-Path -LiteralPath $schemaPath) {
        $schema = Get-Content -Raw $schemaPath | ConvertFrom-Json
        Assert-Equal 'https://json-schema.org/draft/2020-12/schema' $schema.'$schema' 'Unexpected JSON Schema dialect.'
        Assert-Equal 1 $schema.properties.schemaVersion.const 'Schema must freeze version 1.'
        Assert-Equal 18 @($schema.'$defs'.decision.required).Count 'Decision schema must require all 18 semantic fields.'
    }
}
finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    throw "SHR-030 validation failed with $($failures.Count) finding(s)."
}

Write-Output 'SHR-030 validation passed.'
Write-Output '  39 operations aligned with published SHR-014A.'
Write-Output '  2,340 exhaustive role/bundle/operation/policy decisions.'
Write-Output '  Canonical CSV/JSON and DHS/TripleQuadUI parity fixtures match.'
Write-Output '  Alias, bundle-only, conflicting-role, unknown-bit, unknown-code, and presentation rules fail closed.'
Write-Output '  Managed-user target-role and access-mutation scope is explicit and fail closed.'
