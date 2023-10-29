function Get-ADGroupAccountDetails {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param (
        [Parameter(Mandatory = $false)]
        [String]
        $GroupName = 'Domain Admins',
        [Parameter(Mandatory = $false)]
        [Switch]
        $PassDetails,
        [Parameter(Mandatory = $false)]
        [String]
        $OutputFile
    )
    BEGIN { }
    PROCESS {
        $adminAccounts = Get-ADGroupMember -Identity $GroupName -Recursive | Get-ADUser -Properties *
        $adminAccountsData = $adminAccounts | ForEach-Object {
            $passwordAge = if ($_.PasswordLastSet) {
                ((Get-Date) - $_.PasswordLastSet).Days
            }
            $accountExpirationDate = if ($_.AccountExpirationDate) {
                $_.AccountExpirationDate
            }
            $lastLogonDate = if ($_.LastLogonDate) {
                $_.LastLogonDate
            }
            $groups = $_.MemberOf | ForEach-Object { (Get-ADGroup $_).Name }
            $adminAccount = [PSCustomObject]@{
                Name                  = $_.Name
                DisplayName           = $_.DisplayName
                SamAccountName        = $_.SamAccountName
                Description           = $_.Description
                Enabled               = $_.Enabled
                PasswordNeverExpires  = $_.PasswordNeverExpires
                PasswordLastSet       = $_.PasswordLastSet
                PasswordAge           = $passwordAge
                AccountExpirationDate = $accountExpirationDate
                LastLogonDate         = $lastLogonDate
                Groups                = $groups -join ', '
            }
            $adminAccount  # output the object to be collected in $adminAccountsData
        }
        if ($PassDetails) {
            $adminAccountsData | Select-Object -Property Name, SamAccountName, PasswordNeverExpires, PasswordLastSet, PasswordAge
        }
        elseif ($OutputFile) {
            $adminAccountsData | Export-Csv -Path $OutputFile -NoTypeInformation -Append -Encoding UTF8 -Force
        }
        else {
            $adminAccountsData
        }
    }
    END { }
}
