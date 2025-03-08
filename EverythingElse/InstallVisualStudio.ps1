New-IntuneWin32AppPackage -FolderPath "C:\Temp\VisualStudio" -SetupFileName "PSAppDeployToolkit\Frontend\v4\Invoke-AppDeployToolkit.exe" -OutputPath "C:\Temp\IntuneWinFiles\Visual_Studio_Community.intunewin"

$DetectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -Path "C:\Program Files\VisualStudio\vs.exe" -FileOrFolder "file" -DetectionType "exists" -Check32BitOn64System $false
	
Add-IntuneWin32App -FilePath "C:\Temp\IntuneWinFiles\Visual_Studio_Community.intunewin" -DisplayName "Install Visual Studio Community Edition" -Description "Deploys Visual Studio Community Edition via Intune using PSAppDeployToolkit v4" -Publisher "Microsoft" -InstallCommand "Invoke-AppDeployToolkit.exe -Silent" -UninstallCommand "Invoke-AppDeployToolkit.exe -Uninstall -Silent" -InstallExperience system -RestartBehavior suppress -DetectionRule $DetectionRule
