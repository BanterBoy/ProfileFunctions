Function Initialize-TeamsLocalUploadFolder {
    param (
        [Parameter(Mandatory = $false)] [boolean]$IncludeNewTeams
    )
    
    $UserDirectories = Get-ChildItem 'C:\Users\' | Where-Object { $_.PSIsContainer }
    
    foreach ($UserDir in $UserDirectories) {
        $TeamsBackgroundBasePath = $UserDir.FullName + "\AppData\Roaming\Microsoft\Teams\Backgrounds\"
        $TeamsBackgroundUploadPath = $TeamsBackgroundBasePath + "\Uploads\"

        If (!(Test-Path $TeamsBackgroundUploadPath)) {
            try {
                New-Item -ItemType Directory -Path $TeamsBackgroundBasePath -Name "Uploads"
                $teamsLocalUploadFolderExists = $true
            }
            catch {
                $teamsLocalUploadFolderExists = $false
            }
        }
        else {
            $teamsLocalUploadFolderExists = $true 
        }
        if ($IncludeNewTeams -eq $true) {
            $NewTeamsBackgroundBasePath = $UserDir.FullName + "\AppData\Local" + "\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\"
            $NewTeamsBackgroundUploadPath = $NewTeamsBackgroundBasePath + "\Uploads\"
            If (!(Test-Path $NewTeamsBackgroundUploadPath)) {
                $NewTeamsLocalUploadFolderExists = $false
            }
            else {
                $NewTeamsLocalUploadFolderExists = $true
            }
        }
    
        return $teamsLocalUploadFolderExists, $NewTeamsLocalUploadFolderExists
    }
}
