function Test-GloDataExport {
    $GloExport = "CarpetrightGlo-" + [DateTime]::ParseExact( (Get-Date).ToShortDateString() , "dd/MM/yyyy", $null).ToString("yyyy-MM-dd") + "-import.csv"
    $Filepath = "C:\GitRepos\Carpetright\NewUserProcess\HRData\postreleasechanges\"
    Export-GloDataExtract -Path $Filepath -Filename $GloExport
}     
