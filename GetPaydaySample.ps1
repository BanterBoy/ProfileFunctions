Write-Host "Next Pay Day:"
Get-PayDay
Write-Host "Mortgage End Date:"
Get-PayDay -Day 28 -Month February -Year 2022
Write-Host "Robs Mortgage Payment Calculator" -ForegroundColor Cyan -NoNewline:$false
Write-Host "Mortgage End Date : " -ForegroundColor Yellow -NoNewline:$true
Write-Host "$((Get-PayDay -Day 28 -Month February -Year 2030).Longdate)" -ForegroundColor Red
$DaysLeft = (New-TimeSpan -Start (Get-Date) -End (Get-PayDay -Day 28 -Month February -Year 2030).Date).TotalDays.ToString('.00')
if ($DaysLeft -gt ($DaysLeft / 3 * 2) ) {
	Write-Host "Mortgage Complete : " -ForegroundColor Yellow -NoNewline:$true
	Write-Host "$($DaysLeft)" -ForegroundColor Red -NoNewline:$true
	Write-Host " - Days Left" -ForegroundColor Red
}
elseif ($DaysLeft -lt ($DaysLeft / 2) ) {
	Write-Host "Mortgage Complete : " -ForegroundColor Yellow -NoNewline:$true
	Write-Host "Mortgage Complete = $($DaysLeft)" -ForegroundColor DarkGreen -NoNewline:$true
	Write-Host " - Days Left" -ForegroundColor DarkGreen
}
else { 
	Write-Host "Mortgage Complete : " -ForegroundColor Yellow -NoNewline:$true
	Write-Host "Mortgage Complete = $($DaysLeft)" -ForegroundColor Green -NoNewline:$true
	Write-Host " - Days Left" -ForegroundColor Green
}
