<#
	mass-ping an entire IP range
#>

#requires -Version 7.0 

# IP range to ping
$IPAddresses = 1..255 | ForEach-Object {"192.168.1.$_"} 
 
# timeout in milliseconds
$timeout = 1000
 
# number of simultaneous pings
$throttleLimit = 80
 
# measure execution time
$start = Get-Date
 
$result = $IPAddresses | ForEach-Object -ThrottleLimit $throttleLimit -parallel {
    $ComputerName = $_
    $ping = [System.Net.NetworkInformation.Ping]::new()
 
    $ping.Send($ComputerName, $using:timeout) |
        Select-Object -Property Status, @{N='IP' ;E={$ComputerName}}, Address
    } | Where-Object Status -eq Success
  
$end = Get-Date
$time = ($end - $start).TotalMilliseconds
 
Write-Warning "Execution Time $time ms"   
 
$result

