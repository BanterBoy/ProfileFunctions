function Add-ScheduledTaskAction {
<#

.SYNOPSIS
Adds a new action to existing scheduled task actions.

.DESCRIPTION
Adds a new action to existing scheduled task actions.

.ROLE
Administrators

.PARAMETER taskName
    The name of the task

.PARAMETER taskPath
    The task path.

.PARAMETER actionExecute
    The name of executable to run. By default looks in System32 if Working Directory is not provided

.PARAMETER actionArguments
    The arguments for the executable.

.PARAMETER workingDirectory
    The path to working directory
#>

param (
    [parameter(Mandatory=$true)]
    [string]
    $taskName,
    [parameter(Mandatory=$true)]
    [string]
    $taskPath,
    [parameter(Mandatory=$true)]
    [string]
    $actionExecute,
    [string]
    $actionArguments,
    [string]
    $workingDirectory  
)

Import-Module ScheduledTasks

#
# Prepare action parameter bag
#
$taskActionParams = @{
    Execute = $actionExecute;
} 

if ($actionArguments) {
    $taskActionParams.Argument = $actionArguments;
}
if ($workingDirectory) {
     $taskActionParams.WorkingDirectory = $workingDirectory;
}

######################################################
#### Main script
######################################################

# Create action object
$action = New-ScheduledTaskAction @taskActionParams

$task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
$actionsArray =  $task.Actions
$actionsArray += $action 
Set-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $actionsArray
}
## [END] Add-ScheduledTaskAction ##
function Add-ScheduledTaskTrigger {
 <#

.SYNOPSIS
Adds a new trigger to existing scheduled task triggers.

.DESCRIPTION
Adds a new trigger to existing scheduled task triggers.

.ROLE
Administrators

.PARAMETER taskName
    The name of the task

.PARAMETER taskDescription
    The description of the task.

.PARAMETER taskPath
    The task path.

.PARAMETER triggerAt
    The date/time to trigger the task.    

.PARAMETER triggerFrequency
    The frequency of the task occurence. Possible values Daily, Weekly, Monthly, Once, AtLogOn, AtStartup

.PARAMETER daysInterval
    The number of days interval to run task.

.PARAMETER weeklyInterval
    The number of weeks interval to run task.

.PARAMETER daysOfWeek
    The days of the week to run the task. Possible values can be an array of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday

.PARAMETER username
    The username associated with the trigger.

.PARAMETER repetitionInterval
    The repitition interval.

.PARAMETER repetitionDuration
    The repitition duration.

.PARAMETER randomDelay
    The delay before running the trigger.
#>
 param (
    [parameter(Mandatory=$true)]
    [string]
    $taskName,
    [parameter(Mandatory=$true)]
    [string]
    $taskPath,
    [AllowNull()][System.Nullable[DateTime]]
    $triggerAt,
    [parameter(Mandatory=$true)]
    [string]
    $triggerFrequency, 
    [Int32]
    $daysInterval, 
    [Int32]
    $weeksInterval,
    [string[]]
    $daysOfWeek,
    [string]
    $username,
    [string]
    $repetitionInterval,
    [string]
    $repetitionDuration,
    [boolean]
    $stopAtDurationEnd,
    [string]
    $randomDelay,
    [string]
    $executionTimeLimit
)

Import-Module ScheduledTasks

#
# Prepare task trigger parameter bag
#
$taskTriggerParams = @{} 

if ($triggerAt) {
   $taskTriggerParams.At =  $triggerAt;
}
   
    
# Build optional switches
if ($triggerFrequency -eq 'Daily')
{
    $taskTriggerParams.Daily = $true;
    if ($daysInterval -ne 0) 
    {
       $taskTriggerParams.DaysInterval = $daysInterval;
    }
}
elseif ($triggerFrequency -eq 'Weekly')
{
    $taskTriggerParams.Weekly = $true;
    if ($weeksInterval -ne 0) 
    {
        $taskTriggerParams.WeeksInterval = $weeksInterval;
    }
    if ($daysOfWeek -and $daysOfWeek.Length -gt 0) 
    {
        $taskTriggerParams.DaysOfWeek = $daysOfWeek;
    }
}
elseif ($triggerFrequency -eq 'Once')
{
    $taskTriggerParams.Once = $true;
}
elseif ($triggerFrequency -eq 'AtLogOn')
{
    $taskTriggerParams.AtLogOn = $true;
}
elseif ($triggerFrequency -eq 'AtStartup')
{
    $taskTriggerParams.AtStartup = $true;
}

if ($username) 
{
   $taskTriggerParams.User = $username;
}


######################################################
#### Main script
######################################################

# Create trigger object
$triggersArray = @()
$triggerNew = New-ScheduledTaskTrigger @taskTriggerParams

$task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
$triggersArray =  $task.Triggers

Set-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Trigger $triggerNew | out-null

$task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
$trigger = $task.Triggers[0]


if ($repetitionInterval -and $trigger.Repetition -ne $null) 
{
   $trigger.Repetition.Interval = $repetitionInterval;
}
if ($repetitionDuration -and $trigger.Repetition -ne $null) 
{
   $trigger.Repetition.Duration = $repetitionDuration;
}
if ($stopAtDurationEnd -and $trigger.Repetition -ne $null) 
{
   $trigger.Repetition.StopAtDurationEnd = $stopAtDurationEnd;
}
if($executionTimeLimit) {
 $task.Triggers[0].ExecutionTimeLimit = $executionTimeLimit;
}

if([bool]($task.Triggers[0].PSobject.Properties.name -eq "RandomDelay")) 
{
    $task.Triggers[0].RandomDelay = $randomDelay;
}

if([bool]($task.Triggers[0].PSobject.Properties.name -eq "Delay")) 
{
    $task.Triggers[0].Delay = $randomDelay;
}

$triggersArray += $trigger

Set-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Trigger $triggersArray 
}
## [END] Add-ScheduledTaskTrigger ##
function Disable-ScheduledTask {
<#

.SYNOPSIS
Script to disable a scheduled tasks.

.DESCRIPTION
Script to disable a scheduled tasks.

.ROLE
Administrators

#>

param (
  [Parameter(Mandatory = $true)]
  [String]
  $taskPath,

  [Parameter(Mandatory = $true)]
  [String]
  $taskName
)
Import-Module ScheduledTasks

Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName

}
## [END] Disable-ScheduledTask ##
function Enable-ScheduledTask {
<#

.SYNOPSIS
Script to enable a scheduled tasks.

.DESCRIPTION
Script to enable a scheduled tasks.

.ROLE
Administrators

#>

param (
  [Parameter(Mandatory = $true)]
  [String]
  $taskPath,

  [Parameter(Mandatory = $true)]
  [String]
  $taskName
)

Import-Module ScheduledTasks

Enable-ScheduledTask -TaskPath $taskPath -TaskName $taskName

}
## [END] Enable-ScheduledTask ##
function Get-EventLogs {
<#

.SYNOPSIS
Script to get event logs and sources.

.DESCRIPTION
Script to get event logs and sources. This is used to allow user selection when creating event based triggers.

.ROLE
Readers

#>

Import-Module Microsoft.PowerShell.Diagnostics -ErrorAction SilentlyContinue

Get-WinEvent -ListLog * -ErrorAction SilentlyContinue

}
## [END] Get-EventLogs ##
function Get-ScheduledTasks {
<#

.SYNOPSIS
Script to get list of scheduled tasks.

.DESCRIPTION
Script to get list of scheduled tasks.

.ROLE
Readers

#>

param (
  [Parameter(Mandatory = $false)]
  [String]
  $taskPath,

  [Parameter(Mandatory = $false)]
  [String]
  $taskName
)

Import-Module ScheduledTasks

Add-Type -AssemblyName "System.Linq"
Add-Type -AssemblyName "System.Xml"
Add-Type -AssemblyName "System.Xml.Linq"

function ConvertTo-CustomTriggerType ($trigger) {
  $customTriggerType = ''
  if ($trigger.CimClass -and $trigger.CimClass.CimClassName) {
    $cimClassName = $trigger.CimClass.CimClassName
    if ($cimClassName -eq 'MSFT_TaskTrigger') {
        $ns = [System.Xml.Linq.XNamespace]('http://schemas.microsoft.com/windows/2004/02/mit/task')
        $xml = Export-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath
        $d = [System.Xml.Linq.XDocument]::Parse($xml)
        $scheduleByMonth = $d.Descendants($ns + "ScheduleByMonth")
        if ($scheduleByMonth.Count -gt 0) {
          $customTriggerType = 'MSFT_TaskMonthlyTrigger'
        }
        else {
          $scheduleByMonthDOW = $d.Descendants($ns + "ScheduleByMonthDayOfWeek");
          if ($scheduleByMonthDOW.Count -gt 0) {
            $customTriggerType = 'MSFT_TaskMonthlyDOWTrigger'
          }
        }
    }
  }
  return $customTriggerType
}

function New-TaskWrapper
{
  param (
    [Parameter(Mandatory = $true, ValueFromPipeline=$true)]
    $task
  )

  $task | Add-Member -MemberType NoteProperty -Name 'status' -Value $task.state.ToString()
  $info = Get-ScheduledTaskInfo $task

  $triggerCopies = @()
  for ($i=0;$i -lt $task.Triggers.Length;$i++)
  {
    $trigger = $task.Triggers[$i];
    $triggerCopy = $trigger.PSObject.Copy();
    if ($trigger -ne $null) {

        if ($trigger.StartBoundary -eq $null -or$trigger.StartBoundary -eq '')
        {
            $startDate = $null;
        }

        else
        {
            $startDate = [datetime]($trigger.StartBoundary)
        }

        $triggerCopy | Add-Member -MemberType NoteProperty -Name 'TriggerAtDate' -Value $startDate -TypeName System.DateTime

        if ($trigger.EndBoundary -eq $null -or$trigger.EndBoundary -eq '')
        {
            $endDate = $null;
        }

        else
        {
            $endDate = [datetime]($trigger.EndBoundary)
        }

        $triggerCopy | Add-Member -MemberType NoteProperty -Name 'TriggerEndDate' -Value $endDate -TypeName System.DateTime

        $customTriggerType = ConvertTo-CustomTriggerType -trigger $triggerCopy
        if ($customTriggerType) {
          $triggerCopy | Add-Member -MemberType NoteProperty -Name 'CustomParsedTriggerType' -Value $customTriggerType
        }

        $triggerCopies += $triggerCopy
    }

  }

  $task | Add-Member -MemberType NoteProperty -Name 'TriggersEx' -Value $triggerCopies

  New-Object -TypeName PSObject -Property @{

      ScheduledTask = $task
      ScheduledTaskInfo = $info
  }
}

if ($taskPath -and $taskName) {
  try
  {
    $task = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop
    New-TaskWrapper $task
  }
  catch
  {
  }
} else {
    Get-ScheduledTask | ForEach-Object {
      New-TaskWrapper $_
    }
}

}
## [END] Get-ScheduledTasks ##
function New-BasicTask {
<#

.SYNOPSIS
Creates and registers a new scheduled task.

.DESCRIPTION
Creates and registers a new scheduled task.

.ROLE
Administrators

.PARAMETER taskName
    The name of the task

.PARAMETER taskDescription
    The description of the task.

.PARAMETER taskPath
    The task path.

.PARAMETER taskAuthor
    The task author.

.PARAMETER triggerAt
    The date/time to trigger the task.

.PARAMETER triggerFrequency
    The frequency of the task occurence. Possible values Daily, Weekly, Monthly, Once, AtLogOn, AtStartup

.PARAMETER triggerMonthlyFrequency
    The monthly frequencty of the task occurence. Possible values Monthly (day of month), MonthlyDOW( day of week)

.PARAMETER daysInterval
    The number of days interval to run task.

.PARAMETER weeklyInterval
    The number of weeks interval to run task.

.PARAMETER daysOfWeek
    The days of the week to run the task. Possible values can be an array of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday

.PARAMETER months
    The months of the year that the task is to run. Possible values January thru February

.PARAMETER daysOfMonth
    The specific days of the month that the task can run. Possible values 1-31 and Last. This applies when the task frequency is Monthly.

.PARAMETER weeksOfMonth
    The specific weeks of the month that the task can run. Possible values 1-4 and Last. This applies when the task frequency is MonthlyDOW.

.PARAMETER actionExecute
    The name of executable to run. By default looks in System32 if Working Directory is not provided

.PARAMETER actionArguments
    The arguments for the executable.

.PARAMETER workingDirectory
    The path to working directory
#>

param (
    [parameter(Mandatory=$true)]
    [string]
    $taskName,
    [string]
    $taskDescription,
    [parameter(Mandatory=$true)]
    [string]
    $taskPath,
    [parameter(Mandatory=$true)]
    [string]
    $taskAuthor,
    [parameter(Mandatory=$true)]
    [string]
    $triggerFrequency,
    [string]
    $triggerMonthlyFrequency,
    [AllowNull()][System.Nullable[DateTime]]
    $triggerAt,
    [Int32]
    $daysInterval,
    [Int32]
    $weeklyInterval,
    [string[]]
    $daysOfWeek,
    [string[]]
    $months = @(),
    [string[]]
    $daysOfMonth = @(),
    [string[]]
    $weeksOfMonth = @(),
    [parameter(Mandatory=$true)]
    [string]
    $actionExecute,
    [string]
    $actionArguments,
    [string]
    $workingDirectory,
    [string]
    $eventLogName,
    [string]
    $eventLogSource,
    [Int32]
    $eventLogId
)

Import-Module ScheduledTasks

##SkipCheck=true##
$Source = @"

namespace SME {

    using System;
    using System.Linq;
    using System.Xml.Linq;

    public class TaskSchedulerXml
    {
        public XNamespace ns = "http://schemas.microsoft.com/windows/2004/02/mit/task";

        public XElement CreateMonthlyTrigger(DateTime startBoundary, bool enabled, string[] months, string[] days)
        {
            var element = new XElement(ns + "CalendarTrigger",
                new XElement(ns + "StartBoundary", startBoundary.ToString("s")),
                new XElement(ns + "Enabled", enabled),
                new XElement(ns + "ScheduleByMonth",
                        new XElement(ns + "DaysOfMonth",
                            from day in days
                            select new XElement(ns + "Day", day)
                        ),
                        new XElement(ns + "Months",
                            from month in months
                            select new XElement(ns + month)
                       )
                    )
                );
            return element;
        }

        public XElement CreateMonthlyDOWTrigger(DateTime startBoundary, bool enabled, string[] months, string[] days, string[] weeks)
        {
            var element = new XElement(ns + "CalendarTrigger",
                new XElement(ns + "StartBoundary", startBoundary.ToString("s")),
                new XElement(ns + "Enabled", enabled),
                new XElement(ns + "ScheduleByMonthDayOfWeek",
                        new XElement(ns + "Weeks",
                            from week in weeks
                            select new XElement(ns + "Week", week)
                        ),
                        new XElement(ns + "DaysOfWeek",
                            from day in days
                            select new XElement(ns + day)
                        ),
                        new XElement(ns + "Months",
                            from month in months
                            select new XElement(ns + month)
                       )
                    )
                );
            return element;
        }

        public XElement CreateEventTrigger(string eventLogName, string eventLogSource, string eventLogId, bool enabled)
        {
            XNamespace ns = "http://schemas.microsoft.com/windows/2004/02/mit/task";

            var queryText = string.Format("*[System[Provider[@Name='{0}'] and EventID={1}]]", eventLogSource, eventLogId);

            var queryElement = new XElement("QueryList",
                            new XElement("Query", new XAttribute("Id", "0"), new XAttribute("Path", eventLogName),
                                new XElement("Select", new XAttribute("Path", eventLogName), queryText
                                )
                            )
                        );

            var element = new XElement(ns + "EventTrigger",
                    new XElement(ns + "Enabled", enabled),
                    new XElement(ns + "Subscription", queryElement.ToString()
                    )
                );

            return element;
        }

        public void UpdateTriggers(XElement newTrigger, XDocument d)
        {
            var triggers = d.Descendants(ns + "Triggers").FirstOrDefault();
            if (triggers != null) {
                triggers.ReplaceAll(newTrigger);
            }
        }
    }
  }

"@
##SkipCheck=false##

Add-Type -AssemblyName "System.Linq"
Add-Type -AssemblyName "System.Xml"
Add-Type -AssemblyName "System.Xml.Linq"
Add-Type -TypeDefinition $Source -Language CSharp  -ReferencedAssemblies ("System.Linq", "System.Xml", "System.Xml.Linq")

enum TriggerFrequency {
  Daily
  Weekly
  Monthly
  MonthlyDOW
  Once
  AtLogOn
  AtStartUp
  AtRegistration
  OnIdle
  OnEvent
  CustomTrigger
}

function New-ScheduledTaskXmlTemplate
{
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $taskName,
    [Parameter(Mandatory = $true)]
    [string]
    $taskPath,
    [Parameter(Mandatory = $true)]
    [string]
    $taskDescription,
    [Parameter(Mandatory = $true)]
    [string]
    $taskAuthor,
    [Parameter(Mandatory = $true)]
    $taskActionParameters
  )

  # create a task as template
  $action = New-ScheduledTaskAction @taskActionParameters
  $trigger = New-ScheduledTaskTrigger -Once -At 12AM
  $settingSet = New-ScheduledTaskSettingsSet

  $task = Register-ScheduledTask -TaskName  $taskName -TaskPath $taskPath -Description $taskDescription -Trigger $trigger -Action $action  -Settings $settingSet
  $task = Set-Author -taskPath $taskPath -taskName $taskName -taskAuthor $taskAuthor

  $xml = Export-ScheduledTask -TaskName $taskName -TaskPath $taskPath
  Unregister-ScheduledTask -Confirm:$false -TaskName  $taskName -TaskPath $taskPath

  return $xml
}

