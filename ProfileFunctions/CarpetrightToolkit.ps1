function CarpetrightToolkit {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $InstallPath = 'C:\Program Files\Common Files\Modules\CarpetrightToolkit\',
        [Parameter()]
        [string]
        $CarpetrightToolkitPath = 'C:\GitRepos\Carpetright\NewUserProcess\CarpetrightToolkit\'
    )            
        
    begin {
            
    }
        
    process {

        if (Test-Path -Path:$InstallPath\CarpetrightToolkit.psm1) {
            Write-Output 'Removing Carpetright Toolkit...'
            Remove-Item -Path:$InstallPath -Recurse:$true -Force:$true
        }
        else {
            Write-Output 'Installing Carpetright Toolkit...'
            Copy-Item -Path:$CarpetrightToolkitPath -Destination:$InstallPath -Recurse:$true -Force:$true -Container:$true
        }
            
    }
        
    end {
            
    }
}
