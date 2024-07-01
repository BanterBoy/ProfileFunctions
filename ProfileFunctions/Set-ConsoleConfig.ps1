function Set-ConsoleConfig {
    <#
    .SYNOPSIS
        Configures the console window and buffer size.

    .DESCRIPTION
        This function configures the console window size (height and width) and buffer size (height).
        The buffer size defaults to 9001 if not specified.

    .PARAMETER WindowHeight
        Specifies the height of the console window.

    .PARAMETER WindowWidth
        Specifies the width of the console window.

    .PARAMETER BufferHeight
        Specifies the height of the console buffer. Defaults to 9001.

    .EXAMPLE
        Set-ConsoleConfig -WindowHeight 40 -WindowWidth 120 -BufferHeight 10000
        Configures the console window to have a height of 40, width of 120, and buffer height of 10000.

    .EXAMPLE
        Set-ConsoleConfig -WindowHeight 30 -WindowWidth 100
        Configures the console window to have a height of 30, width of 100, and buffer height of 9001 (default).

    .NOTES
        Author: Your Name
        Date: 2024-06-30
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Enter the height of the console window.")]
        [int]$WindowHeight,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Enter the width of the console window.")]
        [int]$WindowWidth,

        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Enter the height of the console buffer. Defaults to 9001.")]
        [int]$BufferHeight = 9001
    )

    begin {
        Write-Verbose "Starting to configure the console settings."
    }

    process {
        try {
            Write-Verbose "Setting console window size to Height: $WindowHeight, Width: $WindowWidth"
            [System.Console]::SetWindowSize($WindowWidth, $WindowHeight)
            Write-Verbose "Console window size set successfully."

            Write-Verbose "Setting console buffer size to Width: $WindowWidth, Height: $BufferHeight"
            [System.Console]::SetBufferSize($WindowWidth, $BufferHeight)
            Write-Verbose "Console buffer size set successfully."
        }
        catch {
            Write-Error "Failed to set console configuration. Error: $_"
        }
    }

    end {
        Write-Verbose "Completed configuring the console settings."
    }
}

# Example usage:
# Set-ConsoleConfig -WindowHeight 40 -WindowWidth 120 -BufferHeight 10000
# Set-ConsoleConfig -WindowHeight 30 -WindowWidth 100