function Set-MonthlyTrigger
{
  param (
    [Parameter(Mandatory = $true)]
    $taskXml,
    [Parameter(Mandatory = $true)]
    [DateTime]
    $startBoundary,
    [Parameter(Mandatory = $true)]
    [Boolean]
    $enabled,
    [Parameter(Mandatory = $true)]
    [string]
    $triggerMonthlyFrequency,
    [Parameter(Mandatory = $true)]
    [string[]]
    $months,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [string[]]
    $daysOfMonth,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [string[]]
    $weeksOfMonth
  )

  $obj = New-Object SME.TaskSchedulerXml
  $element = $null
  if ($triggerMonthlyFrequency -eq 'Monthly') {
    $element = $obj.CreateMonthlyTrigger($startBoundary, $enabled, $months, $daysOfMonth)
  } elseif ( $triggerMonthlyFrequency -eq 'MonthlyDOW') {
    $element = $obj.CreateMonthlyDOWTrigger($startBoundary, $enabled, $months, $daysOfWeek, $weeksOfMonth)
  }

  $d = [System.Xml.Linq.XDocument]::Parse($taskXml)
  $obj.UpdateTriggers($element, $d)

  return $d.ToString()
}

function Set-EventTrigger
{
  param (
    [Parameter(Mandatory = $true)]
    $taskXml,
    [Parameter(Mandatory = $true)]
    [Boolean]
    $enabled,
    [Parameter(Mandatory = $true)]
    [string]
    $eventLogName,
    [Parameter(Mandatory = $true)]
    [string]
    $eventLogSource,
    [Parameter(Mandatory = $true)]
    [string]
    $eventLogId
)

  $obj = New-Object SME.TaskSchedulerXml
  $element = $obj.CreateEventTrigger($eventLogName, $eventLogSource, $eventLogId, $enabled)

  $d = [System.Xml.Linq.XDocument]::Parse($taskXml)
  $obj.UpdateTriggers($element, $d)

  return $d.ToString()
}

function Set-Author {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $taskName,
    [Parameter(Mandatory = $true)]
    [string]
    $taskPath,
    [Parameter(Mandatory = $true)]
    [string]
    $taskAuthor
  )

  $task = Get-ScheduledTask -TaskPath $taskPath -TaskNAme $taskName
  $task.Principal = $null
  $task.Author = $taskAuthor
  $task | Set-ScheduledTask
}

function Set-Properties {
  param (
    [Parameter(Mandatory = $true)]
    $settings,
    [Parameter(Mandatory = $true)]
    $object
  )

  $settings.GetEnumerator() | ForEach-Object { if ($_.value) { $object[$_.key] = $_.value} }
}

function Set-ActionParameters
{
  $taskActionParams = @{}

  $settings = @{
    'Execute' = $actionExecute
    'Argument'= $actionArguments
    'WorkingDirectory' = $workingDirectory
  }

  Set-Properties -settings $settings -object $taskActionParams

  return $taskActionParams
}

