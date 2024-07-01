function Set-ConsoleConfig {
    <#
    .SYNOPSIS
        Configures the console window and buffer size.

    .DESCRIPTION
        This function configures the console window size (height and width) and buffer size (height and width).
        The buffer height defaults to 9001 and the buffer width defaults to the window width if not specified.

    .PARAMETER WindowHeight
        Specifies the height of the console window.

    .PARAMETER WindowWidth
        Specifies the width of the console window.

    .PARAMETER BufferHeight
        Specifies the height of the console buffer. Defaults to 9001.

    .PARAMETER BufferWidth
        Specifies the width of the console buffer. Defaults to the window width.

    .EXAMPLE
        Set-ConsoleConfig -WindowHeight 40 -WindowWidth 120 -BufferHeight 10000 -BufferWidth 120
        Configures the console window to have a height of 40, width of 120, buffer height of 10000, and buffer width of 120.

    .EXAMPLE
        Set-ConsoleConfig -WindowHeight 30 -WindowWidth 100
        Configures the console window to have a height of 30, width of 100, buffer height of 9001, and buffer width of 100.

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
        [int]$BufferHeight = 9001,

        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Enter the width of the console buffer. Defaults to the window width.")]
        [int]$BufferWidth
    )

    begin {
        Write-Verbose "Starting to configure the console settings."

        # Set the default buffer width to the window width if not specified
        if (-not $PSBoundParameters.ContainsKey('BufferWidth')) {
            $BufferWidth = $WindowWidth
        }
    }

    process {
        try {
            Write-Verbose "Setting console window size to Height: $WindowHeight, Width: $WindowWidth"
            [System.Console]::SetWindowSize($WindowWidth, $WindowHeight)
            Write-Verbose "Console window size set successfully."

            Write-Verbose "Setting console buffer size to Width: $BufferWidth, Height: $BufferHeight"
            [System.Console]::SetBufferSize($BufferWidth, $BufferHeight)
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
# Set-ConsoleConfig -WindowHeight 40 -WindowWidth 120 -BufferHeight 10000 -BufferWidth 120
# Set-ConsoleConfig -WindowHeight 30 -WindowWidth 100
