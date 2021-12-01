$Scripts = Get-ChildItem C:\GitRepos\Carpetright\NewUserProcess\CarpetrightToolkit\Public\ -File | Select-Object -Property FullName
foreach ( $Script in $Scripts) {
    $Content = Get-Content -Path $Script.fullname
    Add-Content -Path C:\GitRepos\Carpetright\NewUserProcess\CarpetrightToolkit\CarpetrightToolkit.psm1 -Value $Content
}