function Set-TriggerParameters
{
  $taskTriggerParams = @{}

  switch ($triggerFrequency)
  {
    Daily     { $taskTriggerParams.Daily = $true      }
    Weekly    { $taskTriggerParams.Weekly = $true     }
    Monthly   { $taskTriggerParams.Monthly = $true;   }
    Once      { $taskTriggerParams.Once = $true;      }
    AtLogOn   { $taskTriggerParams.AtLogOn = $true;   }
    AtStartup { $taskTriggerParams.AtStartup = $true; }
  }

  $settings = @{
    'At' = $triggerAt
    'DaysInterval'= $daysInterval
    'WeeksInterval' = $weeklyInterval
    'DaysOfWeek' = $daysOfWeek
  }

  Set-Properties -settings $settings -object $taskTriggerParams

  return $taskTriggerParams
}

function Test-UseXmlToCreateScheduledTask
{
  return ($triggerFrequency -eq [TriggerFrequency]::Monthly) -Or ($triggerFrequency -eq [TriggerFrequency]::OnEvent)
}

#
# Prepare action parameter bag
#
$taskActionParams = Set-ActionParameters

#
# Prepare task trigger parameter bag
#
$taskTriggerParams = Set-TriggerParameters

######################################################
#### Main script
######################################################

if (-Not (Test-UseXmlToCreateScheduledTask)) {
  # Create action, trigger and default settings
  $action = New-ScheduledTaskAction @taskActionParams
  $trigger = New-ScheduledTaskTrigger @taskTriggerParams
  $settingSet = New-ScheduledTaskSettingsSet

  # Create task
  Register-ScheduledTask -TaskName  $taskName -TaskPath $taskPath -Trigger $trigger -Action $action -Description $taskDescription -Settings $settingSet
  Set-Author -taskPath $taskPath -taskName $taskName -taskAuthor $taskAuthor
} else {

  $xml = New-ScheduledTaskXmlTemplate -taskName $taskName -taskPath $taskPath -taskDescription $taskDescription -taskAuthor $taskAuthor -taskActionParameters $taskActionParams
  $updatedXml = ''

  if ($triggerFrequency -eq [TriggerFrequency]::Monthly) {
    $updatedXml = Set-MonthlyTrigger -taskXml $xml -startBoundary $triggerAt -enabled $true -triggerMonthlyFrequency $triggerMonthlyFrequency -months $months -daysOfMonth $daysOfMonth -weeksOfMonth $weeksOfMonth
  }
  elseif ($triggerFrequency -eq [TriggerFrequency]::OnEvent) {
    $updatedXml = Set-EventTrigger -taskXml $xml -enabled $true -eventLogName $eventLogName -eventLogSource $eventLogSource -eventLogId $eventLogId
  }

  Register-ScheduledTask -Xml $updatedXml -TaskName  $taskName -TaskPath $taskPath
}

}
## [END] New-BasicTask ##
function Remove-ScheduledTask {
<#

.SYNOPSIS
Script to delete a scheduled tasks.

.DESCRIPTION
Script to delete a scheduled tasks.

.ROLE
Administrators

#>

param (
  [Parameter(Mandatory = $true)]
  [String]
  $taskPath,

  [Parameter(Mandatory = $true)]
  [String]
  $taskName
)

Import-Module ScheduledTasks

ScheduledTasks\Unregister-ScheduledTask -TaskPath $taskPath -TaskName $taskName -Confirm:$false

}
## [END] Remove-ScheduledTask ##
function Remove-ScheduledTaskAction {
<#

.SYNOPSIS
Removes action from scheduled task actions.

.DESCRIPTION
Removes action from scheduled task actions.

.ROLE
Administrators

.PARAMETER taskName
    The name of the task

.PARAMETER taskPath
    The task path.

.PARAMETER actionExecute
    The name of executable to run. By default looks in System32 if Working Directory is not provided

.PARAMETER actionArguments
    The arguments for the executable.

.PARAMETER workingDirectory
    The path to working directory
#>

param (
    [parameter(Mandatory=$true)]
    [string]
    $taskName,
    [parameter(Mandatory=$true)]
    [string]
    $taskPath,
    [parameter(Mandatory=$true)]
    [string]
    $actionExecute,
    [string]
    $actionArguments,
    [string]
    $workingDirectory
)

Import-Module ScheduledTasks


######################################################
#### Main script
######################################################

$task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
$actionsArray =  @()

$task.Actions| ForEach-Object {
    $matched = $true;  
  
    if( -not ([string]::IsNullOrEmpty($_.Arguments) -and [string]::IsNullOrEmpty($actionArguments)))
    {
        if ($_.Arguments -ne $actionArguments)
        {
            $matched = $false;
        }
    }

    $workingDirectoryMatched  = $true;
    if( -not ([string]::IsNullOrEmpty($_.WorkingDirectory) -and [string]::IsNullOrEmpty($workingDirectory)))
    {
        if ($_.WorkingDirectory -ne $workingDirectory)
        {
            $matched = $false;
        }
    }

    $executeMatched  = $true;
    if ($_.Execute -ne $actionExecute) 
    {
          $matched = $false;
    }

    if (-not ($matched))
    {
        $actionsArray += $_;
    }
}


Set-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $actionsArray
}
## [END] Remove-ScheduledTaskAction ##
function Set-ScheduledTaskConditions {
<#

.SYNOPSIS
Set/modify scheduled task setting set.

.DESCRIPTION
Set/modify scheduled task setting set.

.ROLE
Administrators

.PARAMETER taskName
    The name of the task

.PARAMETER taskPath
    The task path.

.PARAMETER dontStopOnIdleEnd
    Indicates that Task Scheduler does not terminate the task if the idle condition ends before the task is completed.
    
.PARAMETER idleDurationInMins
    Specifies the amount of time that the computer must be in an idle state before Task Scheduler runs the task.
    
.PARAMETER idleWaitTimeoutInMins
   Specifies the amount of time that Task Scheduler waits for an idle condition to occur before timing out.
    
.PARAMETER restartOnIdle
   Indicates that Task Scheduler restarts the task when the computer cycles into an idle condition more than once.
    
.PARAMETER runOnlyIfIdle
    Indicates that Task Scheduler runs the task only when the computer is idle.
    
.PARAMETER allowStartIfOnBatteries
    Indicates that Task Scheduler starts if the computer is running on battery power.
    
.PARAMETER dontStopIfGoingOnBatteries
    Indicates that the task does not stop if the computer switches to battery power.

.PARAMETER runOnlyIfNetworkAvailable
    Indicates that Task Scheduler runs the task only when a network is available. Task Scheduler uses the NetworkID parameter and NetworkName parameter that you specify in this cmdlet to determine if the network is available.

.PARAMETER networkId
    Specifies the ID of a network profile that Task Scheduler uses to determine if the task can run. You must specify the ID of a network if you specify the RunOnlyIfNetworkAvailable parameter.

.PARAMETER networkName
   Specifies the name of a network profile that Task Scheduler uses to determine if the task can run. The Task Scheduler UI uses this setting for display purposes. Specify a network name if you specify the RunOnlyIfNetworkAvailable parameter.

#>

param (
    [parameter(Mandatory=$true)]
    [string]
    $taskName,
    [parameter(Mandatory=$true)]
    [string]
    $taskPath,
    [Boolean]
    $stopOnIdleEnd,
    [string]
    $idleDuration,
    [string]
    $idleWaitTimeout,
    [Boolean]
    $restartOnIdle,
    [Boolean]
    $runOnlyIfIdle,
    [Boolean]
    $disallowStartIfOnBatteries,
    [Boolean]
    $stopIfGoingOnBatteries,
    [Boolean]
    $wakeToRun
)

Import-Module ScheduledTasks

$task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath;

# Idle related conditions.
$task.settings.RunOnlyIfIdle = $runOnlyIfIdle;

$task.Settings.IdleSettings.IdleDuration = $idleDuration;
$task.Settings.IdleSettings.WaitTimeout = $idleWaitTimeout;

$task.Settings.IdleSettings.RestartOnIdle = $restartOnIdle;
$task.Settings.IdleSettings.StopOnIdleEnd = $stopOnIdleEnd;

# Power related condition.
$task.Settings.DisallowStartIfOnBatteries = $disallowStartIfOnBatteries;

$task.Settings.StopIfGoingOnBatteries = $stopIfGoingOnBatteries;

$task.Settings.WakeToRun = $wakeToRun;

$task | Set-ScheduledTask;
}
## [END] Set-ScheduledTaskConditions ##
function Set-ScheduledTaskGeneralSettings {
<#

.SYNOPSIS
Creates and registers a new scheduled task.

.DESCRIPTION
Creates and registers a new scheduled task.

.ROLE
Administrators

.PARAMETER taskName
    The name of the task

.PARAMETER taskDescription
    The description of the task.

.PARAMETER taskPath
    The task path.

.PARAMETER username
    The username to use to run the task.
#>

param (
    [parameter(Mandatory=$true)]
    [string]
    $taskName,
    [string]
    $taskDescription,
    [parameter(Mandatory=$true)]
    [string]
    $taskPath,
    [string]
    $username
)

Import-Module ScheduledTasks

######################################################
#### Main script
######################################################

$task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
if($task) {
    
    $task.Description = $taskDescription;
  
    if ($username)
    {
        $task | Set-ScheduledTask -User $username ;
    } 
    else 
    {
        $task | Set-ScheduledTask
    }
}
}
## [END] Set-ScheduledTaskGeneralSettings ##
function Set-ScheduledTaskSettingsSet {
<#

.SYNOPSIS
Set/modify scheduled task setting set.

.DESCRIPTION
Set/modify scheduled task setting set.

.ROLE
Administrators

.PARAMETER taskName
    The name of the task

.PARAMETER taskPath
    The task path.

.PARAMETER disallowDemandStart
    Indicates that the task cannot be started by using either the Run command or the Context menu.

.PARAMETER startWhenAvailable
    Indicates that Task Scheduler can start the task at any time after its scheduled time has passed.

.PARAMETER executionTimeLimitInMins
   Specifies the amount of time that Task Scheduler is allowed to complete the task.

.PARAMETER restartIntervalInMins
    Specifies the amount of time between Task Scheduler attempts to restart the task.

.PARAMETER restartCount
    Specifies the number of times that Task Scheduler attempts to restart the task.

.PARAMETER deleteExpiredTaskAfterInMins
    Specifies the amount of time that Task Scheduler waits before deleting the task after it expires.

.PARAMETER multipleInstances
   Specifies the policy that defines how Task Scheduler handles multiple instances of the task. Possible Enum values Parallel, Queue, IgnoreNew

.PARAMETER disallowHardTerminate
   Indicates that the task cannot be terminated by using TerminateProcess.
#>

param (
    [parameter(Mandatory=$true)]
    [string]
    $taskName,
    [parameter(Mandatory=$true)]
    [string]
    $taskPath,
    [Boolean]
    $allowDemandStart,
    [Boolean]
    $allowHardTerminate,
    [Boolean]
    $startWhenAvailable, 
    [string]
    $executionTimeLimit, 
    [string]
    $restartInterval, 
    [Int32]
    $restartCount, 
    [string]
    $deleteExpiredTaskAfter,
    [Int32]
    $multipleInstances  #Parallel, Queue, IgnoreNew
    
)

Import-Module ScheduledTasks

#
# Prepare action parameter bag
#

$task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath;

$task.settings.AllowDemandStart =  $allowDemandStart;
$task.settings.AllowHardTerminate = $allowHardTerminate;

$task.settings.StartWhenAvailable = $startWhenAvailable;

if ($executionTimeLimit -eq $null -or $executionTimeLimit -eq '') {
    $task.settings.ExecutionTimeLimit = 'PT0S';
} 
else 
{
    $task.settings.ExecutionTimeLimit = $executionTimeLimit;
} 

if ($restartInterval -eq $null -or $restartInterval -eq '') {
    $task.settings.RestartInterval = $null;
} 
else
{
    $task.settings.RestartInterval = $restartInterval;
} 

if ($restartCount -gt 0) {
    $task.settings.RestartCount = $restartCount;
}
<#if ($deleteExpiredTaskAfter -eq '' -or $deleteExpiredTaskAfter -eq $null) {
    $task.settings.DeleteExpiredTaskAfter = $null;
}
else 
{
    $task.settings.DeleteExpiredTaskAfter = $deleteExpiredTaskAfter;
}#>

