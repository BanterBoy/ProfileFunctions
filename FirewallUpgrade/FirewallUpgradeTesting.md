Here are some examples of how you would run this script with various parameters.

### Example 1: Basic Execution

Run the script with basic parameters.

```powershell
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
```

### Example 2: Without Credential Parameter

Run the script without specifying the credential parameter (useful when running as a domain admin).

```powershell
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
```

### Example 3: Minimal Parameters

Run the script with minimal required parameters.

```powershell
.\FirewallUpgradeTesting.ps1 -Computers @("Server1") `
                 -Websites @("https://example.com") `
                 -Ports @(@{ComputerName="Server1"; Ports=80}) `
                 -DnsRecords @("example.com") `
                 -NetworkShares @("\\Server1\Share1") `
                 -LocalPath "C:\Local\Path" `
                 -RemotePath "\\Server1\Remote\Path" `
                 -DummyFilePath "C:\Dummy\Files"
```

### Example 4: Using Debug Mode

Run the script with the debug mode enabled to get detailed logging.

```powershell
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
```

### Example 5: Running with Output Redirection

Run the script and redirect output to a file for review.

```powershell
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
```

### Example 6: Specifying Custom Report and Log Paths

Run the script with custom paths for the report and log files.

```powershell
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
```

In each example, the script is called with the required parameters for testing websites, ports, DNS resolution, network shares, file existence, file copying, dummy file creation, and more. The `Credential` parameter is provided where needed, and the `DebugMode` switch is used for detailed logging. Adjust the parameters based on your environment and testing needs.
