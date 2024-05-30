function Get-ADUserPasswordStatus {
    <#
    .SYNOPSIS
        Gets the password status of an Active Directory user account.

    .DESCRIPTION
        Gets the password status of an Active Directory user account.

    .PARAMETER SamAccountName
        The SamAccountName of the user account.

    .PARAMETER Identity
        The Identity of the user account.

    .PARAMETER Domain
        The domain of the user account.

    .EXAMPLE
        Get-ADUserPasswordStatus -SamAccountName 'jsmith'

    .EXAMPLE
        Get-ADUserPasswordStatus -SamAccountName 'jsmith' -Domain 'contoso.com'

    .NOTES
        This function retrieves the password status of an Active Directory user account.
        It requires the SamAccountName parameter to specify the user account.
        The Identity parameter can also be used instead of SamAccountName.
        The Domain parameter is optional and defaults to the current user's domain.

    .LINK
        https://docs.microsoft.com/en-us/powershell/module/activedirectory/get-aduser

    #>
    [CmdletBinding( DefaultParameterSetName = 'Identity', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]

    Param(
        [Parameter( Mandatory = $true, Position = 0, ParameterSetName = 'Identity' )]
        [string]$SamAccountName,

        [Parameter( Mandatory = $false, Position = 1, ParameterSetName = 'Identity' )]
        [string]$Domain = $env:USERDOMAIN
    )

    Process {
        if ($PSCmdlet.ShouldProcess("Target", "Operation")) {
            
            try {
                $ADUser = Get-ADUser -Identity $SamAccountName -Server $Domain -Properties PasswordExpired, PasswordNeverExpires, PasswordLastSet, PasswordNotRequired, AccountExpirationDate, LockedOut, Enabled

                $PasswordStatus = [ordered]@{
                    SamAccountName        = $ADUser.SamAccountName
                    PasswordAgeDays       = [math]::Round((New-TimeSpan -Start $ADUser.PasswordLastSet -End (Get-Date)).TotalDays, 2)
                    Enabled               = $ADUser.Enabled
                    AccountExpirationDate = $ADUser.AccountExpirationDate
                    PasswordLastSet       = $ADUser.PasswordLastSet
                    LockedOut             = $ADUser.LockedOut
                    PasswordExpired       = $ADUser.PasswordExpired
                    PasswordNeverExpires  = $ADUser.PasswordNeverExpires
                    PasswordNotRequired   = $ADUser.PasswordNotRequired
                }
                New-Object -TypeName psobject -Property $PasswordStatus
            }
            catch {
                Write-Error -Message "Failed to get password status for user '$SamAccountName' in domain '$Domain'."
            }
        }
    }
}
