function Get-AdminUrls {

    <#
    .SYNOPSIS
        Retrieves URLs for various admin sites and services.
    .DESCRIPTION
        This function retrieves URLs for various admin sites and services, such as Lidarr, Sonarr, Radarr, and more. It can filter URLs based on the service, site, and server.
    .PARAMETER Service
        Specifies the service for which to retrieve URLs. Valid values are Lidarr, Readarr, Sonarr, Radarr, Prowlarr, Transmission, MulvadVPN, Windows Admin Center, Jira Workspaces, Jira Service Desk, Jira Admin, Ubiquiti Dream Machine, QNAP NAS, JellyFin Server, Printer WebAdmin, Internal Blog, Internal Blog Admin Dashboard, Virtualisation Station, Microsoft Admin Sites, AdminDroid Reporter, Microsoft Connectivity Test, and Azure Portal.
    .PARAMETER Site
        Specifies the site for which to retrieve URLs. Valid values are 63Archer, 51Peel, and Admin.
    .PARAMETER Server
        Specifies the server for which to retrieve URLs. Valid values are kamino-vm, Geonosis, deathstar, DreamMachine, ds-1, kevs-qnap-663, kevs-qnap-412, Hoth, Discovery, and Printer.
    .PARAMETER Open
        If specified, opens the retrieved URL in the default web browser.
    .EXAMPLE
        PS C:\> Get-AdminUrls -Service Sonarr -Site Admin -Open
        Retrieves the URL for the Sonarr admin site on the Admin site and opens it in the default web browser.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('AdminDroid Reporter', 'Azure Portal', 'Exchange Online', 'Internal Blog', 'Internal Blog Admin Dashboard', 'JellyFin Server', 'Jira Admin', 'Jira Service Desk', 'Jira Workspaces', 'Lidarr', 'Microsoft 365 Admin', 'Microsoft Connectivity Test', 'Microsoft Entra', 'MulvadVPN', 'Printer WebAdmin', 'Prowlarr', 'QNAP NAS', 'Radarr', 'Readarr', 'Sonarr', 'Transmission', 'Ubiquiti Dream Machine', 'Virtualisation Station', 'Windows Admin Center')]
        [string]$Service,
        # Add a parameter to select the site
        [Parameter(Mandatory = $false)]
        [ValidateSet('63Archer', '51Peel', 'Admin')]
        [string]$Site,
        # Add a parameter to select the server
        [Parameter(Mandatory = $false)]
        [ValidateSet('kamino-vm', 'Geonosis', 'deathstar', 'DreamMachine', 'ds-1', 'kevs-qnap-663', 'kevs-qnap-412', 'Hoth', 'Discovery', 'Printer')]
        [string]$Server,
        [Parameter(Mandatory = $false)]
        [switch]$Open

    )

    # Import the CSV file
    $urls = Import-Csv -Path $PSScriptRoot\AdminURLs.csv

    # Query the table for specific information based on the table headings
    $filteredUrls = $urls
    if ($Service) {
        $filteredUrls = $filteredUrls | Where-Object { $_.Service -eq $Service }
    }
    if ($Site) {
        $filteredUrls = $filteredUrls | Where-Object { $_.Site -eq $Site }
    }
    if ($Server) {
        $filteredUrls = $filteredUrls | Where-Object { $_.Server -eq $Server }
    }
    if ($Open) {
        Start-Process -FilePath $filteredUrls.URL
    }
    # Return the filtered URLs
    return $filteredUrls
}
