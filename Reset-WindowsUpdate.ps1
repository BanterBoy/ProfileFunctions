<#
.SYNOPSIS
This function resets the Windows Update components.

.DESCRIPTION
The Reset-WindowsUpdate function stops the Windows Update services, removes the QMGR data file, renames the SoftwareDistribution and CatRoot folders, removes the old Windows Update log, resets the Windows Update services to default settings, registers some DLLs, removes WSUS client settings, resets the WinSock, deletes all BITS jobs, attempts to install the Windows Update Agent, starts the Windows Update services, and forces Windows Update to check for updates.

.PARAMETER StopServices
Stops the Windows Update services.

.PARAMETER RemoveQMGR
Removes the QMGR data file.

.PARAMETER RenameFolders
Renames the SoftwareDistribution and CatRoot folders.

.PARAMETER RemoveLog
Removes the old Windows Update log.

.PARAMETER ResetServices
Resets the Windows Update services to default settings.

.PARAMETER RegisterDLLs
Registers some DLLs.

.PARAMETER RemoveWSUS
Removes WSUS client settings.

.PARAMETER ResetWinSock
Resets the WinSock.

.PARAMETER DeleteBITS
Deletes all BITS jobs.

.PARAMETER InstallAgent
Attempts to install the Windows Update Agent.

.PARAMETER StartServices
Starts the Windows Update services.

.PARAMETER ForceDiscovery
Forces Windows Update to check for updates.

.PARAMETER RunAll
Performs all the operations.

.EXAMPLE
Reset-WindowsUpdate -Verbose

This command performs all the operations and displays verbose output for each step.

.EXAMPLE
Reset-WindowsUpdate -StopServices -Verbose

This command stops the Windows Update services and displays verbose output.

.EXAMPLE
Reset-WindowsUpdate -RemoveQMGR -RenameFolders -Verbose

This command removes the QMGR data file, renames the SoftwareDistribution and CatRoot folders, and displays verbose output.

.EXAMPLE
Reset-WindowsUpdate -ResetServices -RegisterDLLs -RemoveWSUS -Verbose

This command resets the Windows Update services to default settings, registers some DLLs, removes WSUS client settings, and displays verbose output.

.EXAMPLE
Reset-WindowsUpdate -ResetWinSock -DeleteBITS -InstallAgent -StartServices -ForceDiscovery -Verbose

This command resets the WinSock, deletes all BITS jobs, attempts to install the Windows Update Agent, starts the Windows Update services, forces Windows Update to check for updates, and displays verbose output.

#>

