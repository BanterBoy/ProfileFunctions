<#
.SYNOPSIS
    Retrieves diagnostic results for Active Directory domain controllers.

.DESCRIPTION
    The Get-DCDiagResults function retrieves diagnostic results for Active Directory domain controllers. It performs various tests and generates reports related to domain controller health, DNS, replication, and more.

.PARAMETER Domain
    Specifies the name of the domain for which to retrieve diagnostic results.

.PARAMETER OutputDirectory
    Specifies the directory where the diagnostic reports will be saved.

.PARAMETER All
    Indicates whether to retrieve all diagnostic results. If specified, all diagnostic tests will be performed and reports will be generated. If not specified, only specific diagnostic tests will be performed based on the other switches.

.PARAMETER DCDiag
    Indicates whether to retrieve diagnostic results using the DCDiag tool. If specified, the DCDiag tool will be used to perform diagnostic tests related to domain controller health and DNS.

.PARAMETER DSQuery
    Indicates whether to retrieve a list of all domain controllers in the domain. If specified, the DSQuery command will be used to retrieve the list of domain controllers.

.PARAMETER RepAdmin
    Indicates whether to retrieve diagnostic results using the RepAdmin tool. If specified, the RepAdmin tool will be used to perform diagnostic tests related to replication.

.PARAMETER ADReplication
    Indicates whether to retrieve diagnostic results using the Get-ADReplicationUpToDatenessVectorTable cmdlet. If specified, the cmdlet will be used to retrieve diagnostic results related to Active Directory replication.

.EXAMPLE
    Get-DCDiagResults -Domain "contoso.com" -OutputDirectory "C:\Reports" -All
    Retrieves all diagnostic results for the "contoso.com" domain and saves the reports in the "C:\Reports" directory.

.EXAMPLE
    Get-DCDiagResults -Domain "fabrikam.com" -OutputDirectory "D:\Reports" -DCDiag -DSQuery
    Retrieves diagnostic results using the DCDiag tool and retrieves a list of all domain controllers for the "fabrikam.com" domain. The reports are saved in the "D:\Reports" directory.

#>
function Get-DCDiagResults {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Domain,

        [Parameter(Mandatory=$true)]
        [string]$OutputDirectory,

        [switch]$All,
        [switch]$DCDiag,
        [switch]$DSQuery,
        [switch]$RepAdmin,
        [switch]$ADReplication
    )

    $DCList = (Get-ADForest).Domains | ForEach-Object -Process { Get-ADDomainController -Filter * -Server $_ }
    $DCList | Where-Object -Property Domain -EQ $Domain | ForEach-Object {
        $FileDate = [datetime]::Now.ToString("dd-MM-yyyy-HH-mm-ss")
        $ServerName = $_.Name
        if ($All -or $DCDiag) {
            dcdiag.exe /c /e /v | Out-File "$OutputDirectory\AD-dcdiag-report-$ServerName-$FileDate.txt"
            dcdiag.exe /s:$_ /test:dns /v | Out-File "$OutputDirectory\DCDIAGdns-$ServerName-$FileDate.txt"
        }
        if ($All -or $DSQuery) {
            dsquery server -o rdn | Out-File "$OutputDirectory\list-all-DCs-$ServerName-$FileDate.txt"
        }
        if ($All -or $RepAdmin) {
            repadmin /showrepl * | Out-File "$OutputDirectory\all-dc-replication-summary-$ServerName-$FileDate.txt"
            repadmin /replsummary | Out-File "$OutputDirectory\replication-health-summary-$ServerName-$FileDate.txt"
            repadmin /showbackup * | Out-File "$OutputDirectory\DC-backup-$ServerName-$FileDate.txt"
            repadmin /queue * | Out-File "$OutputDirectory\replication-queue-$ServerName-$FileDate.txt"
            repadmin /bridgeheads * /verbose | Out-File "$OutputDirectory\topology-summary-$ServerName-$FileDate.txt"
            repadmin /istg * /verbose | Out-File "$OutputDirectory\site-topology-summary-$ServerName-$FileDate.txt"
            repadmin /failcache * | Out-File "$OutputDirectory\failed-replication-kcc-$ServerName-$FileDate.txt"
            repadmin /showtrust * | Out-File "$OutputDirectory\show-trusts-$ServerName-$FileDate.txt"
            repadmin /bind * | Out-File "$OutputDirectory\ad-partition-info-$ServerName-$FileDate.txt"
            repadmin /kcc * | Out-File "$OutputDirectory\recalculate-kcc-$ServerName-$FileDate.txt"
            repadmin /syncall /APed | Out-File "$OutputDirectory\forced-push-replication-$ServerName-$FileDate.txt"
        }
        if ($All -or $ADReplication) {
            $ADReplicationResult = Get-ADReplicationUpToDatenessVectorTable -Target "$env:USERDNSDOMAIN"
            $ADReplicationResult | Out-File "$OutputDirectory\ADReplication-$ServerName-$FileDate.txt"
            $ADReplicationResult | Sort-Object LastReplicationSuccess | Out-File "$OutputDirectory\ADReplicationSorted-$ServerName-$FileDate.txt"
        }
    }
}