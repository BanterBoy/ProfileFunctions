class PortServiceName {
  [string]$ServiceName
  [string]$PortNumber
  [string]$Description
  [string]$Reference

  PortServiceName([string]$ServiceName, [string]$PortNumber, [string]$Description, [string]$Reference) {
    $this.ServiceName = $ServiceName
    $this.PortNumber = $PortNumber
    $this.Description = $Description
    $this.Reference = $Reference
  }

  [bool] MatchPortNumber([string]$PortNumber) {
    return ($this.PortNumber -eq $PortNumber)
  }

  [bool] MatchServiceName([string]$ServiceName) {
    return ($this.ServiceName -like $ServiceName)
  }

  [string] ToString() {
    return "ServiceName: $($this.ServiceName), PortNumber: $($this.PortNumber), Description: $($this.Description), Reference: $($this.Reference)"
  }
}

function Get-PortServiceName {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Query
  )

  $PortServiceNameData = Get-Content -Raw -Path "$PSScriptRoot\port_service_data.json" | ConvertFrom-Json
  $PortServiceNames = @()

  foreach ($entry in $PortServiceNameData) {
    $PortServiceName = [PortServiceName]::new($entry.ServiceName, $entry.PortNumber, $entry.Description, $entry.Reference)

    if ($PortServiceName.MatchPortNumber($Query) -or $PortServiceName.MatchServiceName($Query)) {
      $PortServiceNames += $PortServiceName
    }
  }

  return $PortServiceNames
}
