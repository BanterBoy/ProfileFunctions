$Scripts = Get-ChildItem C:\GitRepos\Carpetright\CarpetrightToolkit\Functions\ -File | Select-Object -Property FullName
foreach ( $Script in $Scripts) {
    $Content = Get-Content -Path $Script.fullname
    Add-Content -Path C:\GitRepos\Carpetright\CarpetrightToolkit\CarpetrightToolkit\CarpetrightToolkit.psm1 -Value $Content
}
