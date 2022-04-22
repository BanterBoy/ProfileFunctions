function New-SpeedTest {

    <#
        Options
        -h, --help
        Print usage information

        -v Logging verbosity, specify multiple times for higher verbosity (e.g. -vvv)

        -V, --version Print version number

        -L, --servers List nearest servers

        --selection-details Show server selection details

        -s id, --server-id=id
        Specify a server from the server list using its id

        -o hostname, --host=hostname
        Specify a server from the server list using its hostname

        -f format_type --format=format_type
        Output format (default = human-readable) Note: Machine readable formats (csv, tsv, json, jsonl, json-pretty) use bytes as the unit of measure with max precision.

        format_type values are as follows:

        human-readable human readable output
        csv comma separated values
        tsv tab separated values
        json javascript object notation (compact)
        jsonl javascript object notation (lines)
        json-pretty javascript object notation (pretty)
        --progress-update-interval=interval Progress update interval (100-1000 milliseconds)

        --output-header Show output header for CSV and TSV formats

        -u* unit_of_measure***, --unit*** unit_of_measure* Output unit for displaying speeds (Note: this is only applicable for ‘human-readable’ output format and the default unit is Mbps)

        bps bits per second (decimal prefix)
        kbps kilobits per second (decimal prefix)
        Mbps megabits per second (decimal prefix)
        Gbps gigabits per second (decimal prefix)
        kibps kilobits per second (binary prefix)
        Mibps megabits per second (binary prefix)
        Gibps gigabits per second (binary prefix)
        B/s bytes per second
        kB/s kilobytes per second
        MB/s megabytes per second
        GiB/s gigabytes per second
        auto-binary-bytes automatic in binary bytes
        auto-decimal-bytes automatic in decimal bytes
        auto-binary-bytes automatic in binary bits
        auto-binary-bytes automatic in decimal bits
        -a
        Shortcut for [-u auto-decimal-bits]

        -A
        Shortcut for [-u auto-decimal-bytes]

        -b
        Shortcut for [-u auto-binary-bits]

        -B
        Shortcut for [-u auto-binary-bytes]

        -P decimal_places --precision=decimal_places
        Number of decimal_places to use (default = 2, valid = 0-8)

        -p yes|no --progress=yes|no
        Enable or disable progress bar (default = yes when interactive)

        -I interface --interface=interface Attempt to bind to the specified interface when connecting to servers

        -i ip_address --ip=ip_address Attempt to bind to the specified IP address when connecting to servers

        --ca-certificate=path Path to CA Certificate bundle, see note below.
    #>

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
