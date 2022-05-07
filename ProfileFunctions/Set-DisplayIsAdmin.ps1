function Set-DisplayIsAdmin {

    if ((Test-IsAdmin) -eq $true) {
        if ((Get-Host).Version.Major -eq '5') {
			$Username = (Get-WMIObject -ClassName Win32_ComputerSystem).Username
            $host.UI.RawUI.WindowTitle = "$($Username) - Admin Privileges"
        }
        else {
			$Username = (Get-CimInstance -ClassName Win32_ComputerSystem).Username
            $host.UI.RawUI.WindowTitle = "$($Username) - Admin Privileges"
        }
    }	
    else {
        if ((Get-Host).Version.Major -eq '5') {
			$Username = (Get-WMIObject -ClassName Win32_ComputerSystem).Username
            $host.UI.RawUI.WindowTitle = "$($Username) - User Privileges"
        }
        else {
            $Username = (Get-CimInstance -ClassName Win32_ComputerSystem).Username
            $host.UI.RawUI.WindowTitle = "$($Username) - User Privileges"
        }
    }	
}
