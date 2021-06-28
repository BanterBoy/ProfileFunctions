function New-Greeting {
	$Today = $(Get-Date)
	Write-Host "   Day of Week  -"$Today.DayOfWeek " - Today's Date -"$Today.ToShortDateString() "- Current Time -"$Today.ToShortTimeString()
	Switch ($Today.dayofweek) {
		Monday { Write-host "   Don't want to work today" }
		Friday { Write-host "   Almost the weekend" }
		Saturday { Write-host "   Everyone loves a Saturday ;-)" }
		Sunday { Write-host "   A good day to rest, or so I hear." }
		Default { Write-host "   Business as usual." }
	}
}