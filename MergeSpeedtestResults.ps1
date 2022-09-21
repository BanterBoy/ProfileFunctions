
$Files = Get-ChildItem -Path "$env:OneDriveCommercial\Documents\SpeedTestResults\" -Filter *.json

$Files.FullName | ForEach-Object -Process { Get-Content -Path $_ | ConvertFrom-Json } | ConvertTo-Json -Depth 5 | Out-File -Path "$env:OneDriveCommercial\Documents\SpeedTestResults\merged.json" -Encoding UTF8 -Append
