function New-SpeedTest {
    <#
		.SYNOPSIS
			New-SpeedTest is a wrapper function for the the official command line client from Speedtest by Ookla for testing the speed and performance of your internet connection.

		.DESCRIPTION
			New-SpeedTest is a wrapper function for the the official command line client from Speedtest by Ookla for testing the speed and performance of your internet connection.

            Functionality included will allow you to perform a speedtest and output the results in a several formats; A PowerShell Object, CSV, Json and Json-Pretty.

            I have included the abilty to output the original Cli with the accompanying progress bar.
			
		.PARAMETER Path
			The Path parameter can be used to enter a specific file path to output the results. If no path is entered, it will attempt to use the default envinronment variable for your documents, with the caveat that a subfolder called SpeedTestResults should be created.
		
		.PARAMETER Format
			The Format parameter is used to speficify the file format. The is a predefined list of CSV, Json or Json-Pretty
		
		.PARAMETER selectionDetails
			The selectionDetails parameter
		
		.PARAMETER File
			A description of the File parameter.
		
		.EXAMPLE
			PS C:\> New-SpeedTest
		
		.NOTES
			Additional information about the function.
	#>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true
    )]
    param
    (
        <#
            
        #>
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
        [bool]
        $Progress = $true
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
