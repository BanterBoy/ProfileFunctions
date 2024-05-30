<#
.SYNOPSIS
Retrieves information about a scheduled script task.

.DESCRIPTION
The Get-ScheduledScript function retrieves information about a scheduled script task based on the specified task name.

.PARAMETER TaskName
The name of the scheduled script task.

.EXAMPLE
Get-ScheduledScript -TaskName "MyScriptTask"

This example retrieves information about the scheduled script task named "MyScriptTask".

.OUTPUTS
The function returns an object with the following properties:
- TaskName: The name of the task.
- TaskPath: The path of the task.
- State: The state of the task.
- LastRunTime: The last run time of the task.
- NextRunTime: The next run time of the task.
- LastTaskResult: The description of the last task result.
- NumberOfMissedRuns: The number of missed runs of the task.

.NOTES
This function requires the Get-ScheduledTask and Get-ScheduledTaskInfo cmdlets.

.LINK
Get-ScheduledTask: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/get-scheduledtask
Get-ScheduledTaskInfo: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/get-scheduledtaskinfo
#>
function Get-ScheduledScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $TaskName
    )

    $task = Get-ScheduledTask -TaskName $TaskName -TaskPath \
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -TaskPath \

    $lastTaskResultDescription = switch ($taskInfo.LastTaskResult) {
        0 { "The operation completed successfully." }
        267011 { "The task is currently running." }
        2147750687 { "The task is already running." }
        2147750686 { "The task will be triggered by user logon." }
        2147942402 { "The system cannot find the file specified." }
        2147942405 { "Access is denied." }
        default { "Unknown error." }
    }

    $output = New-Object PSObject
    $output | Add-Member -MemberType NoteProperty -Name "TaskName" -Value $task.TaskName
    $output | Add-Member -MemberType NoteProperty -Name "TaskPath" -Value $task.TaskPath
    $output | Add-Member -MemberType NoteProperty -Name "State" -Value $task.State
    $output | Add-Member -MemberType NoteProperty -Name "LastRunTime" -Value $taskInfo.LastRunTime
    $output | Add-Member -MemberType NoteProperty -Name "NextRunTime" -Value $taskInfo.NextRunTime
    $output | Add-Member -MemberType NoteProperty -Name "LastTaskResult" -Value $lastTaskResultDescription
    $output | Add-Member -MemberType NoteProperty -Name "NumberOfMissedRuns" -Value $taskInfo.NumberOfMissedRuns

    $output
}
