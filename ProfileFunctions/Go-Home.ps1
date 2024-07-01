# Store the previous location globally
$global:prevLocation = $null

function Go-Home {
    <#
    .SYNOPSIS
    Changes the current location to the root of the current drive.

    .DESCRIPTION
    The Go-Home function stores the current location in a global variable and then changes the current location to the root of the current drive.

    .EXAMPLE
    Go-Home
    Changes the location to the root of the current drive and stores the previous location.

    .NOTES
    The previous location is stored in a global variable $global:prevLocation.
    #>

    try {
        # Store the current location
        $global:prevLocation = Get-Location

        # Get the current drive
        $currentDrive = (Get-Location).Drive.Name

        # Change to the root of the current drive
        Set-Location "$currentDrive`:\"
    }
    catch {
        Write-Warning "Failed to change location to the root of the drive. Error: $_"
    }
}

function Go-Back {
    <#
    .SYNOPSIS
    Changes the current location back to the previously stored location.

    .DESCRIPTION
    The Go-Back function changes the current location back to the location stored in the global variable $global:prevLocation.

    .EXAMPLE
    Go-Back
    Changes the location back to the previously stored location.

    .NOTES
    The previous location is stored in a global variable $global:prevLocation.
    #>

    try {
        if ($global:prevLocation) {
            # Change to the previous location
            Set-Location $global:prevLocation
        }
        else {
            Write-Warning "No previous location stored."
        }
    }
    catch {
        Write-Warning "Failed to change location back to the previous location. Error: $_"
    }
}
