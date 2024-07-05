# Import necessary functions from your profile
. "C:\Path\To\PowerShellProfile.psm1"

# Define parameters for the script
param (
    [string[]]$Computers,
    [string[]]$Websites,
    [array]$Ports,
    [string[]]$DnsRecords,
    [string[]]$NetworkShares,
    [string]$LocalPath,
    [string]$RemotePath,
    [string]$DummyFilePath,
    [string]$ReportPath = "C:\Reports\VPN_Update_Report.txt",
    [string]$LogPath = "C:\Logs\VPN_Update_Logs.txt",
    [string[]]$FolderPaths,
    [string[]]$Services,
    [string[]]$ServerRoles,
    [PSCredential]$Credential,
    [switch]$DebugMode
)

# Initialize logging
Import-Module PoshLog
Start-Logger -LogPath $LogPath -Level Debug

# Function to log messages
function Write-LogMessage {
    param (
        [string]$Message,
        [string]$Level = "Debug"
    )
    Write-Log -Level $Level -Message $Message
}

# Function to compare results
function Compare-Results {
    param (
        [string]$InitialResults,
        [string]$FailoverResults,
        [string]$FailbackResults
    )
    $comparison = @"
Comparison of Results:

Initial Results:
$InitialResults

Failover Results:
$FailoverResults

Failback Results:
$FailbackResults
"@
    Add-Content -Path $ReportPath -Value $comparison
}

