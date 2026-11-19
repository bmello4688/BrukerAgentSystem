[CmdletBinding()]
param(
    [string]$OutputDirectory = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Capability {
    param(
        [string]$Id,
        [int]$Bit,
        [string]$Status,
        [string]$ProtoField,
        [string]$Description
    )

    [pscustomobject][ordered]@{
        id = $Id
        bit = $Bit
        maskHex = ('0x{0:X16}' -f ([uint64]1 -shl $Bit))
        status = $Status
        protoField = $ProtoField
        description = $Description
    }
}

function New-Operation {
    param(
        [int]$Ordinal,
        [string]$AuditName,
        [string]$Id,
        [string]$Description,
        [string[]]$Capabilities,
        [ValidateSet('all', 'any')][string]$Mode = 'all',
        [string]$Boundary = 'authoritative-service-before-operation',
        [string]$Evidence = 'FRD-133-APPENDIX-C+CURRENT-RESOLVER-BASELINE-2026-11-19',
        [System.Collections.IDictionary]$TargetScopeByRole = $null
    )

    if ($null -eq $TargetScopeByRole) {
        $TargetScopeByRole = [ordered]@{
            operator = 'not-applicable'
            supervisor = 'not-applicable'
            administrator = 'not-applicable'
        }
    }

    $expression = if ($Mode -eq 'any') {
        'Any(' + ($Capabilities -join ',') + ')'
    } else {
        $Capabilities -join ' && '
    }

    [pscustomobject][ordered]@{
        auditOrdinal = $Ordinal
        auditName = $AuditName
        operationId = $Id
        description = $Description
        capabilityExpression = $expression
        requiredCapabilities = @($Capabilities)
        expressionMode = $Mode
        targetScopePolicyByRole = [pscustomobject]$TargetScopeByRole
        enforcementBoundary = $Boundary
        evidenceId = $Evidence
    }
}

function Test-OperationAllowed {
    param($Operation, [System.Collections.Generic.HashSet[string]]$EffectiveCapabilities)

    if ($Operation.expressionMode -eq 'any') {
        foreach ($capability in $Operation.requiredCapabilities) {
            if ($EffectiveCapabilities.Contains($capability)) { return $true }
        }
        return $false
    }

    foreach ($capability in $Operation.requiredCapabilities) {
        if (-not $EffectiveCapabilities.Contains($capability)) { return $false }
    }
    return $true
}

function Get-DecisionProjection {
    param($Operation, [bool]$RoleAllowed, [string]$PolicyState)

    $isReportContentAccessOperation = $Operation.operationId -in @(
        'report-surface-access',
        'completed-report-view'
    )
    $isReportRelatedOperation = $Operation.operationId -in @(
        'report-surface-access',
        'equipment-report-generation',
        'event-report-generation',
        'user-report-generation',
        'completed-report-view',
        'report-export',
        'report-print',
        'print-settings-change',
        'auto-print-settings-change',
        'ssi-statement-edit'
    )

    if (-not $RoleAllowed -or $PolicyState -eq 'denied') {
        $projection = if ($Operation.operationId -eq 'report-surface-access') {
            'hidden-reject-deep-link'
        } elseif ($isReportContentAccessOperation -and -not $RoleAllowed) {
            'absent-with-protected-surface'
        } else {
            'visible-disabled'
        }
        return [pscustomobject][ordered]@{
            effectiveDecision = 'denied'
            guidanceCategory = 'authorization-denied'
            retryDisposition = 'do-not-retry'
            presentationProjection = $projection
            protectedContentDisposition = if ($isReportContentAccessOperation) { 'remove' } else { 'retain' }
            focusDisposition = 'restore-stable-target'
            statusAnnouncement = 'announce-neutral-denial'
        }
    }

    switch ($PolicyState) {
        'allowed' {
            return [pscustomobject][ordered]@{
                effectiveDecision = 'allowed'
                guidanceCategory = 'none'
                retryDisposition = 'none'
                presentationProjection = 'visible-enabled'
                protectedContentDisposition = 'retain'
                focusDisposition = 'preserve'
                statusAnnouncement = 'none'
            }
        }
        'reauthentication-required' {
            return [pscustomobject][ordered]@{
                effectiveDecision = 'reauthentication-required'
                guidanceCategory = 'reauthenticate'
                retryDisposition = 'reauthenticate'
                presentationProjection = 'visible-disabled'
                protectedContentDisposition = if ($isReportRelatedOperation) { 'remove' } else { 'retain' }
                focusDisposition = 'restore-stable-target'
                statusAnnouncement = 'announce-neutral-reauthentication'
            }
        }
        'policy-unavailable' {
            return [pscustomobject][ordered]@{
                effectiveDecision = 'policy-unavailable'
                guidanceCategory = 'retry-when-ready'
                retryDisposition = 'retry'
                presentationProjection = 'visible-disabled'
                protectedContentDisposition = if ($isReportRelatedOperation) { 'remove' } else { 'retain' }
                focusDisposition = 'restore-stable-target'
                statusAnnouncement = 'announce-neutral-unavailable'
            }
        }
        'prerequisite-unmet' {
            return [pscustomobject][ordered]@{
                effectiveDecision = 'prerequisite-unmet'
                guidanceCategory = 'correct-input'
                retryDisposition = 'correct-request'
                presentationProjection = 'visible-disabled-prerequisite'
                protectedContentDisposition = 'retain'
                focusDisposition = 'preserve'
                statusAnnouncement = 'announce-neutral-prerequisite'
            }
        }
        default { throw "Unsupported policy state '$PolicyState'." }
    }
}

$capabilities = @(
    New-Capability 'CanShutdownReboot' 0 'published' 'can_shutdown_reboot:1' 'Shut down or reboot the instrument.'
    New-Capability 'CanLogonLogoff' 1 'published' 'can_logon_logoff:2' 'Start or end an authenticated session.'
    New-Capability 'CanAnalyzeSamples' 2 'published' 'can_analyze_samples:3' 'Analyze samples.'
    New-Capability 'CanAccessAlarms' 3 'published' 'can_access_alarms:4' 'Access alarm information.'
    New-Capability 'CanEditAudibleAlarms' 4 'published' 'can_edit_audible_alarms:5' 'Change audible-alarm settings.'
    New-Capability 'CanViewSubstanceLibrary' 5 'published' 'can_view_substance_library:6' 'View the substance library.'
    New-Capability 'CanEditSubstanceLibrary' 6 'published' 'can_edit_substance_library:7' 'Edit the substance library.'
    New-Capability 'CanSelectDetectionAlgorithm' 7 'published' 'can_select_detection_algorithm:8' 'Select a detection algorithm.'
    New-Capability 'CanDoSubstanceTraining' 8 'published' 'can_do_substance_training:9' 'Train substances.'
    New-Capability 'CanEnableDisablePrinting' 9 'published' 'can_EnableDisablePrinting:10' 'Manage printing and auto-print settings.'
    New-Capability 'CanAccessInstrumentConfiguration' 10 'published' 'can_AccessInstrumentConfiguration:11' 'Change instrument configuration.'
    New-Capability 'CanAccessSamplingDataSystemStatus' 11 'published' 'can_AccessSamplingDataSystemStatus:12' 'View sampling-data system status.'
    New-Capability 'CanAccessReports' 12 'published-disabled' 'can_AccessReports:13' 'Enter, generate, and view reports.'
    New-Capability 'CanEditSecurityFooter' 13 'published' 'can_EditSecurityFooter:14' 'Edit the controlled SSI statement.'
    New-Capability 'CanDoMaintenance' 14 'published' 'can_do_maintenance:15' 'Execute maintenance.'
    New-Capability 'CanCleanSystem' 15 'published' 'can_clean_system:16' 'Clean the system.'
    New-Capability 'CanAutoCalibrate' 16 'published' 'can_auto_calibrate:17' 'Run automatic calibration.'
    New-Capability 'CanManuallyCalibrate' 17 'published' 'can_manually_calibrate:18' 'Run manual calibration.'
    New-Capability 'CanManageData' 18 'published' 'can_manage_data:19' 'Manage retained data.'
    New-Capability 'CanCopyDataToUsb' 19 'published' 'can_copy_data_to_usb:20' 'Copy sampling data to attached storage.'
    New-Capability 'CanExportSamplingData' 20 'published' 'can_export_sampling_data:21' 'Export sampling data.'
    New-Capability 'CanUpgradeSoftware' 21 'published' 'can_upgrade_software:22' 'Upgrade software.'
    New-Capability 'CanViewSystemFolders' 22 'published' 'can_view_system_folders:23' 'View approved system folders.'
    New-Capability 'CanManageAdministrators' 23 'published' 'can_manage_administrators:24' 'Manage administrator accounts.'
    New-Capability 'CanManageScreeningStaff' 24 'published' 'can_manage_screening_staff:25' 'Manage screening-staff accounts.'
    New-Capability 'CanManageServiceTechs' 25 'published' 'can_manage_service_techs:26' 'Manage service-technician accounts.'
    New-Capability 'CanManageSuperusers' 26 'published' 'can_manage_superusers:27' 'Manage legacy superuser accounts.'
    New-Capability 'CanManageTesters' 27 'published' 'can_manage_testers:28' 'Manage tester accounts.'
    New-Capability 'CanEditUserRole' 28 'published' 'can_edit_user_role:29' 'Change a managed user role.'
    New-Capability 'HasLabQaTools' 29 'published-bundle-marker' 'user_details.has_lab_qa_tools:14' 'Select the Lab/QA compatibility bundle.'
    New-Capability 'HasServiceMaintenanceTools' 30 'published-bundle-marker' 'user_details.has_service_maintenance_tools:15' 'Select the Service/Maintenance compatibility bundle.'
    New-Capability 'CanExportReports' 31 'planned-append-only' 'access_policy.can_export_reports:31' 'Export a controlled report.'
    New-Capability 'CanPrintReports' 32 'planned-append-only' 'access_policy.can_print_reports:32' 'Submit a controlled report to a printer.'
)

$operatorCapabilities = @(
    'CanLogonLogoff', 'CanAnalyzeSamples', 'CanAccessAlarms', 'CanViewSubstanceLibrary'
)
$supervisorCapabilities = @(
    $operatorCapabilities + @(
        'CanShutdownReboot', 'CanEditAudibleAlarms', 'CanEnableDisablePrinting',
        'CanAccessSamplingDataSystemStatus', 'CanAccessReports', 'CanManageData',
        'CanCopyDataToUsb', 'CanExportSamplingData', 'CanManageScreeningStaff',
        'CanEditUserRole', 'CanExportReports', 'CanPrintReports'
    )
)
$administratorCapabilities = @(
    $capabilities |
        Where-Object { $_.status -notlike '*bundle-marker*' } |
        ForEach-Object { $_.id }
)

$roles = @(
    [pscustomobject][ordered]@{ id = 'operator'; displayName = 'Operator'; capabilityIds = @($operatorCapabilities); evidenceId = 'FRD-133-APPENDIX-C+OWNER-ATTESTATION-2026-11-18' }
    [pscustomobject][ordered]@{ id = 'supervisor'; displayName = 'Supervisor'; capabilityIds = @($supervisorCapabilities); evidenceId = 'FRD-133-APPENDIX-C+OWNER-ATTESTATION-2026-11-18' }
    [pscustomobject][ordered]@{ id = 'administrator'; displayName = 'Administrator'; capabilityIds = @($administratorCapabilities); evidenceId = 'FRD-133-APPENDIX-C+OWNER-ATTESTATION-2026-11-18' }
)

$bundles = @(
    [pscustomobject][ordered]@{ id = 'none'; capabilityIds = @(); evidenceId = 'OWNER-ATTESTATION-2026-11-18' }
    [pscustomobject][ordered]@{ id = 'lab-qa'; capabilityIds = @('CanViewSubstanceLibrary','CanEditSubstanceLibrary','CanSelectDetectionAlgorithm','CanDoSubstanceTraining','CanAccessInstrumentConfiguration','CanAccessSamplingDataSystemStatus'); evidenceId = 'CURRENT-RESOLVER-BASELINE-2026-11-19' }
    [pscustomobject][ordered]@{ id = 'service-maintenance'; capabilityIds = @('CanAccessInstrumentConfiguration','CanAccessSamplingDataSystemStatus','CanDoMaintenance','CanCleanSystem','CanAutoCalibrate','CanManuallyCalibrate','CanUpgradeSoftware','CanViewSystemFolders'); evidenceId = 'CURRENT-RESOLVER-BASELINE-2026-11-19' }
    [pscustomobject][ordered]@{ id = 'lab-qa+service-maintenance'; capabilityIds = @('CanViewSubstanceLibrary','CanEditSubstanceLibrary','CanSelectDetectionAlgorithm','CanDoSubstanceTraining','CanAccessInstrumentConfiguration','CanAccessSamplingDataSystemStatus','CanDoMaintenance','CanCleanSystem','CanAutoCalibrate','CanManuallyCalibrate','CanUpgradeSoftware','CanViewSystemFolders'); evidenceId = 'CURRENT-RESOLVER-BASELINE-2026-11-19' }
)

$targetScopePolicies = @(
    [pscustomobject][ordered]@{
        id = 'not-applicable'; appliesTo = 'none'; allowedCurrentTargetRoles = @(); allowedRequestedTargetRoles = @()
        mayChangeBaseRole = $false; mayChangeSpecialistCapabilities = $false
        selfAccessMutation = 'not-applicable'; finalActiveAdministrator = 'not-applicable'
    }
    [pscustomobject][ordered]@{
        id = 'deny'; appliesTo = 'managed-user'; allowedCurrentTargetRoles = @(); allowedRequestedTargetRoles = @()
        mayChangeBaseRole = $false; mayChangeSpecialistCapabilities = $false
        selfAccessMutation = 'deny'; finalActiveAdministrator = 'preserve'
    }
    [pscustomobject][ordered]@{
        id = 'supervisor-operator-target-read'; appliesTo = 'current-target'; allowedCurrentTargetRoles = @('operator'); allowedRequestedTargetRoles = @()
        mayChangeBaseRole = $false; mayChangeSpecialistCapabilities = $false
        selfAccessMutation = 'deny'; finalActiveAdministrator = 'not-applicable'
    }
    [pscustomobject][ordered]@{
        id = 'supervisor-create-operator-no-specialist'; appliesTo = 'requested-target'; allowedCurrentTargetRoles = @(); allowedRequestedTargetRoles = @('operator')
        mayChangeBaseRole = $false; mayChangeSpecialistCapabilities = $false
        selfAccessMutation = 'deny'; finalActiveAdministrator = 'not-applicable'
    }
    [pscustomobject][ordered]@{
        id = 'supervisor-edit-operator-no-access-mutation'; appliesTo = 'current-and-requested-target'; allowedCurrentTargetRoles = @('operator'); allowedRequestedTargetRoles = @('operator')
        mayChangeBaseRole = $false; mayChangeSpecialistCapabilities = $false
        selfAccessMutation = 'deny'; finalActiveAdministrator = 'not-applicable'
    }
    [pscustomobject][ordered]@{
        id = 'supervisor-operator-target-mutation'; appliesTo = 'current-target'; allowedCurrentTargetRoles = @('operator'); allowedRequestedTargetRoles = @()
        mayChangeBaseRole = $false; mayChangeSpecialistCapabilities = $false
        selfAccessMutation = 'deny'; finalActiveAdministrator = 'not-applicable'
    }
    [pscustomobject][ordered]@{
        id = 'administrator-selectable-target-read'; appliesTo = 'current-target'; allowedCurrentTargetRoles = @('operator','supervisor','administrator'); allowedRequestedTargetRoles = @()
        mayChangeBaseRole = $false; mayChangeSpecialistCapabilities = $false
        selfAccessMutation = 'allow'; finalActiveAdministrator = 'not-applicable'
    }
    [pscustomobject][ordered]@{
        id = 'administrator-create-selectable'; appliesTo = 'requested-target'; allowedCurrentTargetRoles = @(); allowedRequestedTargetRoles = @('operator','supervisor','administrator')
        mayChangeBaseRole = $false; mayChangeSpecialistCapabilities = $true
        selfAccessMutation = 'not-applicable'; finalActiveAdministrator = 'not-applicable'
    }
    [pscustomobject][ordered]@{
        id = 'administrator-edit-selectable-with-safeguards'; appliesTo = 'current-and-requested-target'; allowedCurrentTargetRoles = @('operator','supervisor','administrator'); allowedRequestedTargetRoles = @('operator','supervisor','administrator')
        mayChangeBaseRole = $true; mayChangeSpecialistCapabilities = $true
        selfAccessMutation = 'deny'; finalActiveAdministrator = 'preserve'
    }
    [pscustomobject][ordered]@{
        id = 'administrator-selectable-target-mutation'; appliesTo = 'current-target'; allowedCurrentTargetRoles = @('operator','supervisor','administrator'); allowedRequestedTargetRoles = @()
        mayChangeBaseRole = $false; mayChangeSpecialistCapabilities = $false
        selfAccessMutation = 'deny'; finalActiveAdministrator = 'preserve'
    }
    [pscustomobject][ordered]@{
        id = 'administrator-role-change-with-safeguards'; appliesTo = 'current-and-requested-target'; allowedCurrentTargetRoles = @('operator','supervisor','administrator'); allowedRequestedTargetRoles = @('operator','supervisor','administrator')
        mayChangeBaseRole = $true; mayChangeSpecialistCapabilities = $false
        selfAccessMutation = 'deny'; finalActiveAdministrator = 'preserve'
    }
)

$managedUserReadScopes = [ordered]@{ operator='deny'; supervisor='supervisor-operator-target-read'; administrator='administrator-selectable-target-read' }
$managedUserCreateScopes = [ordered]@{ operator='deny'; supervisor='supervisor-create-operator-no-specialist'; administrator='administrator-create-selectable' }
$managedUserEditScopes = [ordered]@{ operator='deny'; supervisor='supervisor-edit-operator-no-access-mutation'; administrator='administrator-edit-selectable-with-safeguards' }
$managedUserMutationScopes = [ordered]@{ operator='deny'; supervisor='supervisor-operator-target-mutation'; administrator='administrator-selectable-target-mutation' }
$managedUserRoleChangeScopes = [ordered]@{ operator='deny'; supervisor='deny'; administrator='administrator-role-change-with-safeguards' }

$operations = @(
    New-Operation 1 'ReportSurfaceAccess' 'report-surface-access' 'Enter or view the report surface.' @('CanAccessReports') 'all' 'product-navigation-and-service-deep-link' 'OWNER-ATTESTATION-2026-11-18'
    New-Operation 2 'EquipmentReportGeneration' 'equipment-report-generation' 'Generate an Equipment report.' @('CanAccessReports') 'all' 'service-before-source-retrieval' 'OWNER-ATTESTATION-2026-11-18'
    New-Operation 3 'EventReportGeneration' 'event-report-generation' 'Generate an Event report.' @('CanAccessReports') 'all' 'service-before-source-retrieval' 'OWNER-ATTESTATION-2026-11-18'
    New-Operation 4 'UserReportGeneration' 'user-report-generation' 'Generate a User report.' @('CanAccessReports') 'all' 'service-before-source-retrieval' 'OWNER-ATTESTATION-2026-11-18'
    New-Operation 5 'CompletedReportView' 'completed-report-view' 'View an already generated report.' @('CanAccessReports') 'all' 'product-before-content-disclosure' 'OWNER-ATTESTATION-2026-11-18'
    New-Operation 6 'ReportExport' 'report-export' 'Export a controlled report.' @('CanExportReports') 'all' 'product-before-atomic-replacement' 'OWNER-ATTESTATION-2026-11-18'
    New-Operation 7 'ReportPrint' 'report-print' 'Submit a controlled report for printing.' @('CanPrintReports') 'all' 'product-before-spool-submission' 'OWNER-ATTESTATION-2026-11-18'
    New-Operation 8 'PrintSettingsChange' 'print-settings-change' 'Change printer settings.' @('CanEnableDisablePrinting')
    New-Operation 9 'AutoPrintSettingsChange' 'auto-print-settings-change' 'Change auto-print settings.' @('CanEnableDisablePrinting')
    New-Operation 10 'SsiStatementEdit' 'ssi-statement-edit' 'Edit the controlled SSI statement.' @('CanEditSecurityFooter') 'all' 'authoritative-service-before-setting-mutation' 'OWNER-ATTESTATION-2026-11-18'
    New-Operation 11 'ShutdownOrReboot' 'shutdown-or-reboot' 'Shut down or reboot the instrument.' @('CanShutdownReboot')
    New-Operation 12 'SessionLogonOrLogoff' 'session-logon-or-logoff' 'Start or end an authenticated session.' @('CanLogonLogoff')
    New-Operation 13 'SampleAnalysis' 'sample-analysis' 'Analyze a sample.' @('CanAnalyzeSamples')
    New-Operation 14 'AlarmAccess' 'alarm-access' 'Access alarm information.' @('CanAccessAlarms')
    New-Operation 15 'AudibleAlarmSettingsEdit' 'audible-alarm-settings-edit' 'Change audible-alarm settings.' @('CanEditAudibleAlarms')
    New-Operation 16 'SubstanceLibraryView' 'substance-library-view' 'View the substance library.' @('CanViewSubstanceLibrary')
    New-Operation 17 'SubstanceLibraryEdit' 'substance-library-edit' 'Edit the substance library.' @('CanEditSubstanceLibrary')
    New-Operation 18 'DetectionAlgorithmSelection' 'detection-algorithm-selection' 'Select a detection algorithm.' @('CanSelectDetectionAlgorithm')
    New-Operation 19 'SubstanceTraining' 'substance-training' 'Train a substance.' @('CanDoSubstanceTraining')
    New-Operation 20 'InstrumentConfigurationChange' 'instrument-configuration-change' 'Change instrument configuration.' @('CanAccessInstrumentConfiguration')
    New-Operation 21 'SamplingDataSystemStatusView' 'sampling-data-system-status-view' 'View sampling-data system status.' @('CanAccessSamplingDataSystemStatus')
    New-Operation 22 'MaintenanceExecution' 'maintenance-execution' 'Execute maintenance.' @('CanDoMaintenance')
    New-Operation 23 'SystemCleaning' 'system-cleaning' 'Clean the system.' @('CanCleanSystem')
    New-Operation 24 'AutomaticCalibration' 'automatic-calibration' 'Run automatic calibration.' @('CanAutoCalibrate')
    New-Operation 25 'ManualCalibration' 'manual-calibration' 'Run manual calibration.' @('CanManuallyCalibrate')
    New-Operation 26 'DataManagement' 'data-management' 'Manage retained data.' @('CanManageData')
    New-Operation 27 'SamplingDataCopyToUsb' 'sampling-data-copy-to-usb' 'Copy sampling data to attached storage.' @('CanCopyDataToUsb')
    New-Operation 28 'SamplingDataExport' 'sampling-data-export' 'Export sampling data.' @('CanExportSamplingData')
    New-Operation 29 'SoftwareUpgrade' 'software-upgrade' 'Upgrade software.' @('CanUpgradeSoftware')
    New-Operation 30 'SystemFoldersView' 'system-folders-view' 'View approved system folders.' @('CanViewSystemFolders')
    New-Operation 31 'UserPolicyInspection' 'user-policy-inspection' 'Inspect a managed user policy.' @('CanManageAdministrators','CanManageScreeningStaff','CanManageServiceTechs') 'any' 'authoritative-service-before-operation' 'FRD-133-APPENDIX-C+CURRENT-RESOLVER-BASELINE-2026-11-19' $managedUserReadScopes
    New-Operation 32 'ManagedUserCreate' 'managed-user-create' 'Create a managed user.' @('CanManageAdministrators','CanManageScreeningStaff','CanManageServiceTechs') 'any' 'authoritative-service-before-operation' 'FRD-133-APPENDIX-C+CURRENT-RESOLVER-BASELINE-2026-11-19' $managedUserCreateScopes
    New-Operation 33 'ManagedUserEdit' 'managed-user-edit' 'Edit a managed user.' @('CanManageAdministrators','CanManageScreeningStaff','CanManageServiceTechs') 'any' 'authoritative-service-before-operation' 'FRD-133-APPENDIX-C+CURRENT-RESOLVER-BASELINE-2026-11-19' $managedUserEditScopes
    New-Operation 34 'ManagedUserEnableOrDisable' 'managed-user-enable-or-disable' 'Enable or disable a managed user.' @('CanManageAdministrators','CanManageScreeningStaff','CanManageServiceTechs') 'any' 'authoritative-service-before-operation' 'FRD-133-APPENDIX-C+CURRENT-RESOLVER-BASELINE-2026-11-19' $managedUserMutationScopes
    New-Operation 35 'ManagedUserCredentialReset' 'managed-user-credential-reset' 'Reset managed-user credentials.' @('CanManageAdministrators','CanManageScreeningStaff','CanManageServiceTechs') 'any' 'authoritative-service-before-operation' 'FRD-133-APPENDIX-C+CURRENT-RESOLVER-BASELINE-2026-11-19' $managedUserMutationScopes
    New-Operation 36 'ManagedUserMfaReset' 'managed-user-mfa-reset' 'Reset managed-user MFA.' @('CanManageAdministrators','CanManageScreeningStaff','CanManageServiceTechs') 'any' 'authoritative-service-before-operation' 'FRD-133-APPENDIX-C+CURRENT-RESOLVER-BASELINE-2026-11-19' $managedUserMutationScopes
    New-Operation 37 'ManagedUserDelete' 'managed-user-delete' 'Delete a managed user.' @('CanManageAdministrators','CanManageScreeningStaff','CanManageServiceTechs') 'any' 'authoritative-service-before-operation' 'FRD-133-APPENDIX-C+CURRENT-RESOLVER-BASELINE-2026-11-19' $managedUserMutationScopes
    New-Operation 38 'ManagedUserRoleChange' 'managed-user-role-change' 'Change a managed user role.' @('CanEditUserRole') 'all' 'authoritative-service-before-operation' 'FRD-133-APPENDIX-C+CURRENT-RESOLVER-BASELINE-2026-11-19' $managedUserRoleChangeScopes
    New-Operation 39 'ManagedUserAccessTokenRevoke' 'managed-user-access-token-revoke' 'Revoke a managed user access token.' @('CanManageAdministrators','CanManageScreeningStaff','CanManageServiceTechs') 'any' 'authoritative-service-before-operation' 'FRD-133-APPENDIX-C+CURRENT-RESOLVER-BASELINE-2026-11-19' $managedUserMutationScopes
)

$policyStates = @('allowed','denied','reauthentication-required','policy-unavailable','prerequisite-unmet')
$aliases = @(
    [pscustomobject][ordered]@{ input = 'Operator'; normalizedRole = 'operator'; valid = $true }
    [pscustomobject][ordered]@{ input = 'Operator/Screener'; normalizedRole = 'operator'; valid = $true }
    [pscustomobject][ordered]@{ input = 'operator'; normalizedRole = 'operator'; valid = $true }
    [pscustomobject][ordered]@{ input = ' Supervisor '; normalizedRole = 'supervisor'; valid = $true }
    [pscustomobject][ordered]@{ input = 'System Manager'; normalizedRole = 'supervisor'; valid = $true }
    [pscustomobject][ordered]@{ input = 'Administrator'; normalizedRole = 'administrator'; valid = $true }
    [pscustomobject][ordered]@{ input = 'System Administrator'; normalizedRole = 'administrator'; valid = $true }
    [pscustomobject][ordered]@{ input = 'QA'; normalizedRole = ''; valid = $false }
    [pscustomobject][ordered]@{ input = 'Service'; normalizedRole = ''; valid = $false }
    [pscustomobject][ordered]@{ input = 'Commissioning'; normalizedRole = ''; valid = $false }
)

$matrixRows = [System.Collections.Generic.List[object]]::new()
foreach ($role in $roles) {
    foreach ($bundle in $bundles) {
        $effectiveCapabilities = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($capability in $role.capabilityIds) { [void]$effectiveCapabilities.Add($capability) }
        foreach ($capability in $bundle.capabilityIds) { [void]$effectiveCapabilities.Add($capability) }

        foreach ($operation in $operations) {
            $targetScopePolicyId = $operation.targetScopePolicyByRole.PSObject.Properties[$role.id].Value
            $targetScopePolicy = $targetScopePolicies | Where-Object { $_.id -eq $targetScopePolicyId }
            if ($null -eq $targetScopePolicy) {
                throw "Operation '$($operation.operationId)' references unknown target-scope policy '$targetScopePolicyId' for '$($role.id)'."
            }
            $roleAllowed = (Test-OperationAllowed $operation $effectiveCapabilities) -and $targetScopePolicyId -ne 'deny'
            $decisionEvidence = @($role.evidenceId, $bundle.evidenceId, $operation.evidenceId) |
                Select-Object -Unique
            foreach ($policyState in $policyStates) {
                $projection = Get-DecisionProjection $operation $roleAllowed $policyState
                $matrixRows.Add([pscustomobject][ordered]@{
                    schemaVersion = 1
                    operationId = $operation.operationId
                    auditOperationOrdinal = $operation.auditOrdinal
                    capabilityExpression = $operation.capabilityExpression
                    targetScopePolicyId = $targetScopePolicyId
                    baseRole = $role.id
                    bundleSet = $bundle.id
                    roleDecision = if ($roleAllowed) { 'allowed' } else { 'denied' }
                    policyState = $policyState
                    effectiveDecision = $projection.effectiveDecision
                    guidanceCategory = $projection.guidanceCategory
                    retryDisposition = $projection.retryDisposition
                    presentationProjection = $projection.presentationProjection
                    protectedContentDisposition = $projection.protectedContentDisposition
                    focusDisposition = $projection.focusDisposition
                    statusAnnouncement = $projection.statusAnnouncement
                    enforcementBoundary = $operation.enforcementBoundary
                    evidenceId = $decisionEvidence -join '|'
                })
            }
        }
    }
}

$catalog = [pscustomobject][ordered]@{
    schemaVersion = 1
    policyId = 'bruker.user-management.capability-matrix.v1'
    effectiveDate = '2026-11-18'
    authority = @('FRD-133-APPENDIX-C','OWNER-ATTESTATION-2026-11-18')
    capabilities = $capabilities
    roles = $roles
    bundles = $bundles
    targetScopePolicies = $targetScopePolicies
    operations = $operations
    policyStates = $policyStates
    unknownCodeFallback = [pscustomobject][ordered]@{
        effectiveDecision = 'denied'
        guidanceCategory = 'unknown-code'
        retryDisposition = 'do-not-retry'
        presentationProjection = 'visible-disabled'
        protectedContentDisposition = 'remove'
        focusDisposition = 'restore-stable-target'
        statusAnnouncement = 'announce-neutral-unknown-code'
    }
    rollingUpgrade = [pscustomobject][ordered]@{
        unknownBits = 'deny'
        unknownRoles = 'deny'
        conflictingBaseRoles = 'deny'
        bundleWithoutBaseRole = 'deny'
        unsupportedSchemaVersion = 'deny'
        cachedUiMayAuthorize = $false
    }
}

$matrix = [pscustomobject][ordered]@{
    schemaVersion = 1
    policyId = $catalog.policyId
    rowCount = $matrixRows.Count
    dimensions = [pscustomobject][ordered]@{
        roles = $roles.Count
        bundleSets = $bundles.Count
        operations = $operations.Count
        policyStates = $policyStates.Count
    }
    rows = $matrixRows
}

$failClosedFixtures = [pscustomobject][ordered]@{
    schemaVersion = 1
    fallback = $catalog.unknownCodeFallback
    cases = @(
        [pscustomobject][ordered]@{ id='missing-base-role'; baseRoles=@(); bundles=@(); input=''; expected='deny' }
        [pscustomobject][ordered]@{ id='lab-qa-bundle-only'; baseRoles=@(); bundles=@('lab-qa'); input='lab-qa'; expected='deny' }
        [pscustomobject][ordered]@{ id='service-bundle-only'; baseRoles=@(); bundles=@('service-maintenance'); input='service-maintenance'; expected='deny' }
        [pscustomobject][ordered]@{ id='conflicting-operator-supervisor'; baseRoles=@('operator','supervisor'); bundles=@(); input='operator+supervisor'; expected='deny' }
        [pscustomobject][ordered]@{ id='conflicting-supervisor-administrator'; baseRoles=@('supervisor','administrator'); bundles=@(); input='supervisor+administrator'; expected='deny' }
        [pscustomobject][ordered]@{ id='unknown-role'; baseRoles=@('future-role'); bundles=@(); input='future-role'; expected='deny' }
        [pscustomobject][ordered]@{ id='unknown-bit-33'; baseRoles=@('administrator'); bundles=@(); input='0x0000000200000000'; expected='deny' }
        [pscustomobject][ordered]@{ id='unknown-bit-63'; baseRoles=@('administrator'); bundles=@(); input='0x8000000000000000'; expected='deny' }
        [pscustomobject][ordered]@{ id='unsupported-schema-version'; baseRoles=@('administrator'); bundles=@(); input='schemaVersion=2'; expected='deny' }
        [pscustomobject][ordered]@{ id='unknown-operation-code'; baseRoles=@('administrator'); bundles=@(); input='future-operation'; expected='deny' }
        [pscustomobject][ordered]@{ id='unknown-policy-state'; baseRoles=@('administrator'); bundles=@(); input='future-policy-state'; expected='deny' }
        [pscustomobject][ordered]@{ id='unknown-guidance-code'; baseRoles=@('administrator'); bundles=@(); input='future-guidance'; expected='deny' }
        [pscustomobject][ordered]@{ id='unknown-target-scope-policy'; baseRoles=@('administrator'); bundles=@(); input='future-target-scope'; expected='deny' }
    )
    presentationCases = @(
        [pscustomobject][ordered]@{ id='report-surface-denied-removes-content'; baseRole='operator'; operationId='report-surface-access'; policyState='allowed'; expectedProjection='hidden-reject-deep-link'; expectedContentDisposition='remove' }
        [pscustomobject][ordered]@{ id='completed-report-view-denied-removes-content'; baseRole='operator'; operationId='completed-report-view'; policyState='allowed'; expectedProjection='absent-with-protected-surface'; expectedContentDisposition='remove' }
        [pscustomobject][ordered]@{ id='export-denied-retains-authorized-report'; baseRole='operator'; operationId='report-export'; policyState='allowed'; expectedProjection='visible-disabled'; expectedContentDisposition='retain' }
        [pscustomobject][ordered]@{ id='print-denied-retains-authorized-report'; baseRole='operator'; operationId='report-print'; policyState='allowed'; expectedProjection='visible-disabled'; expectedContentDisposition='retain' }
        [pscustomobject][ordered]@{ id='print-settings-denied-retains-authorized-report'; baseRole='operator'; operationId='print-settings-change'; policyState='allowed'; expectedProjection='visible-disabled'; expectedContentDisposition='retain' }
        [pscustomobject][ordered]@{ id='auto-print-settings-denied-retains-authorized-report'; baseRole='operator'; operationId='auto-print-settings-change'; policyState='allowed'; expectedProjection='visible-disabled'; expectedContentDisposition='retain' }
        [pscustomobject][ordered]@{ id='ssi-edit-denied-retains-authorized-report'; baseRole='supervisor'; operationId='ssi-statement-edit'; policyState='allowed'; expectedProjection='visible-disabled'; expectedContentDisposition='retain' }
    )
    targetScopeCases = @(
        [pscustomobject][ordered]@{ id='supervisor-create-operator-only'; baseRole='supervisor'; operationId='managed-user-create'; expectedRoleDecision='allowed'; expectedTargetScopePolicyId='supervisor-create-operator-no-specialist' }
        [pscustomobject][ordered]@{ id='supervisor-edit-operator-without-access-mutation'; baseRole='supervisor'; operationId='managed-user-edit'; expectedRoleDecision='allowed'; expectedTargetScopePolicyId='supervisor-edit-operator-no-access-mutation' }
        [pscustomobject][ordered]@{ id='supervisor-role-change-denied'; baseRole='supervisor'; operationId='managed-user-role-change'; expectedRoleDecision='denied'; expectedTargetScopePolicyId='deny' }
        [pscustomobject][ordered]@{ id='administrator-role-change-safeguarded'; baseRole='administrator'; operationId='managed-user-role-change'; expectedRoleDecision='allowed'; expectedTargetScopePolicyId='administrator-role-change-with-safeguards' }
    )
}

$output = [IO.Path]::GetFullPath($OutputDirectory)
$fixtureDirectory = Join-Path $output 'fixtures'
New-Item -ItemType Directory -Force -Path $output, $fixtureDirectory | Out-Null

$utf8NoBom = [Text.UTF8Encoding]::new($false)
function Write-Utf8([string]$Path, [string]$Content) {
    $normalized = ($Content -replace "`r`n", "`n" -replace "`r", "`n").TrimEnd() + "`n"
    [IO.File]::WriteAllText($Path, $normalized, $utf8NoBom)
}

Write-Utf8 (Join-Path $output 'capability-catalog.v1.json') ($catalog | ConvertTo-Json -Depth 20)
Write-Utf8 (Join-Path $output 'capability-matrix.v1.json') ($matrix | ConvertTo-Json -Depth 20)

$csvLines = $matrixRows | ConvertTo-Csv -NoTypeInformation
Write-Utf8 (Join-Path $output 'capability-matrix.v1.csv') ($csvLines -join "`n")

$aliasLines = $aliases | ConvertTo-Csv -NoTypeInformation
Write-Utf8 (Join-Path $fixtureDirectory 'role-aliases.v1.csv') ($aliasLines -join "`n")
Write-Utf8 (Join-Path $fixtureDirectory 'fail-closed-inputs.v1.json') ($failClosedFixtures | ConvertTo-Json -Depth 10)

$matrixBytes = [IO.File]::ReadAllBytes((Join-Path $output 'capability-matrix.v1.json'))
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $matrixHash = ([BitConverter]::ToString($sha256.ComputeHash($matrixBytes)) -replace '-', '').ToLowerInvariant()
}
finally {
    $sha256.Dispose()
}
$failClosedBytes = [IO.File]::ReadAllBytes((Join-Path $fixtureDirectory 'fail-closed-inputs.v1.json'))
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $failClosedHash = ([BitConverter]::ToString($sha256.ComputeHash($failClosedBytes)) -replace '-', '').ToLowerInvariant()
}
finally {
    $sha256.Dispose()
}
foreach ($productId in @('dhs','triple-quad-ui')) {
    $parity = [pscustomobject][ordered]@{
        schemaVersion = 1
        productId = $productId
        policyId = $catalog.policyId
        decisionSource = '../capability-matrix.v1.json'
        canonicalMatrixSha256 = $matrixHash
        failClosedSource = 'fail-closed-inputs.v1.json'
        failClosedSha256 = $failClosedHash
        scenarioCount = $matrixRows.Count
        roles = @($roles.id)
        bundleSets = @($bundles.id)
        operations = @($operations.operationId)
        policyStates = @($policyStates)
        semanticFields = @('roleDecision','targetScopePolicyId','effectiveDecision','guidanceCategory','retryDisposition','presentationProjection','protectedContentDisposition','focusDisposition','statusAnnouncement')
        unknownCodeFallback = $catalog.unknownCodeFallback
    }
    Write-Utf8 (Join-Path $fixtureDirectory "$productId-capability-decisions.v1.json") ($parity | ConvertTo-Json -Depth 10)
}

Write-Output "Generated $($matrixRows.Count) capability decisions at $output"