if ($multipleInstances) {
    $task.settings.MultipleInstances = $multipleInstances;
}

$task | Set-ScheduledTask ;
}
## [END] Set-ScheduledTaskSettingsSet ##
function Start-ScheduledTask {
<#

.SYNOPSIS
Script to start a scheduled tasks.

.DESCRIPTION
Script to start a scheduled tasks.

.ROLE
Administrators

#>

param (
  [Parameter(Mandatory = $true)]
  [String]
  $taskPath,

  [Parameter(Mandatory = $true)]
  [String]
  $taskName
)

Import-Module ScheduledTasks

Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName | ScheduledTasks\Start-ScheduledTask

}
## [END] Start-ScheduledTask ##
function Stop-ScheduledTask {
<#

.SYNOPSIS
Script to stop a scheduled tasks.

.DESCRIPTION
Script to stop a scheduled tasks.

.ROLE
Administrators

#>

param (
  [Parameter(Mandatory = $true)]
  [String]
  $taskPath,

  [Parameter(Mandatory = $true)]
  [String]
  $taskName
)

Import-Module ScheduledTasks

Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName | ScheduledTasks\Stop-ScheduledTask

}
## [END] Stop-ScheduledTask ##
function Update-ScheduledTaskAction {
<#

.SYNOPSIS
Updates existing scheduled task action.

.DESCRIPTION
Updates existing scheduled task action.

.ROLE
Administrators

.PARAMETER taskName
    The name of the task

.PARAMETER taskPath
    The task path.

.PARAMETER oldActionExecute
    The name of executable to run. By default looks in System32 if Working Directory is not provided

.PARAMETER newActionExecute
    The name of executable to run. By default looks in System32 if Working Directory is not provided

.PARAMETER oldActionArguments
    The arguments for the executable.

.PARAMETER newActionArguments
    The arguments for the executable.

.PARAMETER oldWorkingDirectory
    The path to working directory

.PARAMETER newWorkingDirectory
    The path to working directory
#>

param (
    [parameter(Mandatory=$true)]
    [string]
    $taskName,
    [parameter(Mandatory=$true)]
    [string]
    $taskPath,
    [parameter(Mandatory=$true)]
    [string]
    $newActionExecute,
    [parameter(Mandatory=$true)]
    [string]
    $oldActionExecute,
    [string]
    $newActionArguments,
    [string]
    $oldActionArguments,
    [string]
    $newWorkingDirectory,
    [string]
    $oldWorkingDirectory
)

Import-Module ScheduledTasks


######################################################
#### Main script
######################################################

$task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
$actionsArray = $task.Actions

foreach ($action in $actionsArray) {
    $argMatched = $true;
    if( -not ([string]::IsNullOrEmpty($action.Arguments) -and [string]::IsNullOrEmpty($oldActionArguments)))
    {
        if ($action.Arguments -ne $oldActionArguments)
        {
            $argMatched = $false;
        }
    }

    $workingDirectoryMatched  = $true;
    if( -not ([string]::IsNullOrEmpty($action.WorkingDirectory) -and [string]::IsNullOrEmpty($oldWorkingDirectory)))
    {
        if ($action.WorkingDirectory -ne $oldWorkingDirectory)
        {
            $workingDirectoryMatched = $false;
        }
    }

    $executeMatched  = $true;
    if ($action.Execute -ne $oldActionExecute) 
    {
          $executeMatched = $false;
    }

    if ($argMatched -and $executeMatched -and $workingDirectoryMatched)
    {
        $action.Execute = $newActionExecute;
        $action.Arguments = $newActionArguments;
        $action.WorkingDirectory = $newWorkingDirectory;
        break
    }
}


Set-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $actionsArray
}
## [END] Update-ScheduledTaskAction ##
function Update-ScheduledTaskTrigger {
 <#

.SYNOPSIS
Adds a new trigger to existing scheduled task triggers.

.DESCRIPTION
Adds a new trigger to existing scheduled task triggers.

.ROLE
Administrators

.PARAMETER taskName
    The name of the task

.PARAMETER taskPath
    The task path.

.PARAMETER triggerClassName
    The cim class Name for Trigger being edited.

.PARAMETER triggersToCreate
    Collections of triggers to create/edit, should be of same type. The script will preserve any other trigger than cim class specified in triggerClassName. 
    This is done because individual triggers can not be identified by Id. Everytime update to any trigger is made we recreate all triggers that are of the same type supplied by user in triggers to create collection.
#>
 param (
    [parameter(Mandatory=$true)]
    [string]
    $taskName,
    [parameter(Mandatory=$true)]
    [string]
    $taskPath,
    [string]
    $triggerClassName,
    [object[]]
    $triggersToCreate
)

Import-Module ScheduledTasks

######################################################
#### Functions
######################################################


function Create-Trigger 
 {
    Param (
    [object]
    $trigger
    )

    if($trigger) 
    {
        #
        # Prepare task trigger parameter bag
        #
        $taskTriggerParams = @{} 
        # Parameter is not required while creating Logon trigger /startup Trigger
        if ($trigger.triggerAt -and $trigger.triggerFrequency -in ('Daily','Weekly', 'Once')) {
           $taskTriggerParams.At =  $trigger.triggerAt;
        }
   
    
        # Build optional switches
        if ($trigger.triggerFrequency -eq 'Daily')
        {
            $taskTriggerParams.Daily = $true;
        }
        elseif ($trigger.triggerFrequency -eq 'Weekly')
        {
            $taskTriggerParams.Weekly = $true;
            if ($trigger.weeksInterval -and $trigger.weeksInterval -ne 0) 
            {
               $taskTriggerParams.WeeksInterval = $trigger.weeksInterval;
            }
            if ($trigger.daysOfWeek) 
            {
               $taskTriggerParams.DaysOfWeek = $trigger.daysOfWeek;
            }
        }
        elseif ($trigger.triggerFrequency -eq 'Once')
        {
            $taskTriggerParams.Once = $true;
        }
        elseif ($trigger.triggerFrequency -eq 'AtLogOn')
        {
            $taskTriggerParams.AtLogOn = $true;
        }
        elseif ($trigger.triggerFrequency -eq 'AtStartup')
        {
            $taskTriggerParams.AtStartup = $true;
        }


        if ($trigger.daysInterval -and $trigger.daysInterval -ne 0) 
        {
           $taskTriggerParams.DaysInterval = $trigger.daysInterval;
        }
        
        if ($trigger.username) 
        {
           $taskTriggerParams.User = $trigger.username;
        }


        # Create trigger object
        $triggerNew = New-ScheduledTaskTrigger @taskTriggerParams

        $task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
       
        Set-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Trigger $triggerNew | out-null

        $task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
     

        if ($trigger.repetitionInterval -and $task.Triggers[0].Repetition -ne $null) 
        {
           $task.Triggers[0].Repetition.Interval = $trigger.repetitionInterval;
        }
        if ($trigger.repetitionDuration -and $task.Triggers[0].Repetition -ne $null) 
        {
           $task.Triggers[0].Repetition.Duration = $trigger.repetitionDuration;
        }
        if ($trigger.stopAtDurationEnd -and $task.Triggers[0].Repetition -ne $null) 
        {
           $task.Triggers[0].Repetition.StopAtDurationEnd = $trigger.stopAtDurationEnd;
        }
        if($trigger.executionTimeLimit) 
        {
            $task.Triggers[0].ExecutionTimeLimit = $trigger.executionTimeLimit;
        }
        if($trigger.randomDelay -ne '')
        {
            if([bool]($task.Triggers[0].PSobject.Properties.name -eq "RandomDelay")) 
            {
                $task.Triggers[0].RandomDelay = $trigger.randomDelay;
            }

            if([bool]($task.Triggers[0].PSobject.Properties.name -eq "Delay")) 
            {
                $task.Triggers[0].Delay = $trigger.randomDelay;
            }
        }

        if($trigger.enabled -ne $null) 
        {
            $task.Triggers[0].Enabled = $trigger.enabled;
        }

        if($trigger.endBoundary -and $trigger.endBoundary -ne '') 
        {
            $date = [datetime]($trigger.endBoundary);
            $task.Triggers[0].EndBoundary = $date.ToString("yyyy-MM-ddTHH:mm:sszzz"); #convert date to specific string.
        }

        # Activation date is also stored in StartBoundary for Logon/Startup triggers. Setting it in appropriate context
        if($trigger.triggerAt -ne '' -and $trigger.triggerAt -ne $null -and $trigger.triggerFrequency -in ('AtLogOn','AtStartup')) 
        {
            $date = [datetime]($trigger.triggerAt);
            $task.Triggers[0].StartBoundary = $date.ToString("yyyy-MM-ddTHH:mm:sszzz"); #convert date to specific string.
        }


        return  $task.Triggers[0];
       } # end if
 }

######################################################
#### Main script
######################################################

$task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
$triggers = $task.Triggers;
$allTriggers = @()
try {

    foreach ($t in $triggers)
    {
        # Preserve all the existing triggers which are of different type then the modified trigger type.
        if ($t.CimClass.CimClassName -ne $triggerClassName) 
        {
            $allTriggers += $t;
        } 
    }

     # Once all other triggers are preserved, recreate the ones passed on by the UI
     foreach ($t in $triggersToCreate)
     {
        $newTrigger = Create-Trigger -trigger $t
        $allTriggers += $newTrigger;
     }

    Set-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Trigger $allTriggers
} 
catch 
{
     Set-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Trigger $triggers
     throw $_.Exception
}

}
## [END] Update-ScheduledTaskTrigger ##
function Get-CimWin32LogicalDisk {
<#

.SYNOPSIS
Gets Win32_LogicalDisk object.

.DESCRIPTION
Gets Win32_LogicalDisk object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_LogicalDisk

}
## [END] Get-CimWin32LogicalDisk ##
function Get-CimWin32NetworkAdapter {
<#

.SYNOPSIS
Gets Win32_NetworkAdapter object.

.DESCRIPTION
Gets Win32_NetworkAdapter object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_NetworkAdapter

}
## [END] Get-CimWin32NetworkAdapter ##
function Get-CimWin32PhysicalMemory {
<#

.SYNOPSIS
Gets Win32_PhysicalMemory object.

.DESCRIPTION
Gets Win32_PhysicalMemory object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_PhysicalMemory

}
## [END] Get-CimWin32PhysicalMemory ##
function Get-CimWin32Processor {
<#

.SYNOPSIS
Gets Win32_Processor object.

.DESCRIPTION
Gets Win32_Processor object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_Processor

}
## [END] Get-CimWin32Processor ##
function Get-ClusterInventory {
<#

.SYNOPSIS
Retrieves the inventory data for a cluster.

.DESCRIPTION
Retrieves the inventory data for a cluster.

.ROLE
Readers

#>

import-module CimCmdlets -ErrorAction SilentlyContinue

# JEA code requires to pre-import the module (this is slow on failover cluster environment.)
import-module FailoverClusters -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Get the name of this computer.

.DESCRIPTION
Get the best available name for this computer.  The FQDN is preferred, but when not avaialble
the NetBIOS name will be used instead.

#>

function getComputerName() {
    $computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object Name, DNSHostName

    if ($computerSystem) {
        $computerName = $computerSystem.DNSHostName

        if ($null -eq $computerName) {
            $computerName = $computerSystem.Name
        }

        return $computerName
    }

    return $null
}

<#

.SYNOPSIS
Are the cluster PowerShell cmdlets installed on this server?

.DESCRIPTION
Are the cluster PowerShell cmdlets installed on this server?

#>

function getIsClusterCmdletAvailable() {
    $cmdlet = Get-Command "Get-Cluster" -ErrorAction SilentlyContinue

    return !!$cmdlet
}

<#

.SYNOPSIS
Get the MSCluster Cluster CIM instance from this server.

.DESCRIPTION
Get the MSCluster Cluster CIM instance from this server.

#>
function getClusterCimInstance() {
    $namespace = Get-CimInstance -Namespace root/MSCluster -ClassName __NAMESPACE -ErrorAction SilentlyContinue

    if ($namespace) {
        return Get-CimInstance -Namespace root/mscluster MSCluster_Cluster -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object fqdn, S2DEnabled
    }

    return $null
}


<#

.SYNOPSIS
Determines if the current cluster supports Failover Clusters Time Series Database.

.DESCRIPTION
Use the existance of the path value of cmdlet Get-StorageHealthSetting to determine if TSDB 
is supported or not.

#>
function getClusterPerformanceHistoryPath() {
    return $null -ne (Get-StorageSubSystem clus* | Get-StorageHealthSetting -Name "System.PerformanceHistory.Path")
}

<#

.SYNOPSIS
Get some basic information about the cluster from the cluster.

.DESCRIPTION
Get the needed cluster properties from the cluster.

#>
function getClusterInfo() {
    $returnValues = @{}

    $returnValues.Fqdn = $null
    $returnValues.isS2DEnabled = $false
    $returnValues.isTsdbEnabled = $false

    $cluster = getClusterCimInstance
    if ($cluster) {
        $returnValues.Fqdn = $cluster.fqdn
        $isS2dEnabled = !!(Get-Member -InputObject $cluster -Name "S2DEnabled") -and ($cluster.S2DEnabled -eq 1)
        $returnValues.isS2DEnabled = $isS2dEnabled

        if ($isS2DEnabled) {
            $returnValues.isTsdbEnabled = getClusterPerformanceHistoryPath
        } else {
            $returnValues.isTsdbEnabled = $false
        }
    }

    return $returnValues
}

<#

.SYNOPSIS
Are the cluster PowerShell Health cmdlets installed on this server?

.DESCRIPTION
Are the cluster PowerShell Health cmdlets installed on this server?

s#>
function getisClusterHealthCmdletAvailable() {
    $cmdlet = Get-Command -Name "Get-HealthFault" -ErrorAction SilentlyContinue

    return !!$cmdlet
}
<#

.SYNOPSIS
Are the Britannica (sddc management resources) available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) available on the cluster?

