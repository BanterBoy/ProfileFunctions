Function Get-MgUserDetails {
    param (
        [string]$UserPrincipalName,
        [string]$enabled,
        [bool]$adminsOnly,
        [bool]$IsLicensed
    )

    process {
        # Set the properties to retrieve
        $select = @(
            'id',
            'DisplayName',
            'userprincipalname',
            'mail'
        )

        $properties = $select + "AssignedLicenses"

        # Get enabled, disabled or both users
        switch ($enabled) {
            "true" { $filter = "AccountEnabled eq true and UserType eq 'member'" }
            "false" { $filter = "AccountEnabled eq false and UserType eq 'member'" }
            "both" { $filter = "UserType eq 'member'" }
        }
    
        # Check if UserPrincipalName(s) are given
        if ($UserPrincipalName) {
            Write-Output "Get users by name"

            $users = @()
            foreach ($user in $UserPrincipalName) {
                try {
                    $users += Get-MgUser -UserId $user -Property $properties | Select-Object -Property $select -ErrorAction Stop
                }
                catch {
                    [PSCustomObject]@{
                        DisplayName       = " - Not found"
                        UserPrincipalName = $User
                        isAdmin           = $null
                        MFAEnabled        = $null
                    }
                }
            }
        }
        elseif ($adminsOnly) {
            Write-Output "Get admins only"

            $users = @()
            foreach ($admin in $admins) {
                $users += Get-MgUser -UserId $admin.UserPrincipalName -Property $properties | Select-Object $select
            }
        }
        else {
            if ($IsLicensed) {
                # Get only licensed users
                $users = Get-MgUser -Filter $filter -Property $properties -all | Where-Object { ($_.AssignedLicenses).count -gt 0 } | Select-Object $select
            }
            else {
                $users = Get-MgUser -Filter $filter -Property $properties -all | Select-Object $select
            }
        }
        return $users
    }
}