# Function to run all tests with progress and error handling
function Invoke-AllTests {
    param (
        [string]$Stage
    )
    $results = @()
    $totalTests = 20
    $progressCount = 0

    function Update-Progress {
        param (
            [string]$Activity,
            [string]$Status,
            [int]$PercentComplete
        )
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    }

    # Test website availability using Test-WebsiteAvailability function from your profile
    function Test-Websites {
        param (
            [string[]]$Urls
        )
        foreach ($url in $Urls) {
            try {
                $response = Test-WebsiteAvailability -Url $url
                if ($response.StatusCode -eq 200) {
                    $message = "Website $url is available."
                }
                else {
                    $message = "Website $url is not available. Status Code: $($response.StatusCode)"
                }
            }
            catch {
                $message = "Website $url is not available. Error: $_"
            }
            Write-LogMessage -Message $message
            $results += $message
            $progressCount++
            Update-Progress -Activity "Running Tests" -Status "Testing Websites" -PercentComplete (($progressCount / $totalTests) * 100)
        }
    }

    # Check if specific ports are open using your Test-OpenPorts function
    function Test-Ports {
        param (
            [array]$PortTests
        )
        foreach ($test in $PortTests) {
            $computer = $test.ComputerName
            $ports = $test.Ports
            foreach ($port in $ports) {
                try {
                    $result = Test-OpenPorts -ComputerName $computer -Port $port
                    $message = "Port $port on ${computer}: $result"
                }
                catch {
                    $message = "Port $port on ${computer} is not open. Error: $_"
                }
                Write-LogMessage -Message $message
                $results += $message
                $progressCount++
                Update-Progress -Activity "Running Tests" -Status "Testing Ports" -PercentComplete (($progressCount / $totalTests) * 100)
            }
        }
    }

    # Verify DNS resolution using your Test-DNSRecord function
    function Test-DNSResolution {
        param (
            [string[]]$DnsRecords
        )
        foreach ($record in $DnsRecords) {
            try {
                $resolved = Test-DNSRecord -RecordName $record
                $message = "DNS record ${record} resolved: $resolved"
            }
            catch {
                $message = "DNS record ${record} could not be resolved. Error: $_"
            }
            Write-LogMessage -Message $message
            $results += $message
            $progressCount++
            Update-Progress -Activity "Running Tests" -Status "Testing DNS Resolution" -PercentComplete (($progressCount / $totalTests) * 100)
        }
    }

    # Check for the existence of files on network shares using Test-NetworkShares function
    function Test-NetworkShares {
        param (
            [string[]]$FilePaths
        )
        foreach ($filePath in $FilePaths) {
            try {
                $result = Test-NetworkShares -Path $filePath
                $message = "File ${filePath} exists: $result"
            }
            catch {
                $message = "File ${filePath} does not exist. Error: $_"
            }
            Write-LogMessage -Message $message
            $results += $message
            $progressCount++
            Update-Progress -Activity "Running Tests" -Status "Testing Network Shares" -PercentComplete (($progressCount / $totalTests) * 100)
        }
    }

    # Check if file exists using Test-FileExists function
    function Test-FileExistence {
        param (
            [string[]]$FilePaths
        )
        foreach ($filePath in $FilePaths) {
            try {
                $exists = Test-FileExists -Path $filePath
                $message = "File ${filePath} exists: $exists"
            }
            catch {
                $message = "File ${filePath} does not exist. Error: $_"
            }
            Write-LogMessage -Message $message
            $results += $message
            $progressCount++
            Update-Progress -Activity "Running Tests" -Status "Checking File Existence" -PercentComplete (($progressCount / $totalTests) * 100)
        }
    }

    # Perform file copying for speed/load testing using Copy-FilestoComputer function
    function Test-FileCopying {
        param (
            [string]$LocalPath,
            [string]$RemotePath
        )
        try {
            Copy-FilestoComputer -ComputerName $env:COMPUTERNAME -LocalPath $LocalPath -RemotePath $RemotePath
            $message = "Files copied from $LocalPath to $RemotePath successfully."
        }
        catch {
            $message = "File copying from $LocalPath to $RemotePath failed. Error: $_"
        }
        Write-LogMessage -Message $message
        $results += $message
        $progressCount++
        Update-Progress -Activity "Running Tests" -Status "Testing File Copying" -PercentComplete (($progressCount / $totalTests) * 100)
    }

    # Create dummy files to test file creation capabilities using Create-DummyFiles function
    function Test-DummyFileCreation {
        param (
            [string]$DummyFilePath
        )
        try {
            Create-DummyFiles -Path $DummyFilePath
            $message = "Dummy file ${DummyFilePath} created successfully."
        }
        catch {
            $message = "Failed to create dummy file ${DummyFilePath}. Error: $_"
        }
        Write-LogMessage -Message $message
        $results += $message
        $progressCount++
        Update-Progress -Activity "Running Tests" -Status "Testing Dummy File Creation" -PercentComplete (($progressCount / $totalTests) * 100)
    }

    # Test computer status using Test-Computer function
    function Test-Computers {
        param (
            [string[]]$ComputerNames
        )
        foreach ($computer in $ComputerNames) {
            try {
                $result = Test-Computer -ComputerName $computer
                $message = "Computer ${computer} status: $result"
            }
            catch {
                $message = "Failed to test computer status for ${computer}. Error: $_"
            }
            Write-LogMessage -Message $message
            $results += $message
            $progressCount++
            Update-Progress -Activity "Running Tests" -Status "Testing Computer Status" -PercentComplete (($progressCount / $totalTests) * 100)
        }
    }

    # Retrieve server information using Get-ServerInfo function
    function Get-ServersInfo {
        param (
            [string[]]$ComputerNames,
            [PSCredential]$Credential
        )
        foreach ($computer in $ComputerNames) {
            try {
                $result = Get-ServerInfo -ComputerName $computer -Credential $Credential
                $message = "Server info for ${computer}: $result"
            }
            catch {
                $message = "Failed to retrieve server info for ${computer}. Error: $_"
            }
            Write-LogMessage -Message $message
            $results += $message
            $progressCount++
            Update-Progress -Activity "Running Tests" -Status "Retrieving Server Info" -PercentComplete (($progressCount / $totalTests) * 100)
        }
    }

    # Retrieve process details using Get-ProcessDetails function
    function Get-Processes {
        param (
            [string[]]$ComputerNames
        )
        foreach ($computer in $ComputerNames) {
            try {
                $result = Get-ProcessDetails -ComputerName $computer
                $message = "Process details for ${computer}: $result"
            }
            catch {
                $message = "Failed to retrieve process details for ${computer}. Error: $_"
            }
            Write-LogMessage -Message $message
            $results += $message
            $progressCount++
            Update-Progress -Activity "Running Tests" -Status "Retrieving Process Details" -PercentComplete (($progressCount / $totalTests) * 100)
        }
    }

    # Retrieve service details using Get-ServiceDetails function
    function Get-Services {
        param (
            [string[]]$ComputerNames
        )
        foreach ($computer in $ComputerNames) {
            try {
                $result = Get-ServiceDetails -ComputerName $computer
                $message = "Service details for ${computer}: $result"
            }
            catch {
                $message = "Failed to retrieve service details for ${computer}. Error: $_"
            }
            Write-LogMessage -Message $message
            $results += $message
            $progressCount++
            Update-Progress -Activity "Running Tests" -Status "Retrieving Service Details" -PercentComplete (($progressCount / $totalTests) * 100)
        }
    }

    # Retrieve port details using Get-PortDetails function
    function Get-Ports {
        param (
            [string[]]$ComputerNames
        )
        foreach ($computer in $ComputerNames) {
            try {
                $result = Get-PortDetails -ComputerName $computer
                $message = "Port details for ${computer}: $result"
            }
            catch {
                $message = "Failed to retrieve port details for ${computer}. Error: $_"
            }
            Write-LogMessage -Message $message
            $results += $message
            $progressCount++
            Update-Progress -Activity "Running Tests" -Status "Retrieving Port Details" -PercentComplete (($progressCount / $totalTests) * 100)
        }
    }

    # Check folder existence using Test-FolderExists function
    function Test-FolderExistence {
        param (
            [string[]]$FolderPaths
        )
        foreach ($folderPath in $FolderPaths) {
            try {
                $exists = Test-FolderExists -Path $folderPath
                $message = "Folder ${folderPath} exists: $exists"
            }
            catch {
                $message = "Folder ${folderPath} does not exist. Error: $_"
            }
            Write-LogMessage -Message $message
            $results += $message
            $progressCount++
            Update-Progress -Activity "Running Tests" -Status "Checking Folder Existence" -PercentComplete (($progressCount / $totalTests) * 100)
        }
    }

    # Test TLS connections using Test-TLSConnection function
    function Test-TLSConnections {
        param (
            [string[]]$ComputerNames
        )
        foreach ($computer in $ComputerNames) {
            try {
                $result = Test-TLSConnection -ComputerName $computer
                $message = "TLS connection to ${computer}: $result"
            }
            catch {
                $message = "TLS connection to ${computer} failed. Error: $_"
            }
            Write-LogMessage -Message $message
            $results += $message
            $progressCount++
            Update-Progress -Activity "Running Tests" -Status "Testing TLS Connections" -PercentComplete (($progressCount / $totalTests) * 100)
        }
    }

    # Retrieve SYSVOL replication info using Get-SysvolReplicationInfo function
    function Get-SysvolReplication {
        try {
            $result = Get-SysvolReplicationInfo
            $message = "SYSVOL Replication Info: $result"
        }
        catch {
            $message = "Failed to retrieve SYSVOL Replication Info. Error: $_"
        }
        Write-LogMessage -Message $message
        $results += $message
        $progressCount++
        Update-Progress -Activity "Running Tests" -Status "Retrieving SYSVOL Replication Info" -PercentComplete (($progressCount / $totalTests) * 100)
    }

    # Check server roles using Test-ServerRolePortGroup function
    function Test-ServerRoles {
        param (
            [string[]]$ComputerNames,
            [string[]]$Roles
        )
        foreach ($computer in $ComputerNames) {
            foreach ($role in $Roles) {
                try {
                    $result = Test-ServerRolePortGroup -ComputerName $computer -ServerRole $role
                    $message = "Server role ${role} on ${computer}: $result"
                }
                catch {
                    $message = "Failed to test server role ${role} on ${computer}. Error: $_"
                }
                Write-LogMessage -Message $message
                $results += $message
                $progressCount++
                Update-Progress -Activity "Running Tests" -Status "Testing Server Roles" -PercentComplete (($progressCount / $totalTests) * 100)
            }
        }
    }

    # Ping tests using Test-Connection
    function Test-Ping {
        param (
            [string[]]$ComputerNames
        )
        foreach ($computer in $ComputerNames) {
            try {
                $result = Test-Connection -ComputerName $computer -Count 4
                $message = "Ping test to ${computer}: $result"
            }
            catch {
                $message = "Ping test to ${computer} failed. Error: $_"
            }
            Write-LogMessage -Message $message
            $results += $message
            $progressCount++
            Update-Progress -Activity "Running Tests" -Status "Running Ping Tests" -PercentComplete (($progressCount / $totalTests) * 100)
        }
    }

    # Group Policy Results using Get-TargetGPResult
    function Get-GPOResults {
        param (
            [string[]]$ComputerNames,
            [string[]]$UserNames,
            [PSCredential]$Credential
        )
        foreach ($computer in $ComputerNames) {
            foreach ($user in $UserNames) {
                try {
                    $result = Get-TargetGPResult -ComputerName $computer -UserName $user -Credential $Credential
                    $message = "GPO results for ${user} on ${computer}: $result"
                }
                catch {
                    $message = "Failed to retrieve GPO results for ${user} on ${computer}. Error: $_"
                }
                Write-LogMessage -Message $message
                $results += $message
                $progressCount++
                Update-Progress -Activity "Running Tests" -Status "Retrieving GPO Results" -PercentComplete (($progressCount / $totalTests) * 100)
            }
        }
    }

    # Run all tests
    Test-Websites -Urls $Websites
    Test-Ports -PortTests $Ports
    Test-DNSResolution -DnsRecords $DnsRecords
    Test-NetworkShares -FilePaths $NetworkShares
    Test-FileExistence -FilePaths $NetworkShares
    Test-FileCopying -LocalPath $LocalPath -RemotePath $RemotePath
    Test-DummyFileCreation -DummyFilePath $DummyFilePath
    Test-Computers -ComputerNames $Computers
    Get-ServersInfo -ComputerNames $Computers -Credential $Credential
    Get-Processes -ComputerNames $Computers
    Get-Services -ComputerNames $Computers
    Get-Ports -ComputerNames $Computers
    Test-FolderExistence -FolderPaths $FolderPaths
    Test-TLSConnections -ComputerNames $Computers
    Get-SysvolReplication
    Test-ServerRoles -ComputerNames $Computers -Roles $ServerRoles
    Test-Ping -ComputerNames $Computers
    Get-GPOResults -ComputerNames $Computers -UserNames @("Administrator") -Credential $Credential

    # Log results for the stage
    $stageResults = $results -join "`n"
    Add-Content -Path $LogPath -Value "`n${Stage} Results:`n$stageResults`n"

    return $stageResults
}

# Perform initial tests
$initialResults = Invoke-AllTests -Stage "Initial"

# Failover the VPN connection
Invoke-VpnFailover
Start-Sleep -Seconds 30 # Allow time for the failover

# Perform tests after failover
$failoverResults = Invoke-AllTests -Stage "Failover"

# Failback to the primary VPN connection
Invoke-VpnFailback
Start-Sleep -Seconds 30 # Allow time for the failback

# Perform tests after failback
$failbackResults = Invoke-AllTests -Stage "Failback"

# Compare results
Compare-Results -InitialResults $initialResults -FailoverResults $failoverResults -FailbackResults $failbackResults

# Summarize results
Add-Content -Path $ReportPath -Value "VPN Update Test Completed. Logs can be found at $LogPath."
Stop-Logger
