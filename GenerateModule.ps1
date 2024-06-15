# Path to the directory containing your PowerShell scripts
$scriptDir = "C:\GitRepos\RDGScripts\PowerShellProfile"
# Path to the module file
$modulePath = "C:\GitRepos\RDGScripts\PowerShellProfileModule\ProfileFunctions.psm1"

# Ensure the module directory exists
if (-not (Test-Path -Path "C:\GitRepos\RDGScripts\PowerShellProfileModule")) {
    New-Item -ItemType Directory -Path "C:\GitRepos\RDGScripts\PowerShellProfileModule" | Out-Null
}

# Create or update the module file
@"
# Auto-generated module file
# This file imports all PowerShell scripts from $scriptDir

"@ | Out-File -FilePath $modulePath -Encoding UTF8

# Import each .ps1 file and export the functions
Get-ChildItem -Path $scriptDir -Filter *.ps1 | ForEach-Object {
    "`n. `"$($scriptDir)\$($_.Name)`"" | Out-File -FilePath $modulePath -Encoding UTF8 -Append
    "Export-ModuleMember -Function $(($_.BaseName -replace '\.ps1$', ''))" | Out-File -FilePath $modulePath -Encoding UTF8 -Append
}

# Import the module
Import-Module $modulePath -Force
