<#
.SYNOPSIS
Synchronizes Active Directory (AD) with Azure Active Directory (AAD) on one or more computers.

.DESCRIPTION
The Sync-ADwithAAD function synchronizes Active Directory (AD) with Azure Active Directory (AAD) on one or more computers. It imports the AADConnector.psm1 module, checks the AD Sync Scheduler status, and starts a sync cycle if one is not already in progress. It then waits for the sync cycle to complete before proceeding.

.PARAMETER ComputerName
Specifies the name of the computer(s) on which to synchronize AD with AAD. This parameter is mandatory and accepts pipeline input.

.PARAMETER Credential
Specifies the credentials to use when creating a new session with the computer(s). If not provided, a session will be created without credentials.

.INPUTS
System.String

.OUTPUTS
System.String

.EXAMPLE
Sync-ADwithAAD -ComputerName 'Server01'

This example synchronizes AD with AAD on a single computer named 'Server01'.

.EXAMPLE
'Server01', 'Server02' | Sync-ADwithAAD

This example synchronizes AD with AAD on multiple computers named 'Server01' and 'Server02' using pipeline input.

.LINK
http://scripts.lukeleigh.com/

#>
function Sync-ADwithAAD {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        HelpUri = 'http://scripts.lukeleigh.com/',
        PositionalBinding = $true)]
    [OutputType([string], ParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            Position = 0,
            HelpMessage = 'Enter the Name of the computer you would like to test.')]
        [Alias('cn')]
        [string[]]$ComputerName,
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter computer name or pipe input')]
        [Alias('cred')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )
    begin {
        Write-Verbose -Message "Starting Sync-ADwithAAD" -Verbose
        $scriptBlock = {
            try {
                Write-Verbose -Message "Importing AADConnector.psm1 module" -Verbose
                Import-Module "C:\Program Files\Microsoft Azure AD Sync\Extensions\AADConnector.psm1"
                $ADSyncStatus = Get-ADSyncScheduler
                if (-Not $ADSyncStatus.SyncCycleInProgress) {
                    Write-Verbose -Message "Starting ADSyncSyncCycle" -Verbose
                    Start-ADSyncSyncCycle
                }
                else {
                    Write-Verbose -Message "Sync cycle already in progress" -Verbose
                }
                do {
                    Start-Sleep -Seconds 20
                    $ADSyncStatus = Get-ADSyncScheduler
                } while ($ADSyncStatus.SyncCycleInProgress)
            }
            catch {
                Write-Output "An error occurred: $_"
            }
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            try {
                Write-Verbose -Message "Processing computer: $Computer" -Verbose
                if ($Credential) {
                    Write-Verbose -Message "Creating new session with credentials" -Verbose
                    $session = New-PSSession -ComputerName $ComputerName -Credential $Credential
                    Invoke-Command -Session $session -ScriptBlock $scriptBlock
                    Remove-PSSession -Session $session
                }
                else {
                    Write-Verbose -Message "Creating new session without credentials" -Verbose
                    $session = New-PSSession -ComputerName $ComputerName
                    Invoke-Command -Session $session -ScriptBlock $scriptBlock
                    Remove-PSSession -Session $session
                }
            }
            catch {
                Write-Output "An error occurred while processing $($Computer): $_"
            }
        }
    }
    end {
        Write-Verbose -Message "Ending Sync-ADwithAAD" -Verbose
    }
}
