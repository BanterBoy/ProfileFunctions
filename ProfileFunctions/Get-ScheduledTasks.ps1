<#
.SYNOPSIS
Retrieves scheduled tasks from one or more servers.

.DESCRIPTION
The Get-ScheduledTasks function retrieves scheduled tasks from one or more servers. It uses the ScheduledTasks module to interact with the Task Scheduler service on the specified servers. The function supports filtering tasks based on their state (Ready, Disabled, Running).

.PARAMETER Servers
Specifies the servers from which to retrieve scheduled tasks. By default, the function retrieves tasks from the local computer.

.PARAMETER State
Specifies the state of the tasks to retrieve. The valid values are "Ready", "Disabled", and "Running". By default, all tasks are retrieved regardless of their state.

.EXAMPLE
Get-ScheduledTasks -Servers "Server1", "Server2" -State "Ready"
Retrieves all scheduled tasks in the "Ready" state from Server1 and Server2.

.EXAMPLE
Get-ScheduledTasks -Servers "Server1" -State "Disabled"
Retrieves all scheduled tasks in the "Disabled" state from Server1.

.NOTES
- This function requires the ScheduledTasks module to be installed. If the module is not installed, an error message is displayed.
- The function uses Test-Connection cmdlet to check the connectivity to each server before retrieving tasks.
- The function returns a custom object with the following properties: Server, Name, RunAsUser, State, TaskName, Author.
#>
function Get-ScheduledTasks {
    [CmdletBinding()]        
   
    # Parameters used in this function
    param
    (
        [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Provide server names", ValueFromPipeline = $true)] 
        $Servers = $env:COMPUTERNAME,
   
        [Parameter(Position = 1, Mandatory = $false, HelpMessage = "Select task state (Ready, Disabled, Running)", ValueFromPipeline = $true)][ValidateSet("Ready", "Disabled", "Running")][string]
        $State = $null
    ) 
  
    # Error action set to Stop
    $ErrorActionPreference = "Stop"
  
    # Checking module
    Try {
        Import-Module ScheduledTasks
    }
    Catch {
        $_.Exception.Message
        Write-Warning "Scheduled Tasks module not installed"
        Break
    }
          
    # Looping each server
    ForEach ($Server in $Servers) {
        Write-Output "Processing $Server" 
      
        # Testing connection
        If (!(Test-Connection -ComputerName $Server -BufferSize 16 -Count 1 -ErrorAction 0 -Quiet)) {
            Write-Warning   "Failed to connect to $Server"
        }
        Else {
            $TasksArray = @()
  
            Try {
                $Tasks = Get-ScheduledTask -CimSession $Server | Where-Object { $_.state -match "$State" }
            }
            Catch {
                $_.Exception.Message
                Continue
            }
 
            If ($Tasks) {
                # Loop through the servers
                $Tasks | ForEach-Object {
                    # Define current loop to variable
                    $Task = $_
  
                    # Creating a custom object 
                    $Object = New-Object PSObject -Property @{
                        Server    = $Server.name
                        Name      = $task.Name
                        RunAsUser = $taskinfo.Task.Principals.Principal.UserId
                        State     = $task.State
                        TaskName  = $task.TaskName
                        Author    = $task.Author
                    }  
  
                    # Add custom object to our array
                    $TasksArray += $Object
                }
  
                # Display results in console
                $TasksArray 
            }
            Else {
                Write-Warning "Tasks not found"
            }
        }
    }   
}
