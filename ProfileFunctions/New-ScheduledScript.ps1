<#
.SYNOPSIS
Creates a new scheduled task that runs a PowerShell script.

.DESCRIPTION
The New-ScheduledScript function creates a new scheduled task that runs a PowerShell script at a specified frequency and time. It uses the Register-ScheduledTask cmdlet to register the task with the Windows Task Scheduler.

.PARAMETER ScriptPath
The path to the PowerShell script that will be executed by the scheduled task. The default value is "C:\Temp\ScheduledScript.ps1".

.PARAMETER TaskName
The name of the scheduled task. The default value is "ScheduledScript".

.PARAMETER Description
A description of the scheduled task. The default value is "ScheduledScript created by New-ScheduledScript function.".

.PARAMETER TriggerFrequency
The frequency at which the scheduled task should run. Valid values are "Daily", "Weekly", "AtStartup", "AtLogon", and "Once". The default value is "Daily".

.PARAMETER TriggerTime
The time at which the scheduled task should run. The default value is "1am".

.PARAMETER ComputerName
The name of the remote computer where the scheduled task will be created. If not specified, the task will be created on the local computer.

.PARAMETER Credential
The credentials to use for creating the scheduled task on a remote computer. If not specified, the current user's credentials will be used.

.EXAMPLE
New-ScheduledScript -ScriptPath "C:\Scripts\MyScript.ps1" -TaskName "MyTask" -Description "My task description" -TriggerFrequency "Weekly" -TriggerTime "8am"
Creates a new scheduled task named "MyTask" that runs the script "C:\Scripts\MyScript.ps1" every week at 8am.

.EXAMPLE
New-ScheduledScript -ComputerName "RemoteComputer" -ScriptPath "C:\Scripts\MyScript.ps1" -TaskName "RemoteTask" -Description "Remote task description" -TriggerFrequency "Daily" -TriggerTime "6am" -Credential (Get-Credential)
Creates a new scheduled task named "RemoteTask" that runs the script "C:\Scripts\MyScript.ps1" every day at 6am on the remote computer "RemoteComputer" using the specified credentials.

.NOTES
This function requires administrative privileges to register the scheduled task with the Windows Task Scheduler.
#>
function New-ScheduledScript {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ScriptPath = "C:\Temp\ScheduledScript.ps1",

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$TaskName = "ScheduledScript",

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Description = "ScheduledScript created by New-ScheduledScript function.",

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Daily', 'Weekly', 'AtStartup', 'AtLogon', 'Once')]
        [string]$TriggerFrequency = 'Daily',

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$TriggerTime = '1am',

        [Parameter(Mandatory = $false)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    # Define the script block to create the scheduled task
    $scriptBlock = {
        param (
            $ScriptPath,
            $TaskName,
            $Description,
            $TriggerFrequency,
            $TriggerTime
        )

        Write-Verbose "ScriptBlock: Parameters received: ScriptPath=$ScriptPath, TaskName=$TaskName, Description=$Description, TriggerFrequency=$TriggerFrequency, TriggerTime=$TriggerTime"

        try {
            Write-Verbose "Creating new scheduled task action"
            $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -NoProfile -NoLogo"
            
            Write-Verbose "Creating new scheduled task trigger"
            switch ($TriggerFrequency) {
                'Daily' {
                    $triggerTime = [datetime]::Parse($TriggerTime)
                    $trigger = New-ScheduledTaskTrigger -Daily -At $triggerTime
                }
                'Weekly' {
                    $triggerTime = [datetime]::Parse($TriggerTime)
                    $trigger = New-ScheduledTaskTrigger -Weekly -At $triggerTime
                }
                'AtStartup' {
                    $trigger = New-ScheduledTaskTrigger -AtStartup
                }
                'AtLogon' {
                    $trigger = New-ScheduledTaskTrigger -AtLogon
                }
                'Once' {
                    $triggerTime = [datetime]::Parse($TriggerTime)
                    $trigger = New-ScheduledTaskTrigger -Once -At $triggerTime
                }
            }

            Write-Verbose "Creating new scheduled task settings"
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

            Write-Verbose "Registering new scheduled task"
            Register-ScheduledTask -TaskName "$TaskName" -Action $action -Trigger $trigger -Settings $settings -Description "$Description"
        }
        catch {
            if ($_.Exception.Message -match "Cannot create a file when that file already exists") {
                Write-Error "The task '$TaskName' already exists. Please choose a different name or delete the existing task."
            }
            else {
                Write-Error "Failed to create scheduled task: $_"
            }
        }
    }

    Write-Verbose "Main Function: Parameters received: ScriptPath=$ScriptPath, TaskName=$TaskName, Description=$Description, TriggerFrequency=$TriggerFrequency, TriggerTime=$TriggerTime, ComputerName=$ComputerName"

    if ($ComputerName) {
        # Prepare the parameters for Invoke-Command
        $params = @{
            ScriptBlock  = $scriptBlock
            ArgumentList = $ScriptPath, $TaskName, $Description, $TriggerFrequency, $TriggerTime
            ComputerName = $ComputerName
        }
        if ($Credential) {
            $params.Credential = $Credential
        }
        Write-Verbose "Invoking command on remote computer $ComputerName"
        try {
            Invoke-Command @params -ErrorAction Stop
        }
        catch {
            if ($_.Exception.Message -match "Cannot create a file when that file already exists") {
                Write-Error "The task '$TaskName' already exists on the remote computer. Please choose a different name or delete the existing task."
            }
            else {
                Write-Error "Failed to execute remote command: $_"
            }
        }
    }
    else {
        Write-Verbose "Invoking script block locally"
        try {
            & $scriptBlock -ScriptPath $ScriptPath -TaskName $TaskName -Description $Description -TriggerFrequency $TriggerFrequency -TriggerTime $TriggerTime -ErrorAction Stop
        }
        catch {
            if ($_.Exception.Message -match "Cannot create a file when that file already exists") {
                Write-Error "The task '$TaskName' already exists on the local computer. Please choose a different name or delete the existing task."
            }
            else {
                Write-Error "Failed to create scheduled task locally: $_"
            }
        }
    }
}
