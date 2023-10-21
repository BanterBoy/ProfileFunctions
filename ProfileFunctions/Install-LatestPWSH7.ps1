function Install-LatestPWSH7 {
    # Check for existing installation
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        $installedVersion = (pwsh --version).Split(" ")[-1]
        $latestVersion = (Invoke-RestMethod https://api.github.com/repos/PowerShell/PowerShell/releases/latest).tag_name.Replace("v", "")
        
        if ($installedVersion -eq $latestVersion) {
            Write-Output "The latest version of PowerShell 7 ($latestVersion) is already installed."
            return
        }
        else {
            Write-Output "An older version of PowerShell 7 ($installedVersion) is installed. The latest version is $latestVersion."
        }
    }

    # Attempt to install PowerShell 7
    try {
        Write-Verbose "Attempting to install PowerShell 7..."
        Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI"
        Write-Verbose "PowerShell 7 installed successfully."
    }
    catch {
        Write-Error "Failed to install PowerShell 7: $_"
    }
}