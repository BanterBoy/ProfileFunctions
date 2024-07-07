<#
.SYNOPSIS
    Script to perform various network and connectivity tests before, during, and after a VPN failover event.

.DESCRIPTION
    This script performs a series of tests to verify the availability and performance of network resources, services, and connections.
    The tests are executed before the VPN failover, during the failover, and after failing back to the primary VPN connection.
    The results from each stage are compared and logged for analysis.

.PARAMETER Computers
    List of computer names to test.

.PARAMETER Websites
    List of websites to test availability.

.PARAMETER Ports
    List of ports to test, each as a hashtable with ComputerName and Ports array.

.PARAMETER DnsRecords
    List of DNS records to resolve.

.PARAMETER NetworkShares
    List of network shares to test for file existence.

.PARAMETER LocalPath
    Local path for file copying tests.

.PARAMETER RemotePath
    Remote path for file copying tests.

.PARAMETER DummyFilePath
    Path to create dummy files for testing.

.PARAMETER ReportPath
    Path for the report file (default: C:\Reports\VPN_Update_Report.txt).

.PARAMETER LogPath
    Path for the log file (default: C:\Logs\VPN_Update_Logs.txt).

.PARAMETER FolderPaths
    List of folder paths to check existence.

.PARAMETER Services
    List of services to check on computers.

.PARAMETER ServerRoles
    List of server roles to test.

.PARAMETER Credential
    Credential for tasks requiring authentication.

.PARAMETER DebugMode
    Enable debug mode for detailed logging.

.EXAMPLE
    Example 1: Basic Execution
    Run the script with basic parameters.

    .\FirewallUpgradeTesting.ps1 -Computers @("Server1", "Server2") `
                                 -Websites @("https://example.com", "https://anotherexample.com") `
                                 -Ports @(@{ComputerName="Server1"; Ports=80, 443}, @{ComputerName="Server2"; Ports=22}) `
                                 -DnsRecords @("example.com", "anotherexample.com") `
                                 -NetworkShares @("\\Server1\Share1", "\\Server2\Share2") `
                                 -LocalPath "C:\Local\Path" `
                                 -RemotePath "\\Server1\Remote\Path" `
                                 -DummyFilePath "C:\Dummy\Files" `
                                 -FolderPaths @("C:\Folder1", "C:\Folder2") `
                                 -Services @("Service1", "Service2") `
                                 -ServerRoles @("DomainController", "FileServer") `
                                 -Credential (Get-Credential) `
                                 -DebugMode

.EXAMPLE
    Example 2: Without Credential Parameter
    Run the script without specifying the credential parameter (useful when running as a domain admin).

    .\FirewallUpgradeTesting.ps1 -Computers @("Server1", "Server2") `
                                 -Websites @("https://example.com", "https://anotherexample.com") `
                                 -Ports @(@{ComputerName="Server1"; Ports=80, 443}, @{ComputerName="Server2"; Ports=22}) `
                                 -DnsRecords @("example.com", "anotherexample.com") `
                                 -NetworkShares @("\\Server1\Share1", "\\Server2\Share2") `
                                 -LocalPath "C:\Local\Path" `
                                 -RemotePath "\\Server1\Remote\Path" `
                                 -DummyFilePath "C:\Dummy\Files" `
                                 -FolderPaths @("C:\Folder1", "C:\Folder2") `
                                 -Services @("Service1", "Service2") `
                                 -ServerRoles @("DomainController", "FileServer")

