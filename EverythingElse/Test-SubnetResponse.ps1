# <#
# 	mass-ping an entire IP range
# #>

# # IP range to ping
# $CIDRAddress
# $Subnet
 
# # timeout in milliseconds
# $timeout = 1000
 
# # number of simultaneous pings
# $throttleLimit = 80
 
# Based on the example code above Can you write a function that will allow me to enter the IP range using the parameters cidraddress, subnet and the timeout value, and return the results?
# The function will be called Test-SubnetResponse
# Available Parameters will be:
# -cidraddress
# -subnet
# -timeout

# Example:
# Test-SubnetResponse -cidraddress 10.10.0.0 -subnet 24 -timeout 1000

# The function should return the following:
# IP Address
# Status
# Response Time

# Example:
# IP Address:
#
# Status:
#
# Response Time:

# The function should also return the total execution time in milliseconds.

# Example:
# Execution Time: 1000 ms

# The function should also return the total number of IP addresses in the subnet.

# Example:
# Total IP Addresses: 254

# The function should also return the total number of IP addresses that responded.

# Example:
# Total IP Addresses Responded: 254

# The function should also return the total number of IP addresses that did not respond.

# Example:
# Total IP Addresses Did Not Respond: 0

Function Test-SubnetResponse {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$cidraddress,
        [Parameter(Mandatory = $true)]
        [int]$subnet,
        [Parameter(Mandatory = $true)]
        [int]$timeout
    )

    $ip = [System.Net.IPAddress]::Parse($cidraddress)
    $ipbytes = $ip.GetAddressBytes()
    $maskbytes = [System.Net.IPAddress]::IPv6MaskToIPv4Mask([System.Net.IPAddress]::Parse("::" * $subnet).GetAddressBytes(), 0)
    $start = [System.BitConverter]::ToUInt32($ipbytes, 0)
    $end = [System.BitConverter]::ToUInt32($maskbytes, 0)
    $total = $end - $start
    $totalip = $total + 1
    $totalipresponded = 0
    $totalipdidnotrespond = 0
    $totaltime = 0


    For ($i = $start; $i -le $end; $i++) {
        $ip = [System.Net.IPAddress]::Parse($i.ToString())
        $ping = New-Object System.Net.NetworkInformation.Ping
        $reply = $ping.Send($ip, $timeout)
        $totaltime += $reply.RoundtripTime
        If ($reply.Status -eq "Success") {
            $totalipresponded++
            Write-Host "IP Address: $ip"
            Write-Host "Status: $reply.Status"
            Write-Host "Response Time: $reply.RoundtripTime"
        }
        Else {
            $totalipdidnotrespond++
        }
    }

    Write-Host "Execution Time: $totaltime ms"
    Write-Host "Total IP Addresses: $totalip"
    Write-Host "Total IP Addresses Responded: $totalipresponded"
    Write-Host "Total IP Addresses Did Not Respond: $totalipdidnotrespond"
}

# Test-SubnetResponse -cidraddress 10.10.0.0 -subnet 24 -timeout 1000

