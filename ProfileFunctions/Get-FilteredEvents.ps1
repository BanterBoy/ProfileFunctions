# Get-WinEvent -ComputerName AZURECON19 -MaxEvents 100 |
# Where-Object { 'System' -In ($_ | Select-Object -ExpandProperty Loglinks | Select-Object -ExpandProperty Logname) } |
# Where-Object -FilterScript { $_.Message -like '*836*' }

# Get-WinEvent -FilterHashTable @{'LogName' = 'Application'; 'StartTime' = (Get-Date -Hour 0 -Minute 0 -Second 0)} | Select-Object TimeCreated, ID, ProviderName, LevelDisplayName, Message | Format-Table -AutoSize


# Path: Profile\Functions\Get-FilteredEvents.ps1
# Get-WinEvent -FilterHashTable @{'LogName' = $LogName; 'StartTime' = $StartTime} | Select-Object TimeCreated, ID, ProviderName, LevelDisplayName, Message
# function Get-FilteredEvents {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [ValidateNotNullOrEmpty()]
#         [string]$ComputerName,

#         [Parameter(Mandatory = $true)]
#         [ValidateNotNullOrEmpty()]
#         [string]$LogName,

#         [Parameter(Mandatory = $false)]
#         [ValidateNotNullOrEmpty()]
#         [datetime]$StartTime = (Get-Date -Hour 0 -Minute 0 -Second 0),

#         [Parameter(Mandatory = $false)]
#         [ValidateNotNullOrEmpty()]
#         [datetime]$EndTime = (Get-Date -Hour 23 -Minute 59 -Second 59),

#         [Parameter(Mandatory = $false)]
#         [ValidateNotNullOrEmpty()]
#         [string]$ID
#     )

#     try {
#         $FilterHashTable = @{'LogName' = $LogName; 'StartTime' = $StartTime; 'EndTime' = $EndTime }
#         if ($ID) {
#             $FilterHashTable.Add('ID', $ID)
#         }
#         Get-WinEvent -FilterHashTable $FilterHashTable | Select-Object TimeCreated, ID, ProviderName, LevelDisplayName, Message
#     }
#     catch {
#         Write-Output "No events were found that match the specified selection criteria."
#     }

# }
function Get-FilteredEvents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [datetime]$StartTime = (Get-Date -Hour 0 -Minute 0 -Second 0),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [datetime]$EndTime = (Get-Date -Hour 23 -Minute 59 -Second 59),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ID
    )

    try {
        $FilterHashTable = @{'LogName' = $LogName; 'StartTime' = $StartTime; 'EndTime' = $EndTime }
        if ($ID) {
            $FilterHashTable.Add('ID', $ID)
        }
        $events = Get-WinEvent -FilterHashTable $FilterHashTable -ErrorAction Stop | Select-Object TimeCreated, ID, ProviderName, LevelDisplayName, Message
        if ($events) {
            return $events
        }
        else {
            throw "No events were found that match the specified selection criteria."
        }
    }
    catch {
        Write-Output $_.Exception.Message
    }
}