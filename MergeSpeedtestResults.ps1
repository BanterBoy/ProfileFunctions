$totalDetails = @()
 
$Ind_Details = 
$UK_Details = 
 
$totalDetails += ConvertFrom-Json  $Ind_Details
$totalDetails += ConvertFrom-Json  $UK_Details
 
$totalDetails = $totalDetails | ConvertTo-Json
$totalDetails



Get-ChildItem -Path "C:\Users\Luke\OneDrive - leighzhao\Documents\SpeedTestResults\" -Filter *.json | Select-Object -ExpandProperty FullName | ConvertFrom-Json | ConvertTo-Json | Out-File -Path .\merged.json -Encoding UTF8
Get-ChildItem -Path "C:\Users\Luke\OneDrive - leighzhao\Documents\SpeedTestResults\" -Filter *.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv  -NoTypeInformation | Out-File -Path .\merged.csv -Encoding UTF8
