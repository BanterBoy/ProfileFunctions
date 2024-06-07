function Get-DCDiagResults {
    [CmdletBinding()]
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

    # Ensure output directory exists
    if (-not (Test-Path -Path $OutputDirectory)) {
        try {
            New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        }
        catch {
            Write-Error "Failed to create output directory: $_"
            return
        }
    }

    $DCList = Get-ADDomainController -Filter * -Server $Domain
    $totalDCs = $DCList.Count
    $currentIndex = 0

    foreach ($DC in $DCList) {
        $currentIndex++
        $percentComplete = [math]::Round(($currentIndex / $totalDCs) * 100)
        $FileDate = Get-Date -Format "dd-MM-yyyy-HH-mm-ss"
        $ServerName = $DC.Name

        Write-Progress -Activity "Processing domain controllers" -Status "$currentIndex out of $totalDCs" -PercentComplete $percentComplete

        if ($All -or $DCDiag) {
            Write-Progress -Activity "Running DCDiag for $ServerName" -Status "Processing DCDiag" -PercentComplete $percentComplete
            try {
                dcdiag.exe /s:$ServerName /c /e /v | Out-File -FilePath "$OutputDirectory\AD-dcdiag-report-$ServerName-$FileDate.txt"
                dcdiag.exe /s:$ServerName /test:dns /v | Out-File -FilePath "$OutputDirectory\DCDIAGdns-$ServerName-$FileDate.txt"
            }
            catch {
                Write-Error "Failed to run DCDiag on $($ServerName): $_"
            }
        }

        if ($All -or $DSQuery) {
            Write-Progress -Activity "Running DSQuery for $ServerName" -Status "Processing DSQuery" -PercentComplete $percentComplete
            try {
                dsquery server -o rdn | Out-File -FilePath "$OutputDirectory\list-all-DCs-$ServerName-$FileDate.txt"
            }
            catch {
                Write-Error "Failed to run DSQuery on $($ServerName): $_"
            }
        }

        if ($All -or $RepAdmin) {
            Write-Progress -Activity "Running RepAdmin for $ServerName" -Status "Processing RepAdmin" -PercentComplete $percentComplete
            $repAdminCommands = @(
                "/showrepl *",
                "/replsummary",
                "/showbackup *",
                "/queue *",
                "/bridgeheads * /verbose",
                "/istg * /verbose",
                "/failcache *",
                "/showtrust *",
                "/bind *",
                "/kcc *",
                "/syncall /APed"
            )
            foreach ($cmd in $repAdminCommands) {
                try {
                    $outputFile = "$OutputDirectory\$($cmd -replace '[/\*]', '')-$ServerName-$FileDate.txt"
                    repadmin $cmd | Out-File -FilePath $outputFile
                }
                catch {
                    Write-Error "Failed to run RepAdmin command '$cmd' on $($ServerName): $_"
                }
            }
        }

        if ($All -or $ADReplication) {
            Write-Progress -Activity "Running ADReplication for $ServerName" -Status "Processing ADReplication" -PercentComplete $percentComplete
            try {
                $ADReplicationResult = Get-ADReplicationUpToDatenessVectorTable -Target $ServerName
                $ADReplicationResult | Out-File -FilePath "$OutputDirectory\ADReplication-$ServerName-$FileDate.txt"
                $ADReplicationResult | Sort-Object LastReplicationSuccess | Out-File -FilePath "$OutputDirectory\ADReplicationSorted-$ServerName-$FileDate.txt"
            }
            catch {
                Write-Error "Failed to get ADReplication results for $($ServerName): $_"
            }
        }
    }

    Write-Verbose "Completed diagnostic results collection."
    Write-Progress -Activity "Processing complete" -Status "All tasks completed" -Completed
}
