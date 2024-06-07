function Get-TimeSource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    if ([string]::IsNullOrEmpty($ComputerName)) {
        throw "ComputerName parameter cannot be empty or null"
    }

    try {
        $w32tmOutput = w32tm /query /computer:$ComputerName /source 2>&1
        if ($LASTEXITCODE -ne 0) {
            $errorMessage = "Failed to retrieve time source from $($ComputerName): $w32tmOutput"
            Write-Warning $errorMessage
            return $null
        }
        $NtpServer = $w32tmOutput.Trim()
    }
    catch {
        Write-Warning "Failed to retrieve time source from $($ComputerName): $_"
        return $null
    }

    # Create a custom PSObject to return
    $output = New-Object PSObject
    $output | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
    $output | Add-Member -MemberType NoteProperty -Name "TimeSource" -Value $NtpServer

    return $output
}

# Example usage
# Get-TimeSource -ComputerName $env:COMPUTERNAME