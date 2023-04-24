<#
class PortService {
    [string]$ServiceName
    [int]$PortNumber
    [string]$TransportProtocol
    [string]$Description
    [string]$Reference
  
    PortService([hashtable]$properties) {
        $this.ServiceName = $properties.ServiceName
        $this.PortNumber = $properties.PortNumber
        $this.TransportProtocol = $properties.TransportProtocol
        $this.Description = $properties.Description
        $this.Reference = $properties.Reference
    }
  
    [string]GetPortServiceByPortNumber([int]$portNumber) {
        if ($this.PortNumber -eq $portNumber) {
            return $this
        }
    }
  
    [string]GetPortServiceByServiceName([string]$serviceName) {
        if ($this.ServiceName -eq $serviceName) {
            return $this
        }
    }
}
  
# Create the function
function Get-PortService {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$PortNumber,
        [Parameter(Mandatory = $true)]
        [string]$TransportProtocol
    )
  
    $portServiceObjects | ForEach-Object {
        $portService = [PortService]@{
            ServiceName       = $_.ServiceName
            PortNumber        = $_.PortNumber
            TransportProtocol = $_.TransportProtocol
            Description       = $_.Description
            Reference         = $_.Reference
        }
  
        $portService.GetPortServiceByPortNumber($PortNumber)
        $portService.GetPortServiceByServiceName($TransportProtocol)
    }
}


function Get-PortService {
  param(
    [int]$PortNumber
  )

  $jsonFile = Join-Path $PSScriptRoot "allTCPports.json"
  $json = Get-Content $jsonFile -Raw | ConvertFrom-Json

  class TcpService {
    [string]$ServiceName
    [int]$PortNumber
    [string]$TransportProtocol
    [string]$Description
    [string]$Reference

    TcpService([string]$serviceName, [int]$portNumber, [string]$transportProtocol, [string]$description, [string]$reference) {
      $this.ServiceName = $serviceName
      $this.PortNumber = $portNumber
      $this.TransportProtocol = $transportProtocol
      $this.Description = $description
      $this.Reference = $reference
    }
  }

  $services = foreach ($svc in $json) {
    [TcpService]::new($svc.ServiceName, $svc.PortNumber, $svc.TransportProtocol, $svc.Description, $svc.Reference)
  }

  function Get-TcpServiceByPortNumber {
    param(
      [int]$PortNumber
    )

    return $services | Where-Object { $_.PortNumber -eq $PortNumber }
  }

  function Get-TcpServiceByServiceName {
    param(
      [string]$ServiceName
    )

    return $services | Where-Object { $_.ServiceName -eq $ServiceName }
  }

  return Get-TcpServiceByPortNumber $PortNumber
}


#>