#>
function getIsBritannicaEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_Cluster -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Are the Britannica (sddc management resources) virtual machine available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) virtual machine available on the cluster?

#>
function getIsBritannicaVirtualMachineEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_VirtualMachine -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Are the Britannica (sddc management resources) virtual switch available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) virtual switch available on the cluster?

#>
function getIsBritannicaVirtualSwitchEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_VirtualSwitch -ErrorAction SilentlyContinue)
}

###########################################################################
# main()
###########################################################################

$clusterInfo = getClusterInfo

$result = New-Object PSObject

$result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $clusterInfo.Fqdn
$result | Add-Member -MemberType NoteProperty -Name 'IsS2DEnabled' -Value $clusterInfo.isS2DEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsTsdbEnabled' -Value $clusterInfo.isTsdbEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsClusterHealthCmdletAvailable' -Value (getIsClusterHealthCmdletAvailable)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaEnabled' -Value (getIsBritannicaEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaVirtualMachineEnabled' -Value (getIsBritannicaVirtualMachineEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaVirtualSwitchEnabled' -Value (getIsBritannicaVirtualSwitchEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsClusterCmdletAvailable' -Value (getIsClusterCmdletAvailable)
$result | Add-Member -MemberType NoteProperty -Name 'CurrentClusterNode' -Value (getComputerName)

$result

}
## [END] Get-ClusterInventory ##
function Get-ClusterNodes {
<#

.SYNOPSIS
Retrieves the inventory data for cluster nodes in a particular cluster.

.DESCRIPTION
Retrieves the inventory data for cluster nodes in a particular cluster.

.ROLE
Readers

#>

import-module CimCmdlets

# JEA code requires to pre-import the module (this is slow on failover cluster environment.)
import-module FailoverClusters -ErrorAction SilentlyContinue

###############################################################################
# Constants
###############################################################################

Set-Variable -Name LogName -Option Constant -Value "Microsoft-ServerManagementExperience" -ErrorAction SilentlyContinue
Set-Variable -Name LogSource -Option Constant -Value "SMEScripts" -ErrorAction SilentlyContinue
Set-Variable -Name ScriptName -Option Constant -Value $MyInvocation.ScriptName -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Are the cluster PowerShell cmdlets installed?

.DESCRIPTION
Use the Get-Command cmdlet to quickly test if the cluster PowerShell cmdlets
are installed on this server.

#>

function getClusterPowerShellSupport() {
    $cmdletInfo = Get-Command 'Get-ClusterNode' -ErrorAction SilentlyContinue

    return $cmdletInfo -and $cmdletInfo.Name -eq "Get-ClusterNode"
}

<#

.SYNOPSIS
Get the cluster nodes using the cluster CIM provider.

.DESCRIPTION
When the cluster PowerShell cmdlets are not available fallback to using
the cluster CIM provider to get the needed information.

#>

function getClusterNodeCimInstances() {
    # Change the WMI property NodeDrainStatus to DrainStatus to match the PS cmdlet output.
    return Get-CimInstance -Namespace root/mscluster MSCluster_Node -ErrorAction SilentlyContinue | `
        Microsoft.PowerShell.Utility\Select-Object @{Name="DrainStatus"; Expression={$_.NodeDrainStatus}}, DynamicWeight, Name, NodeWeight, FaultDomain, State
}

<#

.SYNOPSIS
Get the cluster nodes using the cluster PowerShell cmdlets.

.DESCRIPTION
When the cluster PowerShell cmdlets are available use this preferred function.

#>

function getClusterNodePsInstances() {
    return Get-ClusterNode -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object DrainStatus, DynamicWeight, Name, NodeWeight, FaultDomain, State
}

<#

.SYNOPSIS
Use DNS services to get the FQDN of the cluster NetBIOS name.

.DESCRIPTION
Use DNS services to get the FQDN of the cluster NetBIOS name.

.Notes
It is encouraged that the caller add their approprate -ErrorAction when
calling this function.

#>

function getClusterNodeFqdn([string]$clusterNodeName) {
    return ([System.Net.Dns]::GetHostEntry($clusterNodeName)).HostName
}

<#

.SYNOPSIS
Writes message to event log as warning.

.DESCRIPTION
Writes message to event log as warning.

#>

function writeToEventLog([string]$message) {
    Microsoft.PowerShell.Management\New-EventLog -LogName $LogName -Source $LogSource -ErrorAction SilentlyContinue
    Microsoft.PowerShell.Management\Write-EventLog -LogName $LogName -Source $LogSource -EventId 0 -Category 0 -EntryType Warning `
        -Message $message  -ErrorAction SilentlyContinue
}

<#

.SYNOPSIS
Get the cluster nodes.

.DESCRIPTION
When the cluster PowerShell cmdlets are available get the information about the cluster nodes
using PowerShell.  When the cmdlets are not available use the Cluster CIM provider.

#>

function getClusterNodes() {
    $isClusterCmdletAvailable = getClusterPowerShellSupport

    if ($isClusterCmdletAvailable) {
        $clusterNodes = getClusterNodePsInstances
    } else {
        $clusterNodes = getClusterNodeCimInstances
    }

    $clusterNodeMap = @{}

    foreach ($clusterNode in $clusterNodes) {
        $clusterNodeName = $clusterNode.Name.ToLower()
        try 
        {
            $clusterNodeFqdn = getClusterNodeFqdn $clusterNodeName -ErrorAction SilentlyContinue
        }
        catch 
        {
            $clusterNodeFqdn = $clusterNodeName
            writeToEventLog "[$ScriptName]: The fqdn for node '$clusterNodeName' could not be obtained. Defaulting to machine name '$clusterNodeName'"
        }

        $clusterNodeResult = New-Object PSObject

        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'FullyQualifiedDomainName' -Value $clusterNodeFqdn
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'Name' -Value $clusterNodeName
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'DynamicWeight' -Value $clusterNode.DynamicWeight
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'NodeWeight' -Value $clusterNode.NodeWeight
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'FaultDomain' -Value $clusterNode.FaultDomain
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'State' -Value $clusterNode.State
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'DrainStatus' -Value $clusterNode.DrainStatus

        $clusterNodeMap.Add($clusterNodeName, $clusterNodeResult)
    }

    return $clusterNodeMap
}

###########################################################################
# main()
###########################################################################

getClusterNodes

}
## [END] Get-ClusterNodes ##
function Get-ServerInventory {
<#

.SYNOPSIS
Retrieves the inventory data for a server.

.DESCRIPTION
Retrieves the inventory data for a server.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0

Import-Module CimCmdlets

<#

.SYNOPSIS
Converts an arbitrary version string into just 'Major.Minor'

.DESCRIPTION
To make OS version comparisons we only want to compare the major and 
minor version.  Build number and/os CSD are not interesting.

#>

function convertOsVersion([string]$osVersion) {
    [Ref]$parsedVersion = $null
    if (![Version]::TryParse($osVersion, $parsedVersion)) {
        return $null
    }

    $version = [Version]$parsedVersion.Value
    return New-Object Version -ArgumentList $version.Major, $version.Minor
}

<#

.SYNOPSIS
Determines if CredSSP is enabled for the current server or client.

.DESCRIPTION
Check the registry value for the CredSSP enabled state.

#>

function isCredSSPEnabled() {
    Set-Variable credSSPServicePath -Option Constant -Value "WSMan:\localhost\Service\Auth\CredSSP"
    Set-Variable credSSPClientPath -Option Constant -Value "WSMan:\localhost\Client\Auth\CredSSP"

    $credSSPServerEnabled = $false;
    $credSSPClientEnabled = $false;

    $credSSPServerService = Get-Item $credSSPServicePath -ErrorAction SilentlyContinue
    if ($credSSPServerService) {
        $credSSPServerEnabled = [System.Convert]::ToBoolean($credSSPServerService.Value)
    }

    $credSSPClientService = Get-Item $credSSPClientPath -ErrorAction SilentlyContinue
    if ($credSSPClientService) {
        $credSSPClientEnabled = [System.Convert]::ToBoolean($credSSPClientService.Value)
    }

    return ($credSSPServerEnabled -or $credSSPClientEnabled)
}

<#

.SYNOPSIS
Determines if the Hyper-V role is installed for the current server or client.

.DESCRIPTION
The Hyper-V role is installed when the VMMS service is available.  This is much
faster then checking Get-WindowsFeature and works on Windows Client SKUs.

#>

function isHyperVRoleInstalled() {
    $vmmsService = Get-Service -Name "VMMS" -ErrorAction SilentlyContinue

    return $vmmsService -and $vmmsService.Name -eq "VMMS"
}

<#

.SYNOPSIS
Determines if the Hyper-V PowerShell support module is installed for the current server or client.

.DESCRIPTION
The Hyper-V PowerShell support module is installed when the modules cmdlets are available.  This is much
faster then checking Get-WindowsFeature and works on Windows Client SKUs.

#>
function isHyperVPowerShellSupportInstalled() {
    # quicker way to find the module existence. it doesn't load the module.
    return !!(Get-Module -ListAvailable Hyper-V -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Determines if Windows Management Framework (WMF) 5.0, or higher, is installed for the current server or client.

.DESCRIPTION
Windows Admin Center requires WMF 5 so check the registey for WMF version on Windows versions that are less than
Windows Server 2016.

#>
function isWMF5Installed([string] $operatingSystemVersion) {
    Set-Variable Server2016 -Option Constant -Value (New-Object Version '10.0')   # And Windows 10 client SKUs
    Set-Variable Server2012 -Option Constant -Value (New-Object Version '6.2')

    $version = convertOsVersion $operatingSystemVersion
    if (-not $version) {
        # Since the OS version string is not properly formatted we cannot know the true installed state.
        return $false
    }

    if ($version -ge $Server2016) {
        # It's okay to assume that 2016 and up comes with WMF 5 or higher installed
        return $true
    }
    else {
        if ($version -ge $Server2012) {
            # Windows 2012/2012R2 are supported as long as WMF 5 or higher is installed
            $registryKey = 'HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine'
            $registryKeyValue = Get-ItemProperty -Path $registryKey -Name PowerShellVersion -ErrorAction SilentlyContinue

            if ($registryKeyValue -and ($registryKeyValue.PowerShellVersion.Length -ne 0)) {
                $installedWmfVersion = [Version]$registryKeyValue.PowerShellVersion

                if ($installedWmfVersion -ge [Version]'5.0') {
                    return $true
                }
            }
        }
    }

    return $false
}

<#

.SYNOPSIS
Determines if the current usser is a system administrator of the current server or client.

.DESCRIPTION
Determines if the current usser is a system administrator of the current server or client.

#>
function isUserAnAdministrator() {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

<#

.SYNOPSIS
Get some basic information about the Failover Cluster that is running on this server.

.DESCRIPTION
Create a basic inventory of the Failover Cluster that may be running in this server.

#>
function getClusterInformation() {
    $returnValues = @{}

    $returnValues.IsS2dEnabled = $false
    $returnValues.IsCluster = $false
    $returnValues.ClusterFqdn = $null

    $namespace = Get-CimInstance -Namespace root/MSCluster -ClassName __NAMESPACE -ErrorAction SilentlyContinue
    if ($namespace) {
        $cluster = Get-CimInstance -Namespace root/MSCluster -ClassName MSCluster_Cluster -ErrorAction SilentlyContinue
        if ($cluster) {
            $returnValues.IsCluster = $true
            $returnValues.ClusterFqdn = $cluster.Fqdn
            $returnValues.IsS2dEnabled = !!(Get-Member -InputObject $cluster -Name "S2DEnabled") -and ($cluster.S2DEnabled -gt 0)
        }
    }

    return $returnValues
}

<#

.SYNOPSIS
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the passed in computer name.

.DESCRIPTION
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the passed in computer name.

#>
function getComputerFqdnAndAddress($computerName) {
    $hostEntry = [System.Net.Dns]::GetHostEntry($computerName)
    $addressList = @()
    foreach ($item in $hostEntry.AddressList) {
        $address = New-Object PSObject
        $address | Add-Member -MemberType NoteProperty -Name 'IpAddress' -Value $item.ToString()
        $address | Add-Member -MemberType NoteProperty -Name 'AddressFamily' -Value $item.AddressFamily.ToString()
        $addressList += $address
    }

    $result = New-Object PSObject
    $result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $hostEntry.HostName
    $result | Add-Member -MemberType NoteProperty -Name 'AddressList' -Value $addressList
    return $result
}

<#

.SYNOPSIS
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the current server or client.

.DESCRIPTION
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the current server or client.

#>
function getHostFqdnAndAddress($computerSystem) {
    $computerName = $computerSystem.DNSHostName
    if (!$computerName) {
        $computerName = $computerSystem.Name
    }

    return getComputerFqdnAndAddress $computerName
}

<#

.SYNOPSIS
Are the needed management CIM interfaces available on the current server or client.

.DESCRIPTION
Check for the presence of the required server management CIM interfaces.

#>
function getManagementToolsSupportInformation() {
    $returnValues = @{}

    $returnValues.ManagementToolsAvailable = $false
    $returnValues.ServerManagerAvailable = $false

    $namespaces = Get-CimInstance -Namespace root/microsoft/windows -ClassName __NAMESPACE -ErrorAction SilentlyContinue

    if ($namespaces) {
        $returnValues.ManagementToolsAvailable = !!($namespaces | Where-Object { $_.Name -ieq "ManagementTools" })
        $returnValues.ServerManagerAvailable = !!($namespaces | Where-Object { $_.Name -ieq "ServerManager" })
    }

    return $returnValues
}

<#

.SYNOPSIS
Check the remote app enabled or not.

.DESCRIPTION
Check the remote app enabled or not.

#>
function isRemoteAppEnabled() {
    Set-Variable key -Option Constant -Value "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\TSAppAllowList"

    $registryKeyValue = Get-ItemProperty -Path $key -Name fDisabledAllowList -ErrorAction SilentlyContinue

    if (-not $registryKeyValue) {
        return $false
    }
    return $registryKeyValue.fDisabledAllowList -eq 1
}

<#

.SYNOPSIS
Check the remote app enabled or not.

.DESCRIPTION
Check the remote app enabled or not.

#>

<#
c
.SYNOPSIS
Get the Win32_OperatingSystem information

.DESCRIPTION
Get the Win32_OperatingSystem instance and filter the results to just the required properties.
This filtering will make the response payload much smaller.

#>
function getOperatingSystemInfo() {
    return Get-CimInstance Win32_OperatingSystem | Microsoft.PowerShell.Utility\Select-Object csName, Caption, OperatingSystemSKU, Version, ProductType
}

<#

.SYNOPSIS
Get the Win32_ComputerSystem information

.DESCRIPTION
Get the Win32_ComputerSystem instance and filter the results to just the required properties.
This filtering will make the response payload much smaller.

#>
function getComputerSystemInfo() {
    return Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | `
        Microsoft.PowerShell.Utility\Select-Object TotalPhysicalMemory, DomainRole, Manufacturer, Model, NumberOfLogicalProcessors, Domain, Workgroup, DNSHostName, Name, PartOfDomain
}

###########################################################################
# main()
###########################################################################

$operatingSystem = getOperatingSystemInfo
$computerSystem = getComputerSystemInfo
$isAdministrator = isUserAnAdministrator
$fqdnAndAddress = getHostFqdnAndAddress $computerSystem
$hostname = hostname
$netbios = $env:ComputerName
$managementToolsInformation = getManagementToolsSupportInformation
$isWmfInstalled = isWMF5Installed $operatingSystem.Version
$clusterInformation = getClusterInformation -ErrorAction SilentlyContinue
$isHyperVPowershellInstalled = isHyperVPowerShellSupportInstalled
$isHyperVRoleInstalled = isHyperVRoleInstalled
$isCredSSPEnabled = isCredSSPEnabled
$isRemoteAppEnabled = isRemoteAppEnabled

$result = New-Object PSObject
$result | Add-Member -MemberType NoteProperty -Name 'IsAdministrator' -Value $isAdministrator
$result | Add-Member -MemberType NoteProperty -Name 'OperatingSystem' -Value $operatingSystem
$result | Add-Member -MemberType NoteProperty -Name 'ComputerSystem' -Value $computerSystem
$result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $fqdnAndAddress.Fqdn
$result | Add-Member -MemberType NoteProperty -Name 'AddressList' -Value $fqdnAndAddress.AddressList
$result | Add-Member -MemberType NoteProperty -Name 'Hostname' -Value $hostname
$result | Add-Member -MemberType NoteProperty -Name 'NetBios' -Value $netbios
$result | Add-Member -MemberType NoteProperty -Name 'IsManagementToolsAvailable' -Value $managementToolsInformation.ManagementToolsAvailable
$result | Add-Member -MemberType NoteProperty -Name 'IsServerManagerAvailable' -Value $managementToolsInformation.ServerManagerAvailable
$result | Add-Member -MemberType NoteProperty -Name 'IsWmfInstalled' -Value $isWmfInstalled
$result | Add-Member -MemberType NoteProperty -Name 'IsCluster' -Value $clusterInformation.IsCluster
$result | Add-Member -MemberType NoteProperty -Name 'ClusterFqdn' -Value $clusterInformation.ClusterFqdn
$result | Add-Member -MemberType NoteProperty -Name 'IsS2dEnabled' -Value $clusterInformation.IsS2dEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsHyperVRoleInstalled' -Value $isHyperVRoleInstalled
$result | Add-Member -MemberType NoteProperty -Name 'IsHyperVPowershellInstalled' -Value $isHyperVPowershellInstalled
$result | Add-Member -MemberType NoteProperty -Name 'IsCredSSPEnabled' -Value $isCredSSPEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsRemoteAppEnabled' -Value $isRemoteAppEnabled

$result

}
## [END] Get-ServerInventory ##
function Install-MMAgent {
<#

.SYNOPSIS
Download and install Microsoft Monitoring Agent for Windows.

.DESCRIPTION
Download and install Microsoft Monitoring Agent for Windows.

.PARAMETER workspaceId
The log analytics workspace id a target node has to connect to.

.PARAMETER workspacePrimaryKey
The primary key of log analytics workspace.

.PARAMETER taskName
The task name.

.ROLE
Readers

#>

param(
    [Parameter(Mandatory = $true)]
    [String]
    $workspaceId,
    [Parameter(Mandatory = $true)]
    [String]
    $workspacePrimaryKey,
    [Parameter(Mandatory = $true)]
    [String]
    $taskName
)

$Script = @'
$mmaExe = Join-Path -Path $env:temp -ChildPath 'MMASetup-AMD64.exe'
if (Test-Path $mmaExe) {
    Remove-Item $mmaExe
}

Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?LinkId=828603 -OutFile $mmaExe

$extractFolder = Join-Path -Path $env:temp -ChildPath 'SmeMMAInstaller'
if (Test-Path $extractFolder) {
    Remove-Item $extractFolder -Force -Recurse
}

&$mmaExe /c /t:$extractFolder
$setupExe = Join-Path -Path $extractFolder -ChildPath 'setup.exe'
for ($i=1; $i -le 10; $i++) {
    if(-Not(Test-Path $setupExe)) {
        sleep -s 6
    }
}

&$setupExe /qn NOAPM=1 ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=0 OPINSIGHTS_WORKSPACE_ID=$workspaceId OPINSIGHTS_WORKSPACE_KEY=$workspacePrimaryKey AcceptEndUserLicenseAgreement=1
'@

$Script = '$workspaceId = ' + "'$workspaceId';" + $Script
$Script = '$workspacePrimaryKey =' + "'$workspacePrimaryKey';" + $Script

$ScriptFile = Join-Path -Path $env:LocalAppData -ChildPath "$taskName.ps1"
$ResultFile = Join-Path -Path $env:temp -ChildPath "$taskName.log"
if (Test-Path $ResultFile) {
    Remove-Item $ResultFile
}

$Script | Out-File $ScriptFile
if (-Not(Test-Path $ScriptFile)) {
    $message = "Failed to create file:" + $ScriptFile
    Write-Error $message
    return #If failed to create script file, no need continue just return here
}

#Create a scheduled task
$User = [Security.Principal.WindowsIdentity]::GetCurrent()
$Role = (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$arg = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -c $ScriptFile >> $ResultFile 2>&1"
if(!$Role)
{
  Write-Warning "To perform some operations you must run an elevated Windows PowerShell console."
}

$Scheduler = New-Object -ComObject Schedule.Service

#Try to connect to schedule service 3 time since it may fail the first time
for ($i=1; $i -le 3; $i++)
{
  Try
  {
    $Scheduler.Connect()
    Break
  }
  Catch
  {
    if($i -ge 3)
    {
      Write-EventLog -LogName Application -Source "SME Register $taskName" -EntryType Error -EventID 1 -Message "Can't connect to Schedule service"
      Write-Error "Can't connect to Schedule service" -ErrorAction Stop
    }
    else
    {
      Start-Sleep -s 1
    }
  }
}

$RootFolder = $Scheduler.GetFolder("\")
#Delete existing task
if($RootFolder.GetTasks(0) | Where-Object {$_.Name -eq $TaskName})
{
  Write-Debug("Deleting existing task" + $TaskName)
  $RootFolder.DeleteTask($TaskName,0)
}

$Task = $Scheduler.NewTask(0)
$RegistrationInfo = $Task.RegistrationInfo
$RegistrationInfo.Description = $TaskName
$RegistrationInfo.Author = $User.Name

$Triggers = $Task.Triggers
$Trigger = $Triggers.Create(7) #TASK_TRIGGER_REGISTRATION: Starts the task when the task is registered.
$Trigger.Enabled = $true

$Settings = $Task.Settings
$Settings.Enabled = $True
$Settings.StartWhenAvailable = $True
$Settings.Hidden = $False
$Settings.ExecutionTimeLimit  = "PT20M" # 20 minutes

$Action = $Task.Actions.Create(0)
$Action.Path = "powershell"
$Action.Arguments = $arg

#Tasks will be run with the highest privileges
$Task.Principal.RunLevel = 1

#Start the task to run in Local System account. 6: TASK_CREATE_OR_UPDATE
$RootFolder.RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $Null, 1) | Out-Null
#Wait for running task finished
$RootFolder.GetTask($TaskName).Run(0) | Out-Null
while($Scheduler.GetRunningTasks(0) | Where-Object {$_.Name -eq $TaskName})
{
  Start-Sleep -s 1
}

#Clean up
$RootFolder.DeleteTask($TaskName,0)
Remove-Item $ScriptFile

if (Test-Path $ResultFile)
{
    Get-Content -Path $ResultFile | Out-String -Stream
    Remove-Item $ResultFile
}

}
## [END] Install-MMAgent ##

# SIG # Begin signature block
# MIIdkgYJKoZIhvcNAQcCoIIdgzCCHX8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtbKXP/T8/zOUxwDF47rJz66m
# jQugghhuMIIE3jCCA8agAwIBAgITMwAAAOtpqsw+KZ8tOQAAAAAA6zANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgwODIzMjAxOTMw
# WhcNMTkxMTIzMjAxOTMwWjCBzjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJp
# Y28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkI4RUMtMzBBNC03MTQ0MSUwIwYD
# VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAtUgVMTCRT4OJO0Mpuwvx+XO5QmP3h0rKAKfeLGh8
# EaWmLrpncRID7XmyosZLraSDHoz/hauMvlnCJFE+iMTvTDkSiioNZcAKBK7JDIq0
# vPzA559v2UunwBHaU+NueS6nYTBx54n6I4QpiE8/wr3dMz4e10eBAXd8h4OZ4ZK/
# YmJfSxJUGMSn70yzmSuKhQ7tIqUmmUSIt2Z3vu/zRhbKi8Aind4+ASRFpYMuE+1h
# D4jIpwJ1CUjZZhI0UsDRa7mz6CO2RwCUXPRjgXXvTfrv2zv+F8jDbTfEXs8RZPLw
# 3eIFo06gqUfYhp1Ufw+/7Oesc5rM4OkRY1TG2jD/ne5PqQIDAQABo4IBCTCCAQUw
# HQYDVR0OBBYEFAW30KaPfAOZ1HwiXZI8utZ3J6amMB8GA1UdIwQYMBaAFCM0+NlS
# RnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly9jcmwubWlj
# cm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY3Jvc29mdFRpbWVTdGFtcFBD
# QS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsGAQUFBzAChjxodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcnQw
# EwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQEFBQADggEBAHvg1mBCSvjq
# wnWpRZF0s84/duMABrGAur2JSbcCMVeY1Gz9xftubwtIkxaUSqtyUkGOJVdgwlUM
# ZAT4/up2bRT896uVKcEHNweSFLqPxfeJFgsUzQ+z9ftH4S9+IX+V7o0HB4VoB92Q
# 9Qdd56HqRJFaLzbsppXJpSXbbdtrBjjfohYSrkzlcedWQ6sANjswlYbZ4cWxGDEB
# 3ad8YTzLnPZtcwY4R4n49UOnUavG/NB0tJRUbMOO4fyUAMBr4R20tYudgvoXRK8B
# VVEfYP6mQa1QG6Mh3oluJb3jJ7pYpDfMMRXh3S9Y6pofu67todxbL7afn1Vi11d6
# /bjN6QMHSnYwggX/MIID56ADAgECAhMzAAABA14lHJkfox64AAAAAAEDMA0GCSqG
# SIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# KDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwHhcNMTgw
# NzEyMjAwODQ4WhcNMTkwNzI2MjAwODQ4WjB0MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNyb3NvZnQgQ29ycG9yYXRpb24w
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDRlHY25oarNv5p+UZ8i4hQ
# y5Bwf7BVqSQdfjnnBZ8PrHuXss5zCvvUmyRcFrU53Rt+M2wR/Dsm85iqXVNrqsPs
# E7jS789Xf8xly69NLjKxVitONAeJ/mkhvT5E+94SnYW/fHaGfXKxdpth5opkTEbO
# ttU6jHeTd2chnLZaBl5HhvU80QnKDT3NsumhUHjRhIjiATwi/K+WCMxdmcDt66Va
# mJL1yEBOanOv3uN0etNfRpe84mcod5mswQ4xFo8ADwH+S15UD8rEZT8K46NG2/Ys
# AzoZvmgFFpzmfzS/p4eNZTkmyWPU78XdvSX+/Sj0NIZ5rCrVXzCRO+QUauuxygQj
# AgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEEAYI3TAgBBggrBgEFBQcDAzAd
# BgNVHQ4EFgQUR77Ay+GmP/1l1jjyA123r3f3QP8wUAYDVR0RBEkwR6RFMEMxKTAn
# BgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMRYwFAYDVQQF
# Ew0yMzAwMTIrNDM3OTY1MB8GA1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKV
# MFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUH
# AQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0T
# AQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAn/XJUw0/DSbsokTYDdGfY5YGSz8e
# XMUzo6TDbK8fwAG662XsnjMQD6esW9S9kGEX5zHnwya0rPUn00iThoj+EjWRZCLR
# ay07qCwVlCnSN5bmNf8MzsgGFhaeJLHiOfluDnjYDBu2KWAndjQkm925l3XLATut
# ghIWIoCJFYS7mFAgsBcmhkmvzn1FFUM0ls+BXBgs1JPyZ6vic8g9o838Mh5gHOmw
# GzD7LLsHLpaEk0UoVFzNlv2g24HYtjDKQ7HzSMCyRhxdXnYqWJ/U7vL0+khMtWGL
# sIxB6aq4nZD0/2pCD7k+6Q7slPyNgLt44yOneFuybR/5WcF9ttE5yXnggxxgCto9
# sNHtNr9FB+kbNm7lPTsFA6fUpyUSj+Z2oxOzRVpDMYLa2ISuubAfdfX2HX1RETcn
# 6LU1hHH3V6qu+olxyZjSnlpkdr6Mw30VapHxFPTy2TUxuNty+rR1yIibar+YRcdm
# stf/zpKQdeTr5obSyBvbJ8BblW9Jb1hdaSreU0v46Mp79mwV+QMZDxGFqk+av6pX
# 3WDG9XEg9FGomsrp0es0Rz11+iLsVT9qGTlrEOlaP470I3gwsvKmOMs1jaqYWSRA
# uDpnpAdfoP7YO0kT+wzh7Qttg1DO8H8+4NkI6IwhSkHC3uuOW+4Dwx1ubuZUNWZn
# cnwa6lL2IsRyP64wggYHMIID76ADAgECAgphFmg0AAAAAAAcMA0GCSqGSIb3DQEB
# BQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJk/IsZAEZFgltaWNy
# b3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMxMzAzMDlaMHcxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJ+h
# bLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn0UytdDAgEesH1VSVFUmUG0KS
# rphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0Zxws/HvniB3q506jocEjU8qN
# +kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4nrIZPVVIM5AMs+2qQkDBuh/NZ
# MJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YRJylmqJfk0waBSqL5hKcRRxQJ
# gp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54QTF3zJvfO4OToWECtR0Nsfz3
# m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8GA1UdEwEB/wQFMAMBAf8wHQYD
# VR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsGA1UdDwQEAwIBhjAQBgkrBgEE
# AYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJgQFYnl+UlE/wq4QpTlVnkpKFj
# pGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jv
# c29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL21pY3Jvc29mdHJvb3Rj
# ZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0Um9vdENlcnQuY3J0MBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBBQUAA4ICAQAQl4rDXANENt3p
# tK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1iuFcCy04gE1CZ3XpA4le7r1ia
# HOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+rkuTnjWrVgMHmlPIGL4UD6ZEq
# JCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGctxVEO6mJcPxaYiyA/4gcaMvnM
# MUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/FNSteo7/rvH0LQnvUU3Ih7jDK
# u3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbonXCUbKw5TNT2eb+qGHpiKe+i
# myk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0NbhOxXEjEiZ2CzxSjHFaRkMU
# vLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPpK+m79EjMLNTYMoBMJipIJF9a
# 6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2JoXZhtG6hE6a/qkfwEm/9ijJs
# sv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0eFQF1EEuUKyUsKV4q7OglnUa
# 2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng9wFlb4kLfchpyOZu6qeXzjEp
# /w7FW1zYTRuh2Povnj8uVRZryROj/TCCB3owggVioAMCAQICCmEOkNIAAAAAAAMw
# DQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eSAyMDExMB4XDTExMDcwODIwNTkwOVoXDTI2MDcwODIxMDkwOVowfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAKvw+nIQHC6t2G6qghBNNLrytlghn0IbKmvpWlCquAY4GgRJun/D
# DB7dN2vGEtgL8DjCmQawyDnVARQxQtOJDXlkh36UYCRsr55JnOloXtLfm1OyCizD
# r9mpK656Ca/XllnKYBoF6WZ26DJSJhIv56sIUM+zRLdd2MQuA3WraPPLbfM6XKEW
# 9Ea64DhkrG5kNXimoGMPLdNAk/jj3gcN1Vx5pUkp5w2+oBN3vpQ97/vjK1oQH01W
# KKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd6IlPhBryoS9Z5JA7La4zWMW3Pv4y
# 07MDPbGyr5I4ftKdgCz1TlaRITUlwzluZH9TupwPrRkjhMv0ugOGjfdf8NBSv4yU
# h7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOnqWbsYR9q4ShJnV+I4iVd0yFLPlLE
# tVc/JAPw0XpbL9Uj43BdD1FGd7P4AOG8rAKCX9vAFbO9G9RVS+c5oQ/pI0m8GLhE
# fEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkwp6uO3+xbn6/83bBm4sGXgXvt1u1L
# 50kppxMopqd9Z4DmimJ4X7IvhNdXnFy/dygo8e1twyiPLI9AN0/B4YVEicQJTMXU
# pUMvdJX3bvh4IFgsE11glZo+TzOE2rCIF96eTvSWsLxGoGyY0uDWiIwLAgMBAAGj
# ggHtMIIB6TAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUSG5k5VAF04KqFzc3
# IrVtqMp1ApUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUci06AjGQQ7kUBU7h6qfHMdEj
# iTQwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
# aS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNybDBe
# BggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNydDCB
# nwYDVR0gBIGXMIGUMIGRBgkrBgEEAYI3LgMwgYMwPwYIKwYBBQUHAgEWM2h0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvZG9jcy9wcmltYXJ5Y3BzLmh0bTBA
# BggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBwAG8AbABpAGMAeQBfAHMAdABh
# AHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAZ/KGpZjgVHkaLtPY
# dGcimwuWEeFjkplCln3SeQyQwWVfLiw++MNy0W2D/r4/6ArKO79HqaPzadtjvyI1
# pZddZYSQfYtGUFXYDJJ80hpLHPM8QotS0LD9a+M+By4pm+Y9G6XUtR13lDni6WTJ
# RD14eiPzE32mkHSDjfTLJgJGKsKKELukqQUMm+1o+mgulaAqPyprWEljHwlpblqY
# luSD9MCP80Yr3vw70L01724lruWvJ+3Q3fMOr5kol5hNDj0L8giJ1h/DMhji8MUt
# zluetEk5CsYKwsatruWy2dsViFFFWDgycScaf7H0J/jeLDogaZiyWYlobm+nt3TD
# QAUGpgEqKD6CPxNNZgvAs0314Y9/HG8VfUWnduVAKmWjw11SYobDHWM2l4bf2vP4
# 8hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1HxS+YWG18NzGGwS+30HHDiju3mUv
# 7Jf2oVyW2ADWoUa9WfOXpQlLSBCZgB/QACnFsZulP0V3HjXG0qKin3p6IvpIlR+r
# +0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9azI2h15q/6/IvrC4DqaTuv/DDtBEyO
# 3991bWORPdGdVk5Pv4BXIqF4ETIheu9BCrE/+6jMpF3BoYibV3FWTkhFwELJm3Zb
# CoBIa/15n8G9bW1qyVJzEw16UM0xggSOMIIEigIBATCBlTB+MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29k
# ZSBTaWduaW5nIFBDQSAyMDExAhMzAAABA14lHJkfox64AAAAAAEDMAkGBSsOAwIa
# BQCggaIwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFOsNT86449govD7tmHhZd1yB
# +vMDMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBho
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEATHiIBCkT
# ETJvWZ1L2PWZ5Pec86nLlVKay3yeyYrcE890GmkBKDcA1/XvjMS688EU/otII/WH
# 8oRXUWKoLhJM3h0bPmZZIn6GAFhmas6Lo1B22NzU6UBQMDVEmj+ndC3RNmv7sL39
# vMIjVu0HX4iCPsxk0AlC/oSyYUdj7/fQe3Ka3YPI25iFTHx75aRhQl3eid68k1XQ
# oisLD4L/QVdVLrdW8W2Q4HCHmJKioZ4aHM6gfBI7L/EvwplIdVG0572AyUUsiA4J
# Nercts14R35GukHBIa1yU/xwfYIUbGpzgU96a/h1j7dtll81gXSAyFWzoHBWDvr7
# N5h+db8spmIF0qGCAigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0ECEzMAAADraarMPimfLTkAAAAAAOswCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE5MDQwMzExMDY0MVowIwYJKoZIhvcNAQkEMRYEFFiQV7Vq6BR6l6i1Cb95+Dz3
# E21HMA0GCSqGSIb3DQEBBQUABIIBAA7+ktx7UifXsCNd1s++qUveph9qZ6/ELbkS
# uOi2PcwkB3h7xPEhRZb/kPMmfS5r6yIkF98fBWPsfU6YgNCqNqiSglmfgqREWrh5
# P5adjoW3RLyD0saEm38/oa5cF04IMDIXIoxnBgAjtY1LI437a3HWrw//IUKyjrLq
# 2UCkvlZlUf/doo24GsbuOd2zjGzc5J382rK1YkQiHQT2mKxex6PdguoNhNvrYi0Y
# tED4OgV18bBaJqmf/OCc8a8y/z7eFI73/kbYO/vLq+SfJO5lMIuLzyyh8J015wEJ
# PVLQgGD5I/SOPN7DNJOWhrCnTAk2DmCOxUgq2tjjfJn2rQ7zjwU=
# SIG # End signature block
