function Get-NextPayDay {
    $PayDays = Get-Content -Raw -Path C:\GitRepos\ProfileFunctions\PayDays.csv | ConvertFrom-Csv
    $PayDays | ForEach-Object -Process { New-CountdownDate -CountdownDay $_.PayDay } | Where-Object -FilterScript { $_.DaysLeft -notlike '-*' } | Select-Object -First 1
}
