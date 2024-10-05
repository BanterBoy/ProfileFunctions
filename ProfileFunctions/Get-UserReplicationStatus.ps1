function Get-UserReplicationStatus {
    param (
        [string]$UserName,
        [switch]$ShowPasswordDetails
    )

    # Ensure the ActiveDirectory module is available
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Error "The ActiveDirectory module is not available. Please install it to use this function."
        return
    }

    # Determine which format file to load
    $formatFilePath = if ($ShowPasswordDetails) {
        "$PSScriptRoot\Get-ADUserSearch.PasswordDetails.Format.ps1xml"
    }
    else {
        "$PSScriptRoot\Get-ADUserSearch.UserDetails.Format.ps1xml"
    }

    # Load the custom format file
    if (Test-Path $formatFilePath) {
        Update-FormatData -PrependPath $formatFilePath
    }
    else {
        Write-Warning "Format file not found at path: $formatFilePath"
    }

    # Get all domain controllers
    $domainControllers = Get-AllDomainControllers

    # Initialize an array to hold the results
    $results = @()

    # Iterate over each domain controller and get the user account details
    foreach ($dc in $domainControllers) {
        try {
            $user = Get-ADUser -Identity $UserName -Properties * -Server $dc.Hostname
            $result = [PSCustomObject]@{
                Server                = $dc.Hostname
                SamAccountName        = $user.SamAccountName
                LockedOut             = $user.LockedOut
                LastLogonDate         = $user.LastLogonDate
                PasswordLastSet       = $user.PasswordLastSet
                DisplayName           = $user.DisplayName
                EmailAddress          = $user.EmailAddress
                Title                 = $user.Title
                Department            = $user.Department
                GivenName             = $user.GivenName
                Surname               = $user.Surname
                StreetAddress         = $user.StreetAddress
                City                  = $user.City
                State                 = $user.State
                PostalCode            = $user.PostalCode
                Country               = $user.Country
                TelephoneNumber       = $user.TelephoneNumber
                MobilePhone           = $user.MobilePhone
                Company               = $user.Company
                Manager               = $user.Manager
                EmployeeID            = $user.EmployeeID
                Description           = $user.Description
                Office                = $user.PhysicalDeliveryOfficeName
                Division              = $user.Division
                Fax                   = $user.Fax
                Pager                 = $user.Pager
                HomePhone             = $user.HomePhone
                POBox                 = $user.PostOfficeBox
                LogonWorkstations     = $user.LogonWorkstations
                ScriptPath            = $user.ScriptPath
                ProfilePath           = $user.ProfilePath
                HomeDirectory         = $user.HomeDirectory
                HomeDrive             = $user.HomeDrive
                AccountExpirationDate = $user.AccountExpirationDate
                Enabled               = $user.Enabled
            }

            if ($ShowPasswordDetails) {
                $result | Add-Member -MemberType NoteProperty -Name 'PasswordNeverExpires' -Value $user.PasswordNeverExpires -Force
                $result | Add-Member -MemberType NoteProperty -Name 'PasswordExpired' -Value $user.PasswordExpired -Force
            }

            $result.PSObject.TypeNames.Insert(0, 'Custom.UserReplicationStatus')
            $results += $result
        }
        catch {
            Write-Warning "Failed to get user information from server $($dc.Hostname): $_"
        }
    }

    # Return the results
    return $results
}

# Example usage:
# $userStatus = Get-UserReplicationStatus -UserName "lucy.barrick"
# $userStatus | Format-Table -AutoSize

# Usage with password details:
# $userStatus = Get-UserReplicationStatus -UserName "lucy.barrick" -ShowPasswordDetails
# $userStatus | Format-Table -AutoSize
