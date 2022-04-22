function Get-SpeedTestResults {
    $Path = ([Environment]::GetFolderPath("Desktop")) + "\SpeedTestResults"
    $Speedtest = & $PSScriptRoot\speedtest.exe --format=json --accept-license --accept-gdpr
    $Speedtest | Out-File $Path\Last.txt -Force
    $Speedtest = $Speedtest | ConvertFrom-Json
    [PSCustomObject]$SpeedObject = @{
        InterfaceName    = $Speedtest.interface.name
        DownloadSpeed    = [math]::Round($Speedtest.download.bandwidth / 1000000 * 8, 2)
        DownloadBytes    = $Speedtest.download.bytes
        DownloadTime     = $Speedtest.download.elapsed
        UploadSpeed      = [math]::Round($Speedtest.upload.bandwidth / 1000000 * 8, 2)
        PacketLoss       = [math]::Round($Speedtest.packetLoss)
        UploadBytes      = $Speedtest.upload.bytes
        UploadTime       = $Speedtest.upload.elapsed
        ISP              = $Speedtest.isp
        ExternalIP       = $Speedtest.interface.externalIp
        InternalIP       = $Speedtest.interface.internalIp
        UsedServer       = $Speedtest.server.host
        URL              = $Speedtest.result.url
        Jitter           = [math]::Round($Speedtest.ping.jitter)
        Latency          = [math]::Round($Speedtest.ping.latency)
        TimeStamp        = $Speedtest.timestamp
        MacAddress       = $Speedtest.interface.macAddr
        IsVPN            = $Speedtest.interface.isVpn
        ServerID         = $Speedtest.server.id
        ServerPort       = $Speedtest.server.port
        ServerName       = $Speedtest.server.name
        Country          = $Speedtest.server.country
        ServerIPAddress  = $Speedtest.server.ip
        ResultID         = $Speedtest.result.id
        PersistantResult = $Speedtest.result.persisted
    }
    # I need the output in one file per desired measurement
    $SpeedObject.downloadspeed | Out-File $Path\LastDownloadspeed.txt -Force
    $SpeedObject.uploadspeed | Out-File $Path\LastUploadspeed.txt -Force
    $SpeedObject.packetloss | Out-File $Path\LastPacketloss.txt -Force
    $SpeedObject.Jitter | Out-File $Path\LastJitter.txt -Force
    $SpeedObject.Latency | Out-File $Path\LastLatency.txt -Force
    $SpeedObject
}