function Reset-WindowsUpdate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(ValueFromPipeline = $true, HelpMessage = "Stops the Windows Update services.")]
        [switch]$StopServices,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Removes the QMGR data file.")]
        [switch]$RemoveQMGR,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Renames the SoftwareDistribution and CatRoot folders.")]
        [switch]$RenameFolders,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Removes the old Windows Update log.")]
        [switch]$RemoveLog,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Resets the Windows Update services to default settings.")]
        [switch]$ResetServices,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Registers some DLLs.")]
        [switch]$RegisterDLLs,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Removes WSUS client settings.")]
        [switch]$RemoveWSUS,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Resets the WinSock.")]
        [switch]$ResetWinSock,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Deletes all BITS jobs.")]
        [switch]$DeleteBITS,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Attempts to install the Windows Update Agent.")]
        [switch]$InstallAgent,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Starts the Windows Update services.")]
        [switch]$StartServices,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Forces Windows Update to check for updates.")]
        [switch]$ForceDiscovery,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Performs all the operations.")]
        [switch]$RunAll
    )

    # If no operation switches are selected, set $RunAll to $true
    if (-not ($StopServices -or $RemoveQMGR -or $RenameFolders -or $RemoveLog -or $ResetServices -or $RegisterDLLs -or $RemoveWSUS -or $ResetWinSock -or $DeleteBITS -or $InstallAgent -or $StartServices -or $ForceDiscovery -or $RunAll)) {
        $RunAll = $true
    }

    if ($RunAll) {
        $StopServices = $true
        $RemoveQMGR = $true
        $RenameFolders = $true
        $RemoveLog = $true
        $ResetServices = $true
        $RegisterDLLs = $true
        $RemoveWSUS = $true
        $ResetWinSock = $true
        $DeleteBITS = $true
        $InstallAgent = $true
        $StartServices = $true
        $ForceDiscovery = $true
    }

    $arch = Get-WMIObject -Class Win32_Processor -ComputerName LocalHost | Select-Object AddressWidth

    if ($PSCmdlet.ShouldProcess("Windows Update", "Reset")) {
        try {
            if ($StopServices) {
                Write-Verbose "1. Stopping Windows Update Services..." -Verbose
                Stop-Service -Name BITS -ErrorAction Stop
                Stop-Service -Name wuauserv -ErrorAction Stop
                Stop-Service -Name appidsvc -ErrorAction Stop
                Stop-Service -Name cryptsvc -ErrorAction Stop
            }

            if ($RemoveQMGR) {
                Write-Verbose "2. Remove QMGR Data file..." -Verbose
                Remove-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction Stop
            }

            if ($RenameFolders) {
                Write-Verbose "3. Renaming the Software Distribution and CatRoot Folder..." -Verbose
                if (Test-Path $env:systemroot\SoftwareDistribution.bak) {
                    Remove-Item $env:systemroot\SoftwareDistribution.bak -Recurse -Force -ErrorAction Stop
                }
                Rename-Item $env:systemroot\SoftwareDistribution SoftwareDistribution.bak -ErrorAction Stop

                if (Test-Path $env:systemroot\System32\catroot2.bak) {
                    Remove-Item $env:systemroot\System32\catroot2.bak -Recurse -Force -ErrorAction Stop
                }
                Rename-Item $env:systemroot\System32\Catroot2 catroot2.bak -ErrorAction Stop
            }

            if ($RemoveLog) {
                Write-Verbose "4. Removing old Windows Update log..." -Verbose
                Remove-Item $env:systemroot\WindowsUpdate.log -ErrorAction Stop
            }

            if ($ResetServices) {
                Write-Verbose "5. Resetting the Windows Update Services to defualt settings..." -Verbose
                "sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
                "sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
            }

            if ($RegisterDLLs) {
                Write-Verbose "6. Registering some DLLs..." -Verbose
                regsvr32.exe /s atl.dll 
                regsvr32.exe /s urlmon.dll 
                regsvr32.exe /s mshtml.dll 
                regsvr32.exe /s shdocvw.dll 
                regsvr32.exe /s browseui.dll 
                regsvr32.exe /s jscript.dll 
                regsvr32.exe /s vbscript.dll 
                regsvr32.exe /s scrrun.dll 
                regsvr32.exe /s msxml.dll 
                regsvr32.exe /s msxml3.dll 
                regsvr32.exe /s msxml6.dll 
                regsvr32.exe /s actxprxy.dll 
                regsvr32.exe /s softpub.dll 
                regsvr32.exe /s wintrust.dll 
                regsvr32.exe /s dssenh.dll 
                regsvr32.exe /s rsaenh.dll 
                regsvr32.exe /s gpkcsp.dll 
                regsvr32.exe /s sccbase.dll 
                regsvr32.exe /s slbcsp.dll 
                regsvr32.exe /s cryptdlg.dll 
                regsvr32.exe /s oleaut32.dll 
                regsvr32.exe /s ole32.dll 
                regsvr32.exe /s shell32.dll 
                regsvr32.exe /s initpki.dll 
                regsvr32.exe /s wuapi.dll 
                regsvr32.exe /s wuaueng.dll 
                regsvr32.exe /s wuaueng1.dll 
                regsvr32.exe /s wucltui.dll 
                regsvr32.exe /s wups.dll 
                regsvr32.exe /s wups2.dll 
                regsvr32.exe /s wuweb.dll 
                regsvr32.exe /s qmgr.dll 
                regsvr32.exe /s qmgrprxy.dll 
                regsvr32.exe /s wucltux.dll 
                regsvr32.exe /s muweb.dll 
                regsvr32.exe /s wuwebv.dll 

            }

            if ($RemoveWSUS) {
                Write-Verbose "7) Removing WSUS client settings..." -Verbose
                REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v AccountDomainSid /f 
                REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v PingID /f 
                REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v SusClientId /f 

            }

            if ($ResetWinSock) {
                Write-Verbose "8) Resetting the WinSock..." -Verbose
                netsh winsock reset
                netsh winhttp reset proxy

            }

            if ($DeleteBITS) {
                Write-Verbose "9) Delete all BITS jobs..." -Verbose
                Get-BitsTransfer | Remove-BitsTransfer

            }

            if ($InstallAgent) {
                Write-Verbose "10) Attempting to install the Windows Update Agent..." -Verbose
                if ($arch -eq 64) {
                    wusa Windows8-RT-KB2937636-x64 /quiet
                }
                else {
                    wusa Windows8-RT-KB2937636-x86 /quiet
                }

            }

            if ($StartServices) {
                Write-Verbose "11) Starting Windows Update Services..." -Verbose
                Start-Service -Name BITS -ErrorAction Stop
                Start-Service -Name wuauserv -ErrorAction Stop
                Start-Service -Name appidsvc -ErrorAction Stop
                Start-Service -Name cryptsvc -ErrorAction Stop

            }

            if ($ForceDiscovery) {
                Write-Verbose "12) Forcing Windows Update to check for updates..." -Verbose
                wuauclt /resetauthorization /detectnow

            }

            Write-Verbose "Process complete. Please reboot your computer." -Verbose
        }
        catch {
            Write-Error "An error occurred: $_"
        }
    }
}
