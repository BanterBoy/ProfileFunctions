function Update-PowerShell {

    $Module = "PowerShellForGitHub"

    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    if ( Get-Module -Name $Module ) {
        Import-Module -Name $Module
        Write-Warning "Module Import - Imported $Module"
    }

    else {
        Write-Warning "Installing $Module"
        $execpol = Get-ExecutionPolicy -List
        if ( $execpol -ne 'Unrestricted' ) {
            Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
        }
        Install-Module -Name $Module -Scope AllUsers
    }

    Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted

    if ($GitRelease -like "*" + $LocalVersion) {
        Write-Host "Up-to-date!"
    }

    else {
        $Protocols = [System.Net.SecurityProtocolType]'Tls12'
        [System.Net.ServicePointManager]::SecurityProtocol = $Protocols
        Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI"
    }

}
