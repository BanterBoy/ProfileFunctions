function Convert-AzuretoOnPrem {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the UserPrincipalName for the Azure Account to be converted.'
        )]
        [string[]]$AzureADUser,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter a password for the converted Azure Account or pipe input. This is not a mandatory field and defaults to ThisIsMyPassword.1234'
        )]
        [Alias('cred')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $AccountPassword = (New-Object System.Management.Automation.PSCredential 'dummy', (ConvertTo-SecureString -String 'ThisIsMyPassword.1234' -AsPlainText -Force))
    )

    begin {
        Import-Module AzureAD
    }

    process {
        
        $users = Get-AzureADUser -ObjectId $AzureADUser
        foreach ($user in $users) {
            if ($PSCmdlet.ShouldProcess("$User", "Convertion of Azure AD user to on-premises AD user")) {
                $adUser = ConvertTo-ADUser -AzureADUser $user -AccountPassword $AccountPassword
                New-OnPremADUser -ADUser $adUser
                Export-ADUser -ADUser $adUser
                Set-AzureADUserImmutableId -AzureADUser $user -ADUser $adUser
            }
        }
    }

    end {
        Write-Output "Script completed."
    }
}

function ConvertTo-ADUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Open.AzureAD.Model.User]$AzureADUser,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$AccountPassword
    )

    $samAccountName = $AzureADUser.GivenName + "." + $AzureADUser.Surname

    $params = @{
        Name                 = $samAccountName
        SamAccountName       = $samAccountName
        GivenName            = $AzureADUser.GivenName
        Surname              = $AzureADUser.Surname
        City                 = $AzureADUser.City
        Department           = $AzureADUser.Department
        DisplayName          = $AzureADUser.DisplayName
        Fax                  = $AzureADUser.Fax
        MobilePhone          = $AzureADUser.Mobile
        Office               = $AzureADUser.OfficeLocation
        PasswordNeverExpires = [bool]$AzureADUser.PasswordNeverExpires
        OfficePhone          = $AzureADUser.PhoneNumber
        PostalCode           = $AzureADUser.PostalCode
        EmailAddress         = $AzureADUser.UserPrincipalName
        State                = $AzureADUser.State
        StreetAddress        = $AzureADUser.StreetAddress
        Title                = $AzureADUser.JobTitle
        UserPrincipalName    = $AzureADUser.UserPrincipalName
        AccountPassword      = $AccountPassword
        Enabled              = $true
    }

    return $params
}

function New-OnPremADUser {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$ADUser
    )

    if ($PSCmdlet.ShouldProcess($ADUser.UserPrincipalName, "Create on-premises AD user")) {
        Write-Verbose "Creating on-premises AD user: $($ADUser.SamAccountName)"
        New-ADUser @ADUser
    }
}

function Export-ADUser {
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$ADUser
    )

    $ldifdeCommand = "ldifde.exe -f $($Env:TEMP)\ExportAllUser.txt -r ""(UserPrincipalname=$($ADUser.UserPrincipalName))"" -l ""ObjectGuid,UserPrincipalName"""
    Start-Process -FilePath $ldifdeCommand -Wait -NoNewWindow
}

function Set-AzureADUserImmutableId {
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Open.AzureAD.Model.User]$AzureADUser,

        [Parameter(Mandatory = $true)]
        [Hashtable]$ADUser
    )

    Set-AzureADUser -ObjectId $AzureADUser.ObjectId -ImmutableId $ADUser.ObjectGuid
}

