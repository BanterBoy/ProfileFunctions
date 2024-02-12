# $AZSyncUsers = Get-ADUser -filter " Name -like '*' " -SearchBase "OU=Azure Sync Users,OU=Active,OU=RDG Users,DC=rdg,DC=co,DC=uk" | Where-Object -FilterScript { $_.Enabled -eq $true }
# $CalendarPermissions = $AZSyncUsers | ForEach-Object -Process {
# Get-O365CalendarPermissions -UserPrincipalName $_.UserPrincipalName
# }
# $CalendarPermissions | Where-Object -FilterScript { $_.User -eq "Charmaine Kerr" } | ft -AutoSize
# $CalendarPermissions | Where-Object -FilterScript { $_.User -eq "Charmaine Kerr" } | Export-Csv -Path C:\Temp\CharmaineCalendarPerms.csv -Encoding utf8

function Get-UsersCalendarAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserName,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath, 

        [Parameter(Mandatory = $false)]
        [string]$SearchBase
    )

    try {
        $AZSyncUsers = Get-ADUser -filter " Name -like '*' " -SearchBase $SearchBase -ErrorAction Stop | Where-Object -FilterScript { $_.Enabled -eq $true }
    }
    catch {
        Write-Error "Failed to get AD users: $_"
        return
    }

    $CalendarPermissions = $AZSyncUsers | ForEach-Object -Process {
        try {
            Get-O365CalendarPermissions -UserPrincipalName $_.UserPrincipalName -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to get calendar permissions for $($_.UserPrincipalName): $_"
        }
    } | Where-Object -FilterScript { $_.User -eq $UserName }

    if ($CalendarPermissions) {
        $CalendarPermissions | Export-Csv -Path $OutputPath -Encoding utf8 -ErrorAction SilentlyContinue
        if (-not $?) {
            Write-Error "Failed to export calendar permissions to CSV at $OutputPath"
        }
    }
    else {
        Write-Warning "No calendar permissions found for $UserName"
    }

    return $CalendarPermissions
}

# Get-UserCalendarAccess -UserName "Charmaine Kerr" -OutputPath "C:\Temp\CharmaineCalendarPerms.csv" -SearchBase "OU=Azure Sync Users,OU=Active,OU=RDG Users,DC=rdg,DC=co,DC=uk"
