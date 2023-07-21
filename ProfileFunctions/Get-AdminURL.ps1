<#
Service,Site,Server,URL
Lidarr,63Archer,kamino-vm,"http://kamino-vm.domain.leigh-services.com:8686/"
Lidarr,51Peel,Geonosis,"http://geonosis.domain.leigh-services.com:8686/"
Readarr,63Archer,kamino-vm,"http://kamino-vm.domain.leigh-services.com:8787/"
Readarr,51Peel,Geonosis,"http://geonosis.domain.leigh-services.com:8787/"
Sonarr,63Archer,kamino-vm,"http://kamino-vm.domain.leigh-services.com:8989/"
Sonarr,51Peel,Geonosis,"http://geonosis.domain.leigh-services.com:8989/"
Radarr,63Archer,kamino-vm,"http://kamino-vm.domain.leigh-services.com:7878/"
Radarr,51Peel,Geonosis,"http://geonosis.domain.leigh-services.com:7878/"
Prowlarr,63Archer,kamino-vm,"http://kamino-vm.domain.leigh-services.com:9696/"
Prowlarr,51Peel,Geonosis,"http://geonosis.domain.leigh-services.com:9696/"
Transmission,63Archer,deathstar,"http://deathstar.domain.leigh-services.com:49092/transmission/web/"
Transmission,51Peel,Geonosis,"http://kevs-qnap-663.domain.leigh-services.com:49092/transmission/web/"
MulvadVPN,Admin,External,"https://mullvad.net/en/account/#/login?next=/"
"Windows Admin Center",63Archer,deathstar,"https://darthvader.domain.leigh-services.com:6516/"
"Jira Workspaces",Admin,External,"https://leigh-services.atlassian.net/jira/your-work"
"Jira Service Desk",Admin,External,"https://leigh-services.atlassian.net/jira/projects?selectedProjectType=service_desk"
"Jira Admin",Admin,External,"https://admin.atlassian.com/"
"Ubiquiti Dream Machine",63Archer,DreamMachine,"https://holonet.domain.leigh-services.com/"
"Ubiquiti Dream Machine",51Peel,DreamMachine,"https://hyperchannel.domain.leigh-services.com/"
QNAP NAS,63Archer,deathstar,"https://deathstar.domain.leigh-services.com/cgi-bin/"
QNAP NAS,63Archer,ds-1,"https://ds-1.domain.leigh-services.com/cgi-bin/"
QNAP NAS,51Peel,kevs-qnap-663,"https://kevs-qnap-663.domain.leigh-services.com/cgi-bin/"
QNAP NAS,51Peel,kevs-qnap-412,"https://kevs-qnap-412.domain.leigh-services.com/cgi-bin/"
"JellyFin Server",63Archer,Hoth,"http://hoth.domain.leigh-services.com:8096"
"JellyFin Server",51Peel,Discovery,"http://discovery.domain.leigh-services.com:8096"
"Printer WebAdmin",63Archer,Printer,"http://10.10.0.44/#hId-networkSumPage"
"Printer WebAdmin",51Peel,Printer,"http://10.20.0.53/SSI/index.htm"
"Internal Blog",63Archer,deathstar,"http://deathstar.domain.leigh-services.com:8080/"
"Internal Blog Admin Dashboard",63Archer,deathstar,"http://deathstar.domain.leigh-services.com:8080/admin/dashboard"
"Virtualisation Station",63Archer,deathstar,"https://deathstar.domain.leigh-services.com/qvs/#/console/vms/1?quality=high"
"Virtualisation Station",51Peel,Lahmu,"https://kevs-qnap-663.domain.leigh-services.com/qvs/#/console/vms/3"
"Microsoft Admin Sites",Admin,External,"https://entra.microsoft.com"
"Microsoft Admin Sites",Admin,External,"https://admin.microsoft.com"
"AdminDroid Reporter",63Archer,darthvader,"http://darthvader.domain.leigh-services.com:8000"
"Microsoft Connectivity Test",Admin,External,"https://connectivity.office.com/"
"Azure Portal",Admin,External,"https://portal.azure.com/"
#>

# Create new powershell function to list individual services running on each server
# The function should provide the ability to open the url in a browser
# The following example should only return the relevant url for the service
# Get-AdminURL -Service Transmission -Site 51Peel
# Get-AdminURL -Service Transmission -Site 51Peel -Open
# Get-AdminURL -Service Transmission -Site 51Peel -Server Geonosis -Open
function Get-AdminURL {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Lidarr', 'Readarr', 'Sonarr', 'Radarr', 'Prowlarr', 'Transmission', 'MulvadVPN', 'Windows Admin Center', 'Jira Workspaces', 'Jira Service Desk', 'Jira Admin', 'Ubiquiti Dream Machine', 'QNAP NAS', 'JellyFin Server', 'Printer WebAdmin', 'Internal Blog', 'Internal Blog Admin Dashboard', 'Virtualisation Station', 'Microsoft Admin Sites', 'AdminDroid Reporter', 'Microsoft Connectivity Test', 'Azure Portal')]
        [string]$Service,
        # Add a parameter to select the site
        [Parameter(Mandatory = $false)]
        [ValidateSet('63Archer', '51Peel', 'Admin')]
        [string]$Site,
        # Add a parameter to select the server
        [Parameter(Mandatory = $false)]
        [ValidateSet('kamino-vm', 'Geonosis', 'deathstar', 'DreamMachine', 'ds-1', 'kevs-qnap-663', 'kevs-qnap-412', 'Hoth', 'Discovery', 'Printer')]
        [string]$Server,
        # Add a switch to open the url in a browser
        [switch]$Open
        
    )
    $AdminURLs = Import-Csv -Path $PSScriptRoot\AdminURLs.csv
    $AdminURLs | Where-Object { $_.Service -eq $Service -and $_.Site -eq $Site -and $_.Server -eq $Server } | Select-Object -ExpandProperty URL
    if ($Open) {
        $AdminURLs | Where-Object { $_.Service -eq $Service -and $_.Site -eq $Site -and $_.Server -eq $Server } | Select-Object -ExpandProperty URL | ForEach-Object { Start-Process $_ }
    }
}