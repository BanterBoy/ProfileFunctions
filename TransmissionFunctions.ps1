<#
.SYNOPSIS
Updates transmission to use default settings:

SeedRatioLimit:         0
SeedRatioLimited:       $True 
IncompleteDirectory:    "/share/Download/transmission/incomplete" 
DownloadDirectory:      "/share/Download/transmission/completed" 
DownloadQueueSize:      15

.EXAMPLE
Set-TransmissionDefaultSettings
#>
function Set-TransmissionDefaultSettings {
    $path = "/share/Download/transmission"

    Set-TransmissionSession -SeedRatioLimit 0 -SeedRatioLimited $True -IncompleteDirectory "$path/incomplete" -DownloadDirectory "$path/completed" -DownloadQueueSize 15
}

<#
.SYNOPSIS
Checks to see if the transmission download directory is "/share/Download/transmission/completed", and updates to default settings if not.

.EXAMPLE
Test-TransmissionSettings
#>
function Test-TransmissionSettings {
    $path = "/share/Download/transmission"

    try {
        $session = Get-TransmissionSession

        if ($session.DownloadDirectory -ne "$path/completed") {
            Write-Host "Transmission settings have reverted, updating to default..."

            Set-TransmissionDefaultSettings
        }
    }
    catch {
        Write-Warning -Message "Failed to get transmission settings, NAS may be offline..."
    }
}

$properties = @{
    AlternativeSpeedDown        = 1024
    AlternativeSpeedEnabled     = true
    AlternativeSpeedTimeBegin   = 480
    AlternativeSpeedTimeDay     = 127
    AlternativeSpeedTimeEnabled = true
    AlternativeSpeedTimeEnd     = 60
    AlternativeSpeedUp          = 128
    BlockListEnabled            = true
    BlockListUrl                = "http://john.bitsurge.net/public/biglist.p2p.gz"
    CacheSizeMb                 = 8
    DhtEnabled                  = true
    DownloadDirectory           = "/share/Public"
    DownloadQueueEnabled        = true
    DownloadQueueSize           = 1
    Encryption                  = "required"
    IdleSeedingLimit            = 0
    IdleSeedingLimitEnabled     = true
    IncompleteDirectory         = "/share/Public"
    IncompleteDirectoryEnabled  = true
    LpdEnabled                  = false
    PeerLimitGlobal             = 500
    PeerLimitPerTorrent         = 250
    PeerPort                    = 51413
    PeerPortRandomOnStart       = false
    PexEnabled                  = true
    PortForwardingEnabled       = true
    QueueStalledEnabled         = true
    QueueStalledMinutes         = 0
    RenamePartialFiles          = true
    ScriptTorrentDoneEnabled    = false
    ScriptTorrentDoneFilename   = ""
    SeedQueueEnabled            = true
    SeedQueueSize               = 0
    SeedRatioLimit              = 0
    SeedRatioLimited            = true
    SpeedLimitDown              = 10240
    SpeedLimitDownEnabled       = true
    SpeedLimitUp                = 512
    SpeedLimitUpEnabled         = true
    StartAddedTorrents          = false
    TrashOriginalTorrentFiles   = false
    UtpEnabled                  = true
}

Set-TransmissionDefaultSettings @properties
