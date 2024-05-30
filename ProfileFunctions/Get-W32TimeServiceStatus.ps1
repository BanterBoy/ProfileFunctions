function Get-W32TimeServiceStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {
        $service = Invoke-Command -ComputerName $ComputerName -ScriptBlock { Get-Service -Name "w32time" }
    } catch {
        Write-Error "Failed to get service status: $_"
        return
    }

    $outputObject = New-Object PSObject

    $outputObject | Add-Member -NotePropertyName "ComputerName" -NotePropertyValue $ComputerName
    $outputObject | Add-Member -NotePropertyName "ServiceName" -NotePropertyValue $service.Name
    $outputObject | Add-Member -NotePropertyName "ServiceStatus" -NotePropertyValue $service.Status

    return $outputObject
}