class Greetings {
    # Hashtable to store multiple messages for each day of the week
    [hashtable] $greetings
    # Array of days of the week for validation
    [string[]] $Days
    # Current date
    [datetime] $Date
    # Current day of the week as a string
    [string] $CurrentDay
    # Hashtable to store ASCII mappings for each day
    [hashtable] $asciiMappings

    # Constructor to initialize the hashtable, array, and current date and day
    Greetings() {
        # Load greetings from JSON configuration file
        $jsonFilePath = "$PSScriptRoot\greetings.json"
        $jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json
        $this.greetings = @{}
        foreach ($day in $jsonContent.PSObject.Properties.Name) {
            $this.greetings[$day] = $jsonContent."$day"
        }

        $this.Days = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
        $this.Date = Get-Date
        $this.CurrentDay = $this.Date.DayOfWeek.ToString()

        # Initialize ASCII mappings with dummy data
        $this.asciiMappings = @{
            Monday    = "ASCII Art for Monday"
            Tuesday   = "ASCII Art for Tuesday"
            Wednesday = "ASCII Art for Wednesday"
            Thursday  = "ASCII Art for Thursday"
            Friday    = "ASCII Art for Friday"
            Saturday  = "ASCII Art for Saturday"
            Sunday    = "ASCII Art for Sunday"
        }
    }

    <#
    .SYNOPSIS
    Retrieves a random message for a specified day.

    .DESCRIPTION
    The GetMessageForDay method selects a random message from the predefined list of messages for the given day. 
    It validates the input day and returns a PSCustomObject containing the date, day, time, and message.

    .PARAMETER day
    The day of the week for which to retrieve the message.

    .EXAMPLE
    $greetings = [Greetings]::new()
    $greetings.GetMessageForDay("Monday")
    Retrieves a random message for Monday.

    .NOTES
    Author: [Your Name]
    Date: [Today's Date]
    #>

    [object] GetMessageForDay([string] $day) {
        # Validate the input day
        if (-not $this.Days -contains $day) {
            throw [System.ArgumentException]::new("Invalid day: $day. Valid days are: $($this.Days -join ', ')")
        }

        # Get the current time as a string
        $time = $this.Date.ToShortTimeString()
        # Get the list of messages for the specified day
        $messages = $this.greetings[$day]
        # Shuffle the list of messages for the specified day
        $shuffledMessages = $messages | Sort-Object { Get-Random }
        # Select a random message from the shuffled list
        $message = $shuffledMessages | Select-Object -First 1

        # Create a PSCustomObject with the date, day, time, and message
        $properties = [ordered]@{
            "Date"    = $this.Date.ToShortDateString()
            "Day"     = $day
            "Time"    = $time
            "Message" = $message
        }
        
        return [PSCustomObject]$properties
    }

    <#
    .SYNOPSIS
    Copies a greeting message to the clipboard.

    .DESCRIPTION
    The Process method retrieves a random message for the specified day (if it exists) and copies it to the clipboard.

    .PARAMETER name
    The name of the day for which to copy the message.

    .EXAMPLE
    $greetings = [Greetings]::new()
    $greetings.Process("Monday")
    Copies a random Monday message to the clipboard.

    .NOTES
    Author: [Your Name]
    Date: [Today's Date]
    #>

    [void] Process([string] $name) {
        # Check if the specified name exists in the greetings
        if ($this.greetings.ContainsKey($name)) {
            # Check if ASCII mapping exists
            if ($this.asciiMappings.ContainsKey($name)) {
                # Get a random message and copy it to the clipboard
                Write-Host ($this.asciiMappings[$name] | Set-Clipboard -PassThru)
            }
            else {
                Write-Error "ASCII mapping not found for $name."
            }
        }
        else {
            Write-Error "Name not found in greetings."
        }
    }
}

<#
.SYNOPSIS
Provides valid day names for the Greetings class.

.DESCRIPTION
The GreetingsValidator class implements the IValidateSetValuesGenerator interface to provide valid day names for the Greetings class.

.NOTES
Author: [Your Name]
Date: [Today's Date]
#>
class GreetingsValidator : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        return [Greetings]::new().Days
    }
}


function New-Greeting {
    <#
    .SYNOPSIS
    Creates a greeting message for a specified day.

    .DESCRIPTION
    The New-Greeting function generates a greeting message for a specified day of the week using the `Greetings` class. If no day is specified, it defaults to the current day. The greeting message is returned as a `PSCustomObject` containing the date, day, time, and message.

    .PARAMETER Day
    The day of the week for which the greeting message should be created. If not specified, the current day is used. The valid values for this parameter are defined by the `GreetingsValidator` class.

    .EXAMPLE
    # Example 1: Get a greeting message for Monday
    PS C:\> New-Greeting -Day Monday

    Date       Day     Time  Message
    ----       ---     ----  -------
    30/06/2024 Monday 14:00 Booting up for the week, please wait...

    .EXAMPLE
    # Example 2: Get a greeting message for the current day
    PS C:\> New-Greeting

    Date       Day     Time  Message
    ----       ---     ----  -------
    30/06/2024 Sunday 14:00 Backing up for the week ahead.

    .NOTES
    Author: Your Name
    Date: Today's Date
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([string])]
    Param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the day for which the greeting message should be created.'
        )]
        [ValidateSet([GreetingsValidator])]
        [string]$Day
    )

    Begin {
        # Create a new instance of the Greetings class
        $greetings = [Greetings]::new()

        # If no day is specified, use the current day
        if ([String]::IsNullOrWhiteSpace($Day)) {
            $Day = $greetings.CurrentDay
        }
    }

    Process {
        # Get the greeting message for the specified day
        Write-Output $($greetings.GetMessageForDay($Day))
    }
}

