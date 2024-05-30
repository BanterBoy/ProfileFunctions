function Get-VMInfoCustom {
    Param(
        [parameter()]
        [string]$ServerName
    )
    Get-View -ViewType VirtualMachine -Filter @{"Name" = "$($ServerName)" } | Select-Object -property Name, @{N = "PowerState"; E = { $_.Runtime.PowerState } }, @{N = "NumCpu"; E = { $_.Config.Hardware.NumCPU } }, @{N = "MemoryMB"; E = { $_.Config.Hardware.MemoryMB } }, @{N = "GuestOS"; E = { $_.Config.GuestFullName } }, @{N = "IPAddress"; E = { ($_.Guest.Net | Where-Object { $_.DeviceConfigId -eq 4000 }).IpAddress } }, @{N = "Datastore"; E = { (Get-View -Id $_.Datastore).Name } }, @{N = "Network"; E = { (Get-View -Id $_.Network).Name } }
}