.EXAMPLE
    Example 3: Minimal Parameters
    Run the script with minimal required parameters.

    .\FirewallUpgradeTesting.ps1 -Computers @("Server1") `
                                 -Websites @("https://example.com") `
                                 -Ports @(@{ComputerName="Server1"; Ports=80}) `
                                 -DnsRecords @("example.com") `
                                 -NetworkShares @("\\Server1\Share1") `
                                 -LocalPath "C:\Local\Path" `
                                 -RemotePath "\\Server1\Remote\Path" `
                                 -DummyFilePath "C:\Dummy\Files"

.EXAMPLE
    Example 4: Using Debug Mode
    Run the script with the debug mode enabled to get detailed logging.

    .\FirewallUpgradeTesting.ps1 -Computers @("Server1", "Server2") `
                                 -Websites @("https://example.com", "https://anotherexample.com") `
                                 -Ports @(@{ComputerName="Server1"; Ports=80, 443}, @{ComputerName="Server2"; Ports=22}) `
                                 -DnsRecords @("example.com", "anotherexample.com") `
                                 -NetworkShares @("\\Server1\Share1", "\\Server2\Share2") `
                                 -LocalPath "C:\Local\Path" `
                                 -RemotePath "\\Server1\Remote\Path" `
                                 -DummyFilePath "C:\Dummy\Files" `
                                 -FolderPaths @("C:\Folder1", "C:\Folder2") `
                                 -Services @("Service1", "Service2") `
                                 -ServerRoles @("DomainController", "FileServer") `
                                 -Credential (Get-Credential) `
                                 -DebugMode

.EXAMPLE
    Example 5: Running with Output Redirection
    Run the script and redirect output to a file for review.

    .\FirewallUpgradeTesting.ps1 -Computers @("Server1", "Server2") `
                                 -Websites @("https://example.com", "https://anotherexample.com") `
                                 -Ports @(@{ComputerName="Server1"; Ports=80, 443}, @{ComputerName="Server2"; Ports=22}) `
                                 -DnsRecords @("example.com", "anotherexample.com") `
                                 -NetworkShares @("\\Server1\Share1", "\\Server2\Share2") `
                                 -LocalPath "C:\Local\Path" `
                                 -RemotePath "\\Server1\Remote\Path" `
                                 -DummyFilePath "C:\Dummy\Files" `
                                 -FolderPaths @("C:\Folder1", "C:\Folder2") `
                                 -Services @("Service1", "Service2") `
                                 -ServerRoles @("DomainController", "FileServer") `
                                 -Credential (Get-Credential) `
                                 -DebugMode | Tee-Object -FilePath "C:\Logs\ScriptOutput.txt"

.EXAMPLE
    Example 6: Specifying Custom Report and Log Paths
    Run the script with custom paths for the report and log files.

    .\FirewallUpgradeTesting.ps1 -Computers @("Server1", "Server2") `
                                 -Websites @("https://example.com", "https://anotherexample.com") `
                                 -Ports @(@{ComputerName="Server1"; Ports=80, 443}, @{ComputerName="Server2"; Ports=22}) `
                                 -DnsRecords @("example.com", "anotherexample.com") `
                                 -NetworkShares @("\\Server1\Share1", "\\Server2\Share2") `
                                 -LocalPath "C:\Local\Path" `
                                 -RemotePath "\\Server1\Remote\Path" `
                                 -DummyFilePath "C:\Dummy\Files" `
                                 -FolderPaths @("C:\Folder1", "C:\Folder2") `
                                 -Services @("Service1", "Service2") `
                                 -ServerRoles @("DomainController", "FileServer") `
                                 -Credential (Get-Credential) `
                                 -ReportPath "C:\Custom\Reports\VPN_Update_Report.txt" `
                                 -LogPath "C:\Custom\Logs\VPN_Update_Logs.txt" `
                                 -DebugMode

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Version: 1.0
#>

[CmdletBinding()]
param (
    [string[]]$Computers, # List of computer names to test
    [string[]]$Websites, # List of websites to test availability
    [array]$Ports, # List of ports to test, each as a hashtable with ComputerName and Ports array
    [string[]]$DnsRecords, # List of DNS records to resolve
    [string[]]$NetworkShares, # List of network shares to test for file existence
    [string]$LocalPath, # Local path for file copying tests
    [string]$RemotePath, # Remote path for file copying tests
    [string]$DummyFilePath, # Path to create dummy files for testing
    [string]$ReportPath = "C:\Reports\VPN_Update_Report.txt", # Path for the report file
    [string]$LogPath = "C:\Logs\VPN_Update_Logs.txt", # Path for the log file
    [string[]]$FolderPaths, # List of folder paths to check existence
    [string[]]$Services, # List of services to check on computers
    [string[]]$ServerRoles, # List of server roles to test
    [PSCredential]$Credential, # Credential for tasks requiring authentication
    [switch]$DebugMode                     # Enable debug mode for detailed logging
)

# Initialize logging using PoshLog module
Import-Module PoshLog
Start-Logger -LogPath $LogPath -Level Debug

# Function to log messages
function Write-LogMessage {
    param (
        [string]$Message, # Message to log
        [string]$Level = "Debug"           # Log level (default is Debug)
    )
    Write-Log -Level $Level -Message $Message
}

# Function to compare results from initial, failover, and failback stages
function Compare-Results {
    param (
        [string]$InitialResults, # Results from the initial stage
        [string]$FailoverResults, # Results from the failover stage
        [string]$FailbackResults           # Results from the failback stage
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
        [string]$Stage                     # Stage of testing (Initial, Failover, Failback)
    )
    $results = @()                         # Array to store test results
    $totalTests = 20                       # Total number of tests
    $progressCount = 0                     # Progress counter

    # Function to update progress bar
    function Update-Progress {
        param (
            [string]$Activity, # Current activity
            [string]$Status, # Current status
            [int]$PercentComplete          # Percentage completed
        )
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    }

    # Test website availability using Test-WebsiteAvailability function from your profile
    function Test-Websites {
        param (
            [string[]]$Urls                # List of URLs to test
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
            [array]$PortTests               # List of port tests, each with ComputerName and Ports array
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
            [string[]]$DnsRecords           # List of DNS records to resolve
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
            [string[]]$FilePaths            # List of network share paths to check
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
            [string[]]$FilePaths            # List of file paths to check
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
            [string]$LocalPath, # Local path for file copying
            [string]$RemotePath             # Remote path for file copying
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
            [string]$DummyFilePath          # Path to create dummy files
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
            [string[]]$ComputerNames        # List of computer names to test
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
            [string[]]$ComputerNames, # List of computer names to retrieve server info
            [PSCredential]$Credential       # Credential for authentication
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
            [string[]]$ComputerNames        # List of computer names to retrieve process details
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
            [string[]]$ComputerNames        # List of computer names to retrieve service details
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
            [string[]]$ComputerNames        # List of computer names to retrieve port details
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
            [string[]]$FolderPaths          # List of folder paths to check existence
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
            [string[]]$ComputerNames        # List of computer names to test TLS connections
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
            [string[]]$ComputerNames, # List of computer names to check server roles
            [string[]]$Roles                # List of server roles to test
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
            [string[]]$ComputerNames        # List of computer names to ping
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
            [string[]]$ComputerNames, # List of computer names to get GPO results
            [string[]]$UserNames, # List of user names to get GPO results
            [PSCredential]$Credential       # Credential for authentication
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

    # Run all tests sequentially
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
