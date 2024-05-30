<#
.SYNOPSIS
Removes a scheduled task by task name.

.DESCRIPTION
The Remove-ScheduledScript function removes a scheduled task by task name. It first checks if a scheduled task with the specified task name exists. If the task exists, it unregisters the task. If the task does not exist, it writes an error message.

.PARAMETER TaskName
Specifies the name of the scheduled task to be removed.

.EXAMPLE
Remove-ScheduledScript -TaskName "MyTask"
Removes the scheduled task with the name "MyTask".

#>
function Remove-ScheduledScript {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $TaskName
    )

    process {
        if ($PSCmdlet.ShouldProcess("$TaskName", "Remove scheduled task")) {
            try {
                if (Get-ScheduledTask -TaskName $TaskName -TaskPath \ -ErrorAction SilentlyContinue) {
                    Unregister-ScheduledTask -TaskName "$TaskName" -Confirm:$false
                }
                else {
                    Write-Error "No scheduled task found with the name $TaskName"
                }
            }
            catch {
                Write-Error "Failed to remove scheduled task: $_"
            }
        }
    }
}
