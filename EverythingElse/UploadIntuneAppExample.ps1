# Create Intune Package
New-IntuneWin32App -FilePath "C:\Temp\Install_Visual_Studio_Community.intunewin" `
                   -DisplayName "Install Visual Studio Community Edition" `
                   -Description "Deploys Visual Studio Community Edition via Intune" `
                   -Publisher "Microsoft" `
                   -InstallCommand "powershell.exe -ExecutionPolicy Bypass -File Install_Visual_Studio_Pro.ps1" `
                   -UninstallCommand "powershell.exe -ExecutionPolicy Bypass -File Uninstall_Visual_Studio_Pro.ps1" `
                   -InstallExperience system `
                   -RestartBehavior suppress `
                   -DetectionRuleScript "C:\IntunePackage\Detection.ps1"
 
# Add package to Intune
$DetectionRule = New-IntuneWin32AppDetectionRuleFile `
    -Existence `
    -Path "C:\Program Files\VisualStudio\vs.exe" `
    -FileOrFolder "file" `
    -DetectionType "exists" `
    -Check32BitOn64System $false
$IntuneWin = "C:\IntunePackage\Install_Visual_Studio_Pro.intunewin"
Add-IntuneWin32App -FilePath $IntuneWin `
                   -DisplayName "Install Visual Studio Pro" `
                   -Description "Deploys Visual Studio Pro via Intune" `
                   -Publisher "Microsoft" `
                   -InstallCommand "powershell.exe -ExecutionPolicy Bypass -File Install_Visual_Studio_Pro.ps1" `
                   -UninstallCommand "powershell.exe -ExecutionPolicy Bypass -File Uninstall_Visual_Studio_Pro.ps1" `
                   -InstallExperience system `
                   -RestartBehavior suppress `
                   -DetectionRule $DetectionRule
 
 
# Assign application to Developers Group
$group = Get-MgGroup -Filter "displayName eq 'Developers'"
$groupId = $group.Id
Add-IntuneWin32AppAssignmentGroup -Include -ID $app.Id -GroupID $groupId -Intent required
 
 
These are the commands I used to create and deploy the package to intune….it failed but I am not surprised...I just packaged your powershell script and I don't know if that works anyway
 
You may want to try making the package using the https://psappdeploytoolkit.com/
This is the only thing I haven't tried but I expect you will be able to build the package using that more easily and then package the script you need to deploy the exe...which you could include as a dependency