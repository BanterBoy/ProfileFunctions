<#
$UserTest = Get-AzureADUser -ObjectId testy.mctestingham@leigh-services.com | Select-Object City, Country, Department, DisplayName, Fax, GivenName, Surname, Mobile, OfficeLocation, PhoneNumber, PostalCode, State, StreetAddress, JobTitle, UserPrincipalName

$UserTest | ForEach-Object -Process { New-ADUser -Name ($_.Givenname + "." + $_.Surname) -SamAccountName ($_.Givenname + "." + $_.Surname) -GivenName $_.GivenName -Surname $_.Surname -City $_.City -Department $_.Department -DisplayName $_.DisplayName -Fax $_.Fax -MobilePhone $_.MobilePhone -Office $_.Office -PasswordNeverExpires ($_.PasswordNeverExpires -eq "True") -OfficePhone $_.PhoneNumber -PostalCode $_.PostalCode -EmailAddress $_.UserPrincipalName -State $_.State -StreetAddress $_.StreetAddress -Title $_.Title -UserPrincipalName $_.UserPrincipalName -AccountPassword (ConvertTo-SecureString -string "IamGroot.3188" -AsPlainText -Force) -Enabled $true }
#>

function Convert-AzuretoOnPrem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$AzureADUser,
    )
    begin {}
    process {
        $UserTest = Get-AzureADUser -ObjectId $AzureADUser | Select-Object City, Country, Department, DisplayName, Fax, GivenName, Surname, Mobile, OfficeLocation, PhoneNumber, PostalCode, State, StreetAddress, JobTitle, UserPrincipalName

        $UserTest | ForEach-Object -Process { New-ADUser -Name ($_.Givenname + "." + $_.Surname) -SamAccountName ($_.Givenname + "." + $_.Surname) -GivenName $_.GivenName -Surname $_.Surname -City $_.City -Department $_.Department -DisplayName $_.DisplayName -Fax $_.Fax -MobilePhone $_.MobilePhone -Office $_.Office -PasswordNeverExpires ($_.PasswordNeverExpires -eq "True") -OfficePhone $_.PhoneNumber -PostalCode $_.PostalCode -EmailAddress $_.UserPrincipalName -State $_.State -StreetAddress $_.StreetAddress -Title $_.Title -UserPrincipalName $_.UserPrincipalName -AccountPassword (ConvertTo-SecureString -string "IamGroot.3188" -AsPlainText -Force) -Enabled $true }
    }
    end {}
}

[example]
Convert-AzuretoOnPrem -AzureADUser something@something.com
