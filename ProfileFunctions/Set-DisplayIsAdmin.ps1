function Set-DisplayIsAdmin {
    $whoami = whoami /Groups /FO CSV | ConvertFrom-Csv -Delimiter ','
    $MSAccount = $whoami."Group Name" | Where-Object { $_ -like 'MicrosoftAccount*' }
    $LocalAccount = $whoami."Group Name" | Where-Object { $_ -like 'Local' }
    if ((Test-IsAdmin) -eq $true) {
        if (($MSAccount)) {
            $host.UI.RawUI.WindowTitle = "$($MSAccount.Split('\')[1]) - Admin Privileges"
        }
        else {
            $host.UI.RawUI.WindowTitle = "$($LocalAccount) - Admin Privileges"
        }
    }	
    else {
        if (($LocalAccount)) {
            $host.UI.RawUI.WindowTitle = "$($MSAccount.Split('\')[1]) - User Privileges"
        }
        else {
            $host.UI.RawUI.WindowTitle = "$($LocalAccount) - User Privileges"
        }
    }	
}
