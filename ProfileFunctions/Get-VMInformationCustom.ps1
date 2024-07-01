<#
.SYNOPSIS
Retrieves information about a VM from vCenter.

.DESCRIPTION
This function retrieves information about a virtual machine (VM) from vCenter. It accepts the vCenter server name and the VM name as parameters. The function returns a custom object with various properties such as the VM's name, power state, vCenter server, datacenter, cluster, VM host, datastore, folder name, guest operating system, network name, IP address, MAC address, VM tools version, snapshot count, resource pool, and notes.

.PARAMETER VcenterServer
The name of the vCenter server.

.PARAMETER VMName
The name of the virtual machine.

.EXAMPLE
PS> Get-VMInformation -VcenterServer "vcenter.example.com" -VMName "VM1"
This example retrieves information about a VM named "VM1" from the vCenter server "vcenter.example.com".

.OUTPUTS
System.Management.Automation.PSCustomObject
A custom object with properties representing the VM information.

.NOTES
Author: Your Name
Date:   Current Date
#>

# Get-View -ViewType VirtualMachine -Filter @{"Name"="vm1"} | Select-Object -Property Name,@{N="PowerState";E={$_.Runtime.PowerState}},@{N="NumCpu";E={$_.Config.Hardware.NumCPU}},@{N="MemoryMB";E={$_.Config.Hardware.MemoryMB}},@{N="GuestOS";E={$_.Config.GuestFullName}},@{N="IPAddress";E={($_.Guest.Net | Where-Object {$_.DeviceConfigId -eq 4000}).IpAddress}},@{N="Datastore";E={(Get-View -Id $_.Datastore).Name}}

function Get-VMInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$VcenterServer,
        [Parameter(Mandatory = $true)]
        [string]$VMName
    )
    begin {
        $ErrorActionPreference = 'Stop'
        $Vcenter = Connect-VIServer -Server $VcenterServer -ErrorAction Stop
    }
    process {
        $VM = Get-VM -Name $VMName -ErrorAction Stop
        $VMView = Get-View -ViewType VirtualMachine -Filter @{"Name" = $VM.Name } -ErrorAction Stop
        $VMInfo = [PSCustomObject]@{
            Name          = $VM.Name
            PowerState    = $VMView.Runtime.PowerState
            vCenter       = $Vcenter.Name
            Datacenter    = $VM.VMHost.Parent.Parent.Name
            Cluster       = $VM.VMHost.Parent.Name
            VMHost        = $VM.VMHost.Name
            Datastore     = $VMView.Datastore.Name
            FolderName    = $VM.Folder.Name
            GuestOS       = $VM.Guest.OSFullName
            NetworkName   = $VM.NetworkAdapters[0].NetworkName
            IPAddress     = $VM.Guest.IPAddress[0]
            MacAddress    = $VM.NetworkAdapters[0].MacAddress
            VMTools       = $VM.ExtensionData.Guest.ToolsVersionStatus
            SnapshotCount = $VM.Snapshot.Count
            ResourcePool  = $VM.ResourcePool.Name
            Notes         = $VM.Notes
        }
        $VMInfo
    }
    end {
        # Disconnect-VIServer -Server $Vcenter -Confirm:$false -ErrorAction SilentlyContinue
    }
}