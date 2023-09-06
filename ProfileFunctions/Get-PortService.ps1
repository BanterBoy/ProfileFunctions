<#
.SYNOPSIS
    Gets port service information based on a query.

.DESCRIPTION
    The Get-PortService function retrieves port service information based on a query. The query can be matched against the service name, port number, or description. The function reads the port service data from a JSON file and returns an array of PortService objects.

.PARAMETER Query
    The query to search for. This can be a service name, port number, or description.

.PARAMETER SearchField
    The field to search for the query. This can be 'PortNumber', 'ServiceName', or 'Description'. The default value is 'ServiceName'.

.PARAMETER SearchAllFields
    If specified, the query will be matched against all fields (ServiceName, PortNumber, and Description).

.OUTPUTS
    An array of PortService objects.

.EXAMPLE
    Get-PortService -Query 'http' -SearchField 'Description'
    Returns an array of PortService objects where the description contains 'http'.

.EXAMPLE
    Get-PortService -Query '80' -SearchField 'PortNumber'
    Returns an array of PortService objects where the port number is '80'.

.EXAMPLE
    Get-PortService -Query 'ftp' -SearchAllFields
    Returns an array of PortService objects where the query is matched against all fields.

.NOTES
    Author: GitHub Copilot
#>

class PortService {
    [string]$ServiceName
    [string]$PortNumber
    [string]$Description
    [string]$Reference

    PortService([string]$ServiceName, [string]$PortNumber, [string]$Description, [string]$Reference) {
        $this.ServiceName = $ServiceName
        $this.PortNumber = $PortNumber
        $this.Description = $Description
        $this.Reference = $Reference
    }

    [bool] MatchPortNumber([string]$PortNumber) {
        if ($this.PortNumber -eq $PortNumber) {
            return $true
        }
        return $false
    }

    [bool] MatchServiceName([string]$ServiceName) {
        if ($this.ServiceName -eq $ServiceName) {
            return $true
        }
        return $false
    }

    [bool] MatchDescription($query) {
        if ($this.Description -like "*$query*") {
            return $true
        }
        return $false
    }

    [string] ToString() {
        return "ServiceName: $($this.ServiceName), PortNumber: $($this.PortNumber), Description: $($this.Description), Reference: $($this.Reference)"
    }
}

function Get-PortService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query,
        [Parameter()]
        [ValidateSet('PortNumber', 'ServiceName', 'Description')]
        [string]$SearchField = 'ServiceName',
        [Parameter()]
        [switch]$SearchAllFields
    )

    $portServiceData = Get-Content -Raw -Path $PSScriptRoot\port_service_data.json | ConvertFrom-Json
    $portServices = @()

    foreach ($entry in $portServiceData) {
        $portService = [PortService]::new($entry.ServiceName, $entry.PortNumber, $entry.Description, $entry.Reference)

        if ($SearchAllFields) {
            if ($portService.MatchPortNumber($Query) -or $portService.MatchServiceName($Query) -or $portService.MatchDescription($Query)) {
                $portServices += $portService
            }
        }
        else {
            switch ($SearchField) {
                'PortNumber' {
                    if ($portService.MatchPortNumber($Query)) {
                        $portServices += $portService
                    }
                }
                'ServiceName' {
                    if ($portService.MatchServiceName($Query)) {
                        $portServices += $portService
                    }
                }
                'Description' {
                    if ($portService.MatchDescription($Query)) {
                        $portServices += $portService
                    }
                }
            }
        }
    }

    return $portServices
}
