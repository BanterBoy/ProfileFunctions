<#
.SYNOPSIS
Converts an Azure AD user to an on-premises Active Directory user.

.DESCRIPTION
The Convert-AzuretoOnPrem function retrieves an Azure AD user's information and creates a corresponding on-premises Active Directory user using the New-ADUser cmdlet. The function requires the Azure AD user's Object ID as input.

.PARAMETER AzureADUser
Specifies the Object ID of the Azure AD user to convert.
Mandatory: Yes

.PARAMETER AccountPassword
Specifies the password for the converted user account. If not provided, the function will use the default password "ThisIsMyPassword.1234".
Mandatory: No
Default: "ThisIsMyPassword.1234"

.EXAMPLE
Convert-AzuretoOnPrem -AzureADUser "12345678-90ab-cdef-ghij-klmnopqrstuv" -AccountPassword "MyNewPassword123"
Converts the Azure AD user with the specified Object ID to an on-premises Active Directory user with the specified password.

.INPUTS
None

.OUTPUTS
None

#>

function Convert-AzuretoOnPrem {
    <#
.SYNOPSIS
Converts an Azure AD user to an on-premises Active Directory user.

.DESCRIPTION
The Convert-AzuretoOnPrem function retrieves an Azure AD user's information and creates a corresponding on-premises Active Directory user using the New-ADUser cmdlet. The function requires the Azure AD user's Object ID as input.

.PARAMETER AzureADUser
Specifies the Object ID of the Azure AD user to convert.
Mandatory: Yes

.PARAMETER AccountPassword
Specifies the password for the converted user account as a PSCredential object. If not provided, the function will use the default password "ThisIsMyPassword.1234".
Mandatory: No
Default: "ThisIsMyPassword.1234"

.EXAMPLE
$creds = Get-Credential
Convert-AzuretoOnPrem -AzureADUser "12345678-90ab-cdef-ghij-klmnopqrstuv" -AccountPassword $creds
Converts the Azure AD user with the specified Object ID to an on-premises Active Directory user with the specified password.

.INPUTS
None

.OUTPUTS
None

#>

    function Convert-AzuretoOnPrem {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param (
            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true,
                HelpMessage = 'Enter the UserPrincipalName for the Azure Account to be converted.'
            )]
            [string]$AzureADUser,

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
            $UserTest = Get-AzureADUser -ObjectId $AzureADUser | Select-Object City, Country, Department, DisplayName, Fax, GivenName, Surname, Mobile, OfficeLocation, PhoneNumber, PostalCode, State, StreetAddress, JobTitle, UserPrincipalName

            foreach ($User in $UserTest) {
                $samAccountName = $User.GivenName + "." + $User.Surname

                $params = @{
                    Name                 = $samAccountName
                    SamAccountName       = $samAccountName
                    GivenName            = $User.GivenName
                    Surname              = $User.Surname
                    City                 = $User.City
                    Department           = $User.Department
                    DisplayName          = $User.DisplayName
                    Fax                  = $User.Fax
                    MobilePhone          = $User.Mobile
                    Office               = $User.OfficeLocation
                    PasswordNeverExpires = [bool]$User.PasswordNeverExpires
                    OfficePhone          = $User.PhoneNumber
                    PostalCode           = $User.PostalCode
                    EmailAddress         = $User.UserPrincipalName
                    State                = $User.State
                    StreetAddress        = $User.StreetAddress
                    Title                = $User.JobTitle
                    UserPrincipalName    = $User.UserPrincipalName
                    AccountPassword      = $AccountPassword
                    Enabled              = $true
                }

                if ($PSCmdlet.ShouldProcess($User.UserPrincipalName, "Create on-premises AD user")) {
                    Write-Verbose "Creating on-premises AD user: $samAccountName"
                    New-ADUser @params
                }

                $ldifdeCommand = "ldifde.exe -f C:\Temp\ExportAllUser.txt -r ""(UserPrincipalname=$User.UserPrincipalName)"" -l ""ObjectGuid, userPrincipalName"""
                Start-Process -FilePath $ldifdeCommand -Wait -NoNewWindow
                Set-AzureADUser -ImmutableId $User.ObjectGuid
            }
        }

        end {
            Write-Output "Script completed."
        }
    }

}
