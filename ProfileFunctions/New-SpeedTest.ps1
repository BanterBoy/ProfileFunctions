function New-SpeedTest {
    $Path = ([Environment]::GetFolderPath("Desktop")) + "\SpeedTestResults"
    $Speedtest = & $PSScriptRoot\speedtest.exe --format=json --accept-license --accept-gdpr
    $Speedtest | Out-File ("$Path\Result-" + ([datetime]::Today).ToShortDateString().replace("/", "-") + "-" + ([datetime]::Now).ToLongTimeString().replace(":", "-") + ".txt") -Force
    $Speedtest = $Speedtest | ConvertFrom-Json
    [PSCustomObject]$SpeedObject = [ordered]@{
        TimeStamp        = $Speedtest.timestamp
        InternalIP       = $Speedtest.interface.internalIp
        MacAddress       = $Speedtest.interface.macAddr
        ExternalIP       = $Speedtest.interface.externalIp
        IsVPN            = $Speedtest.interface.isVpn
        ISP              = $Speedtest.isp
        DownloadSpeed    = [math]::Round($Speedtest.download.bandwidth / 1000000 * 8, 2)
        UploadSpeed      = [math]::Round($Speedtest.upload.bandwidth / 1000000 * 8, 2)
        DownloadBytes    = (Get-FriendlySize $Speedtest.download.bytes)
        UploadBytes      = (Get-FriendlySize $Speedtest.upload.bytes)
        DownloadTime     = $Speedtest.download.elapsed
        UploadTime       = $Speedtest.upload.elapsed
        Jitter           = [math]::Round($Speedtest.ping.jitter)
        Latency          = [math]::Round($Speedtest.ping.latency)
        PacketLoss       = [math]::Round($Speedtest.packetLoss)
        ServerName       = $Speedtest.server.name
        ServerIPAddress  = $Speedtest.server.ip
        UsedServer       = $Speedtest.server.host
        ServerPort       = $Speedtest.server.port
        URL              = $Speedtest.result.url
        ServerID         = $Speedtest.server.id
        Country          = $Speedtest.server.country
        ResultID         = $Speedtest.result.id
        PersistantResult = $Speedtest.result.persisted
    }
    $SpeedObject
}
