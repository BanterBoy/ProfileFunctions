Get-ADUser -Filter { name -like '*' } -Properties * | Where-Object -FilterScript { $_.UserPrincipalName -NE $null } | ForEach-Object -Process {
    try {
        $Perms = Get-O365CalendarPermissions -UserPrincipalName $_.UserPrincipalName -ErrorAction Ignore
        $prop = @{
            "Access"            = $Perms.AccessRights
            "User"              = $Perms.User
            "UserPrincipalName" = $Perms.UserPrincipalName
        }
        $obj = New-Object -TypeName psobject -Property $prop
        Write-Output -InputObject $obj
    }
    catch {
        Write-Error -Message "$($_.UserPrincipalName) : Mailbox does not exist"
    }
}
