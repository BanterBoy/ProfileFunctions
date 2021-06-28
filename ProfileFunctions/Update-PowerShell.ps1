function Update-PowerShell {
	$Protocols = [Net.SecurityProtocolType]'Tls12'
	[Net.ServicePointManager]::SecurityProtocol = $Protocols
	Invoke-Expression "& { $(Invoke-RestMethod -Method Get -Uri 'https://aka.ms/install-powershell.ps1') } -UseMSI"
}