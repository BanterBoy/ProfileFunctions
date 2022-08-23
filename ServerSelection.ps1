$Results = Get-Content -Path C:\Temp\Result-22-08-2022-13-38-20.json | ConvertFrom-Json
$Servers = $Results.serverSelection.servers
foreach ($Server in $Servers) {
    Try {
        $serverSelection = [ordered]@{
            ID       = $Server.server.id
            Host     = $Server.server.host
            Port     = $Server.server.port
            Name     = $Server.server.name
            Location = $Server.server.location
            Country  = $Server.server.country
        }
    }
    Catch {
        Write-Error $_
    }
    Finally {
        $obj = New-Object -TypeName PSObject -Property $serverSelection
        Write-Output $obj
    }
}
