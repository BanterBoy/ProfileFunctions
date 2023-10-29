function Set-ConsoleConfig {
    <#
    .SYNOPSIS
    Sets the height and width of the console window and buffer.
    
    .DESCRIPTION
    The Set-ConsoleConfig function sets the height and width of the console window and buffer. If no parameters are specified, the function sets the window height and width to the current console size.
    
    .PARAMETER WindowHeight
    The height of the console window.
    
    .PARAMETER WindowWidth
    The width of the console window.
    
    .EXAMPLE
    Set-ConsoleConfig -WindowHeight 50 -WindowWidth 120
    Sets the console window height to 50 and width to 120.
    
    .NOTES
    Author: Unknown
    Date: Unknown
    #>
    param (
        [int]$WindowHeight = [System.Console]::WindowHeight,
        [int]$WindowWidth = [System.Console]::WindowWidth
    )

    if ($WindowHeight -lt 10 -or $WindowHeight -gt [System.Console]::LargestWindowHeight) {
        Write-Error "Error: WindowHeight must be between 10 and $([System.Console]::LargestWindowHeight)"
        return
    }

    if ($WindowWidth -lt 20 -or $WindowWidth -gt [System.Console]::LargestWindowWidth) {
        Write-Error "Error: WindowWidth must be between 20 and $([System.Console]::LargestWindowWidth)"
        return
    }

    try {
        [System.Console]::SetWindowSize($WindowWidth, $WindowHeight)
        [System.Console]::BufferWidth = $WindowWidth
    }
    catch {
        Write-Error "Failed to set console window size: $_"
    }
}