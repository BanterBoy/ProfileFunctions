function New-SpeedTest {
    <#
        .SYNOPSIS
        New-SpeedTest is a wrapper function for the the official command line client from Speedtest by Ookla for testing the speed and performance of your internet connection.

        .DESCRIPTION
        New-SpeedTest is a wrapper function for the the official command line client from Speedtest by Ookla for testing the speed and performance of your internet connection. Functionality included will allow you to perform a speedtest and output the results in a several formats; A PowerShell Object, CSV, Json and Json-Pretty. I have included the abilty to output the original Cli with the accompanying progress bar.

        .PARAMETER Path
        The Path parameter can be used to enter a specific file path to output the results. If no path is entered, it will attempt to use the default envinronment variable for your documents, with the caveat that a subfolder called SpeedTestResults should be created.

        .PARAMETER Format
        The Format parameter is used to speficify the file format. The is a predefined list of CSV, Json or Json-Pretty

        .PARAMETER selectionDetails
        The selectionDetails parameter displays the latency of the servers and which server was chosen based on the lowest score. If this option is not selected, it will not be captured or displayed in the output.

        .PARAMETER File
        The File parameter is a switch. If this parameter is selected, it will attempt to output the results to a log file. Should be used in conjunction with Path and Format. A file is created using the formula "Result-" + [datetime]::Now.ToString("dd-MM-yyyy-HH-mm-ss") + ".json" (Result-23-08-2022-15-07-28.json)

        .PARAMETER Cli
        The Cli parameter will display the default Cli results. Can be used in conjunction with Progress. This will not capture the results and will only display to the console.
            
        .PARAMETER Progress
        The Progress parameter will display the Cli progress bar. 

        .EXAMPLE
        PS C:\> New-SpeedTest

        Outputs the speedtest details as a PowerShell Object and displays the results to the console.

        TimeStamp        : 23/08/2022 12:13:32
        InternalIP       :  InternalIP
        MacAddress       :  MacAddress
        ExternalIP       :  ExternalIP
        IsVPN            : False
        ISP              : Virgin Media
        DownloadSpeed    : 156.79
        UploadSpeed      : 20.78
        DownloadBytes    : 198.53 MB
        UploadBytes      : 25.67 MB
        DownloadTime     : 11126
        UploadTime       : 10722
        Jitter           : 1
        Latency          : 12
        PacketLoss       : 0
        ServerName       : County Broadband Ltd
        ServerIPAddress  : 185.164.180.30
        UsedServer       : speedtst.countybroadband.net
        ServerPort       : 8080
        URL              : https://www.speedtest.net/result/c/147bb28b-3be7-4c5b-a039-a66d4dba70b9
        ServerID         : 26075
        Country          : United Kingdom
        ResultID         : 147bb28b-3be7-4c5b-a039-a66d4dba70b9
        PersistantResult : True

        .EXAMPLE
        New-SpeedTest -Format json-pretty -File -Path C:\Temp -selectionDetails

        Outputs the speedtest details and the server selection information as a PowerShell Object and displays the results to the console. Data is also output to a Json file and saved to the path C:\Temp

        ID       : 32775
        Host     : speedtest.trooli.com
        Port     : 8080
        Name     : Trooli
        Location : Maidstone
        Country  : United Kingdom
        Latency  : 17.345

        ID       : 1675
        Host     : speed.custdc.net
        Port     : 8080
        Name     : Custodian DataCentre
        Location : Maidstone
        Country  : United Kingdom
        Latency  : 13.231

        ID       : 4740
        Host     : speedtest.vinters.com
        Port     : 8080
        Name     : Vinters
        Location : Maidstone
        Country  : United Kingdom
        Latency  : 14.947

        ID       : 1531
        Host     : speedtest.thinkdedicated.com
        Port     : 8080
        Name     : Cloud Space UK
        Location : Canterbury
        Country  : United Kingdom
        Latency  : 21.256

        ID       : 47643
        Host     : speedtest-server.kent.ac.uk
        Port     : 8080
        Name     : University of Kent
        Location : Canterbury
        Country  : United Kingdom
        Latency  : 15.847

        ID       : 8164
        Host     : speedtest.csd.co
        Port     : 8080
        Name     : CSD Network Services Ltd
        Location : Braintree
        Country  : United Kingdom
        Latency  : 18.411

        ID       : 26075
        Host     : speedtst.countybroadband.net
        Port     : 8080
        Name     : County Broadband Ltd
        Location : Colchester
        Country  : United Kingdom
        Latency  : 10.865

        ID       : 30690
        Host     : speedtest.thn.lon.network.as201838.net
        Port     : 8080
        Name     : Community Fibre Limited
        Location : London
        Country  : United Kingdom
        Latency  : 18.845

        ID       : 34948
        Host     : speedtest.swishfibre.com
        Port     : 8080
        Name     : Swish Fibre
        Location : London
        Country  : United Kingdom
        Latency  : 11.784

        ID       : 22558
        Host     : speedtestlondon.telecom.mu
        Port     : 8080
        Name     : Mauritius Telecom Ltd
        Location : London
        Country  : United Kingdom
        Latency  : 222.919

        SelectedLatency  : 10.865
        TimeStamp        : 23/08/2022 11:47:55
        InternalIP       :  InternalIP
        MacAddress       :  MacAddress
        ExternalIP       :  ExternalIP
        IsVPN            : False
        ISP              : Virgin Media
        DownloadSpeed    : 134.86
        UploadSpeed      : 20.52
        DownloadBytes    : 222.33 MB
        UploadBytes      : 10.57 MB
        DownloadTime     : 15014
        UploadTime       : 4306
        Jitter           : 1
        Latency          : 11
        PacketLoss       : 0
        ServerName       : County Broadband Ltd
        ServerIPAddress  : 185.164.180.30
        UsedServer       : speedtst.countybroadband.net
        ServerPort       : 8080
        URL              : https://www.speedtest.net/result/c/578a407d-cd23-4163-833b-2696a7e5d7e1
        ServerID         : 26075
        Country          : United Kingdom
        ResultID         : 578a407d-cd23-4163-833b-2696a7e5d7e1
        PersistantResult : True

        .INPUTS
        You can pipe objects to these perameters.
        - Path [string]
    
        .OUTPUTS
        Object
    
        .NOTES
        Author:     Luke Leigh
        Website:    https://scripts.lukeleigh.com/
        LinkedIn:   https://www.linkedin.com/in/lukeleigh/
        GitHub:     https://github.com/BanterBoy/
        GitHubGist: https://gist.github.com/BanterBoy
    
        .LINK
        https://github.com/BanterBoy/scripts-blog
    
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium')]
    [Alias('nsp')]
    param(
        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $false,
            Position = 1,
            HelpMessage = 'Default file path is "Documents\SpeedTestResults", please specify your own path if this does not exist.'
        )]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]
        $Path = ([Environment]::GetFolderPath("MyDocuments")) + "\SpeedTestResults",

        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $false,
            Position = 2,
            HelpMessage = 'Please select a file type. This selection determines the output collected from the speedtest exectutable.'
        )]
        [ValidateSet(
            'csv',
            'json',
            'json-pretty'
        )]
        [string]
        $Format = 'json-pretty',
        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $false,
            Position = 3,
            HelpMessage = 'Show server selection details. Default option is False.'
        )]
        [switch]
        $selectionDetails,
        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $false,
            Position = 4,
            HelpMessage = 'Choose whether to output a file of not. Default selection is false.'
        )]
        [switch]
        $File,
        [Parameter(
            ParameterSetName = 'Cli',
            Mandatory = $false,
            Position = 5,
            HelpMessage = 'Select this option to run the native CLI output.'
        )]
        [switch]
        $Cli,
        [Parameter(
            ParameterSetName = 'Cli',
            Mandatory = $false,
            Position = 6,
            HelpMessage = 'Choose whether or not to display a progress bar when using the CLI'
        )]
        [Alias('prog')]
        [switch]
        $Progress
    )
    BEGIN {
    }
    PROCESS {
        if ($PSCmdlet.ShouldProcess("$Env:COMPUTERNAME", "Collecting SpeedTest Results")) {
            if ($Format -eq 'json' -or $Format -eq 'json-pretty') {
                if ($selectionDetails) {
                    $Speedtest = & $PSScriptRoot\speedtest.exe --format=$($Format) --accept-license --accept-gdpr --selection-details
                    if ($File) {
                        $Speedtest | Out-File -FilePath (  "$Path" + "\Result-" + [datetime]::Now.ToString("dd-MM-yyyy-HH-mm-ss") + ".json") -Encoding utf8 -Force
                    }
                    $Speedtest = $Speedtest | ConvertFrom-Json
                    $Servers = $Speedtest.serverSelection.servers
                    $SelectedLatency = $Speedtest.serverSelection.selectedLatency
                    foreach ($Server in $Servers) {
                        Try {
                            $serverSelection = [ordered]@{
                                ID       = $Server.server.id
                                Host     = $Server.server.host
                                Port     = $Server.server.port
                                Name     = $Server.server.name
                                Location = $Server.server.location
                                Country  = $Server.server.country
                                Latency  = $Server.latency
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
                    Try {
                        $properties = [ordered]@{
                            SelectedLatency  = $SelectedLatency
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
                    }
                    Catch {
                        Write-Error $_
                    }
                    Finally {
                        $obj = New-Object -TypeName PSObject -Property $properties
                        Write-Output $obj
                    }
                }
                elseif ($Cli) {
                    if ($progress) {
                        & $PSScriptRoot\speedtest.exe --accept-license --accept-gdpr --progress=yes
                    }
                    else {
                        & $PSScriptRoot\speedtest.exe --accept-license --accept-gdpr --progress=no
                    }
                }
                else {
                    $Speedtest = & $PSScriptRoot\speedtest.exe --format=$($Format) --accept-license --accept-gdpr
                    if ($File) {
                        Write-Verbose -Me "Writing CSV output to file $("$Path" + "\Result-" + [datetime]::Now.ToString("dd-MM-yyyy-HH-mm-ss") + ".csv")"
                        $Speedtest | Out-File -FilePath (  "$Path" + "\Result-" + [datetime]::Now.ToString("dd-MM-yyyy-HH-mm-ss") + ".json") -Encoding utf8 -Force
                    }
                    $Speedtest = $Speedtest | ConvertFrom-Json
                    Try {
                        $properties = [ordered]@{
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
                    }
                    Catch {
                        Write-Error $_
                    }
                    Finally {
                        $obj = New-Object -TypeName PSObject -Property $properties
                        Write-Output $obj
                    }
                }
            }
            else {
                Try {
                    $Speedtest = & $PSScriptRoot\speedtest.exe --format=$($Format) --accept-license --accept-gdpr
                    Write-Output "Writing CSV output to file $("$Path" + "\Result-" + [datetime]::Now.ToString("dd-MM-yyyy-HH-mm-ss") + ".csv")"
                    $Speedtest | Out-File -FilePath ("$Path" + "\Result-" + [datetime]::Now.ToString("dd-MM-yyyy-HH-mm-ss") + ".csv") -Encoding utf8 -Force
                }
                Catch {
                    Write-Error $_
                }
                
            }
        }
    }
    END {
    }
}
