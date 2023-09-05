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
