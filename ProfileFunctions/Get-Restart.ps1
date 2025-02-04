Function Get-Restart {
    [cmdletbinding()]
    [outputtype("RestartEvent")]
    Param(
        [Parameter(Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias("CN")]
        [string]$Computername = $env:COMPUTERNAME,
        [Parameter(HelpMessage = "Find restart events since this date and time.")]
        [ValidateNotNullOrEmpty()]
        [Alias("Since")]
        [datetime]$After,
        [int64]$MaxEvents,
        [PSCredential]$Credential
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
        $filter = @{
            Logname = "System"
            ID      = 1074
        }
        if ($After) {
            Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Getting restart events after $After"
            $filter.Add("StartTime", $After)
        }

        $splat = @{
            ErrorAction = "Stop"
            FilterHash  = $Filter
        }
        if ($MaxEvents -gt 0) {
            Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Limiting search to $MaxEvents event(s)"
            $splat.Add("MaxEvents", $MaxEvents)
        }
        if ($Credential.UserName) {
            Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Adding a credential for $($Credential.UserName)"
            $splat.Add("Credential", $Credential)
        }
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting restart events on $($Computername.ToUpper())"
        $splat.Computername = $Computername
        Try {
            $entries = Get-WinEvent @splat
        }
        Catch {
            Throw $_
        }

        if ($entries) {
            #process entries into custom objects
            foreach ($entry in $entries) {
                #resolve the user SID
                Try {
                    Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Translating $($entry.UserId)"
                    $user = $entry.UserId.translate([System.Security.Principal.NTAccount]).value
                }
                Catch {
                    $user = $entry.properties[-1].value
                    #$entry.userid
                }

                [pscustomobject]@{
                    PSTypeName   = "RestartEvent"
                    Computername = $entry.machinename.ToUpper()
                    Datetime     = $entry.TimeCreated
                    Username     = $user
                    Category     = $entry.properties[4].value
                    Process      = $entry.properties[0].value.split()[0].trim()
                }
            } #foreach item
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"
    } #end

} #close Get-Restart

#add custom formatting
Update-FormatData $PSScriptRoot\restartevent.format.ps1xml