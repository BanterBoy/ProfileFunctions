function Get-LogonEvents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )
    $events = Get-WinEvent -ComputerName $ComputerName -FilterHashtable @{LogName = 'Security'; ID = 4624 } -ErrorAction SilentlyContinue
    if ($events) {
        foreach ($event in $events) {
            $event | Select-Object -Property TimeCreated, @{Name = 'User'; Expression = { $_.Properties[5].Value } }
        }
    }
    else {
        Write-Warning -Message "No logon events found on $ComputerName"
    }
}
