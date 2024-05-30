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
