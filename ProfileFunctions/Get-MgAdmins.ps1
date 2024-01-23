Function Get-MgAdmins {
    <#
  .SYNOPSIS
    Get all user with an Admin role
  #>
    process {
        $admins = Get-MgDirectoryRole | Select-Object DisplayName, Id | 
        ForEach-Object -Process { $role = $_.DisplayName; Get-MgDirectoryRoleMember -DirectoryRoleId $_.id | 
            Where-Object -FilterScript { $_.AdditionalProperties."@odata.type" -eq "#microsoft.graph.user" } | 
            ForEach-Object -Process { Get-MgUser -userid $_.id }
        } | 
        Select-Object -Property @{Name = "Role"; Expression = { $role } }, DisplayName, UserPrincipalName, Mail, Id | Sort-Object -Property Mail -Unique
    
        return $admins
    }
}