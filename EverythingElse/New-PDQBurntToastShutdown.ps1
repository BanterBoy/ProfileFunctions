[CmdletBinding()]
param(
    $Days = 7
)


$ModuleName = 'BurntToast'


# Check the uptime
$cim = Get-CimInstance win32_operatingsystem
$uptime = (Get-Date) - ($cim.LastBootUpTime)
$uptimeDays = $Uptime.Days


# return code 0 if this computer hasn't been online for too long
if ($uptimeDays -LT $Days) {
    Write-Verbose "Uptime is $uptimeDays days. Script will not proceed" -Verbose
    Exit 0
}


# Install the module if it is not already installed, then load it.
Try {
    $null = Get-InstalledModule $ModuleName -ErrorAction Stop
}
Catch {
    if ( -not ( Get-PackageProvider -ListAvailable | Where-Object Name -eq "Nuget" ) ) {
        $null = Install-PackageProvider "Nuget" -Force
    }
    $null = Install-Module $ModuleName -Force
}
$null = Import-Module $ModuleName -Force


Write-Verbose "Displaying Toast" -Verbose
New-BurntToastNotification -Text "This computer hasn't been reboot in $uptimeDays days. Please reboot when possible." -SnoozeAndDismiss
