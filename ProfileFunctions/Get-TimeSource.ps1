function Get-TimeSource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    try {
        $w32tmOutput = w32tm /query /computer:$ComputerName /source
        $NtpServer = $w32tmOutput.Trim()
    }
    catch {
        throw "Failed to retrieve time source from $($ComputerName): $_"
    }

    if ([string]::IsNullOrEmpty($ComputerName)) {
        throw "ComputerName parameter cannot be empty or null"
    }
    $w32tmOutput = w32tm /query /computer:$ComputerName /source

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to retrieve time source from $ComputerName"
    }
    $NtpServer = $w32tmOutput.Trim()
    $NtpServer
}