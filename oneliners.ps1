
Import-Module cache -ErrorAction Ignore
Import-Module publishmap -ErrorAction Ignore

# grab functions from files
Get-ChildItem $PSScriptRoot\functions\ -Filter "*.ps1" | 
Where-Object { -not ($_.Name.Contains(".Tests.")) } |
Where-Object { -not (($_.Name).StartsWith("_")) } |
ForEach-Object { . $_.FullName }


function invoke-giteach($cmd) {
    Get-ChildItem | Where-Object { $_.psiscontainer } | ForEach-Object { Push-Location; Set-Location $_; if (tp ".git") { Write-Output; log-info $_; git $cmd }; Pop-Location; }
}
function invoke-gitpull {
    git-each "pull"
}

function convertto-colorcode($color) {
    $light = $false
    if ($color -isnot [int]) {
        if ($color.startswith("light")) {
            $light = $true
            $color = $color -replace "light", ""
        }
        $color = switch ($color) {
            "black" { 0 }
            "red" { 1 }
            "green" { 2 }
            "yellow" { 3 }
            "blue" { 4 }
            "magenta" { 5 }
            "cyan" { 6 }
            "white" { 7 }
            default { 9 }
        }
    }
    
    return $color, $light
}

function set-bgcolor($n) {
    $base = 40
    $n, $light = convertto-colorcode $n    
    Write-Output  ([char](0x1b) + "[$($base+$n);m")
    if ($light) { Write-Output ([char](0x1b) + "[1;m") }
}

function set-color($n) {
    $base = 30
    $n, $light = convertto-colorcode $n
    Write-Output  ([char](0x1b) + "[$($base+$n);m")
    if ($light) { Write-Output ([char](0x1b) + "[1;m") }
}

function write-controlchar($c) {
    Write-Output  ([char](0x1b) + "[$c;m")
}


function set-windowtitle([string] $title) {
    $host.ui.RawUI.WindowTitle = $title
}
function update-windowtitle() {
    if ("$PWD" -match "\\([^\\]*).hg") {
        set-windowtitle $Matches[1]
    }
}

function split-output {
    [CmdletBinding()] 
    param([Parameter(ValueFromPipeline = $true)]$item, [ScriptBlock] $Filter, $filePath, [switch][bool] $append)
    process {
        $null = $_ | Where-Object $filter | tee-object -filePath $filePath -Append:$append 
        $_
    }
}

<#
function pin-totaskbar {
    param($cmd, $arguments)
    $shell = new-object -com "Shell.Application"
    $cmd = (Get-Item $cmd).FullName
    $dir = split-path -Parent $cmd 
    $exe = Split-Path -Leaf $cmd 
    $folder = $shell.Namespace($dir)    
    $item = $folder.Parsename($cmd)
    $verb = $item.Verbs() | ? {$_.Name -eq 'Pin to Tas&kbar'}
    if ($verb) {$verb.DoIt()}
}#>

function Get-ComFolderItem {
    [CMDLetBinding()]
    param(
        [Parameter(Mandatory = $true)] $Path
    )

    $ShellApp = New-Object -ComObject 'Shell.Application'

    $Item = Get-Item $Path -ErrorAction Stop

    if ($Item -is [System.IO.FileInfo]) {
        $ComFolderItem = $ShellApp.Namespace($Item.Directory.FullName).ParseName($Item.Name)
    }
    elseif ($Item -is [System.IO.DirectoryInfo]) {
        $ComFolderItem = $ShellApp.Namespace($Item.Parent.FullName).ParseName($Item.Name)
    }
    else {
        throw "Path is not a file nor a directory"
    }

    return $ComFolderItem
}

function Install-TaskBarPinnedItem {
    [CMDLetBinding()]
    param(
        [Parameter(Mandatory = $true)] [System.IO.FileInfo] $Item
    )

    $Pinned = Get-ComFolderItem -Path $Item

    $Pinned.invokeverb('taskbarpin')
}

function Uninstall-TaskBarPinnedItem {
    [CMDLetBinding()]
    param(
        [Parameter(Mandatory = $true)] [System.IO.FileInfo] $Item
    )

    $Pinned = Get-ComFolderItem -Path $Item

    $Pinned.invokeverb('taskbarunpin')
}

<#  new-shortcut is defined in pscx also #>

function new-shortcut {
    param ( [Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][string]$target, [string]$Arguments = "" )
    
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($Name)
    $Shortcut.TargetPath = $target
    $Shortcut.Arguments = $Arguments
    $Shortcut.Save()
}

function stop-allprocesses ($name) {
    # or just:
    # stop-process -name $name
    cmd /C taskkill /IM "$name.exe" /F
    cmd /C taskkill /IM "$name" /F
}

function test-any() {
    begin { $ok = $true; $seen = $false } 
    process { $seen = $true; if (!$_) { $ok = $false } } 
    end { $ok -and $seen }
} 

function get-dotnetversions() {
    $def = get-content "$psscriptroot\dotnetver.cs" | out-string
    add-type -TypeDefinition $def

    return [DotNetVer]::GetVersionFromRegistry()
}

<#
function reload-module($module) {
    if (gmo $module) { rmo $module  }
    ipmo $module -Global
}
#>

function test-tcp {
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$ip,

        [Parameter(Mandatory = $True, Position = 2)]
        [int]$port
    )

    $connection = New-Object System.Net.Sockets.TcpClient($ip, $port)
    if ($connection.Connected) {
        Return "Connection Success"
    }
    else {
        Return "Connection Failed"
    }
}

function import-state([Parameter(Mandatory = $true)]$file) {
    if (!(test-path $file)) {
        return $null
    }
    $c = get-content $file | out-string
    $obj = convertfrom-json $c 
    if ($null -eq $obj) { throw "failed to read state from file $file" }
    return $obj
}

function export-state([Parameter(Mandatory = $true)]$state, [Parameter(Mandatory = $true)]$file) {
    $state | convertto-json | out-file $file -encoding utf8
}


function Add-DnsAlias {
    [CmdletBinding()]
    param ([Parameter(Mandatory = $true)] $from, [Parameter(Mandatory = $true)] $to)
     
    $hostlines = @(get-content "c:\Windows\System32\drivers\etc\hosts")
    $hosts = @{}
    
    write-verbose "resolving name '$to'"

    if ($to -match "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+") {
        $ip = $to
    }
    else {
        $r = Resolve-DnsName $to
        if ($null -ne $r.Ip4address) {
            $ip = $r.ip4address        
        }
        else {
            throw "could not resolve name '$to'"
        }
    }
    for ($l = 0; $l -lt $hostlines.Length; $l++) {
        $_ = $hostlines[$l].Trim()
        if ($_.StartsWith("#") -or $_.length -eq 0 -or [string]::IsNullOrEmpty($_)) { continue }        
        $s = $_.Split(' ')
        $org = $_
        try {
            $hosts[$s[1]] = New-Object -type pscustomobject -Property @{ alias = $s[1]; ip = $s[0]; line = $l } 
        }
        catch {
            Write-Warning "failed to pars etc/hosts line: '$org'"
        }
    }
    
    if ($hosts.ContainsKey($from)) {
        $hosts[$from].ip = $ip
    }
    else {
        $hosts[$from] = New-Object -type pscustomobject -Property @{ alias = $from; ip = $ip; line = $hostlines.Length }
        $hostlines += @("")
    }
    
    Write-Verbose "adding to etc\hosts: $ip $from"
    $hostlines[$hosts[$from].line] = "$ip $from"
    
    $guid = [guid]::NewGuid().ToString("n")
    Write-Verbose "backing up etc\hosts to $env:TEMP\hosts-$guid"
    Copy-Item "c:\Windows\System32\drivers\etc\hosts" "$env:TEMP\hosts-$guid"  
    
    $hostlines | Out-File "c:\Windows\System32\drivers\etc\hosts" -Encoding ascii
}

function remove-dnsalias([Parameter(Mandatory = $true)] $from) {
    $hostlines = @(Get-Content "c:\Windows\System32\drivers\etc\hosts")
    $hosts = @{}
    
    $newlines = @()
    $found = $false
    for ($l = 0; $l -lt $hostlines.Length; $l++) {
        $_ = $hostlines[$l]
        if ($_.Trim().StartsWith("#") -or $_.Trim().length -eq 0) { 
            $newlines += @($_); 
            continue 
        }        
        $s = $_.Trim().Split(' ')
        if ($s[1] -ne $from) {
            $newlines += @($_)            
        }
        else {
            $found = $true
        }
    }
    
    if (!$found) {
        Write-Warning "alias '$from' not found!"
        return
    } 
    
    $guid = [guid]::NewGuid().ToString("n")
    Write-Host "backing up etc\hosts to $env:TEMP\hosts-$guid"
    Copy-Item "c:\Windows\System32\drivers\etc\hosts" "$env:TEMP\hosts-$guid"  
    
    $newlines | Out-File "c:\Windows\System32\drivers\etc\hosts" 
    
}

function test-isadmin() {
    # Get the ID and security principal of the current user account
    $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

    # Get the security principal for the Administrator role
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

    # Check to see if we are currently running "as Administrator"
    return $myWindowsPrincipal.IsInRole($adminRole)
}

function Send-Slack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$Text,
        [Parameter(Mandatory = $false)]$Channel,
        [Parameter(Mandatory = $false)]$AsUser
    )
    process {
        Import-Module Require
        req psslack

        $cred = get-credentialscached -message "slack username and token (or webhook  uri)" -container "slack"
        $username = $cred.UserName
        $token = $cred.GetNetworkCredential().password

        $sendasuser = $AsUser

        if ($null -eq $AsUser) {
            $sendasuser = $true
        }

        if ($null -eq $Channel -and $null -ne $env:slackuser) {
            $Channel = "@$env:slackuser"
            Write-Verbose "setting channel to $channel"
            if ($null -eq $AsUser) { $sendasuser = $false }
        }
        if ($null -eq $Channel) {
            $Channel = "@$username"
            if ($null -eq $AsUser) { $sendasuser = $false }
        }

        $a = @{}
        if ($token.startswith("http")) {
            $a["uri"] = $token
        }
        else {
            $a["token"] = $token
            $a["username"] = $username
            $a["channel"] = $channel
        }
        $null = Send-SlackMessage @a -Text $text  -AsUser:$sendasuser
    }
}

function disable-hyperv {
    bcdedit /set hypervisorlaunchtype off
    write-host "hypervisorlaunchtype=off. Reboot to apply:"
    write-host "shutdown /r /t 0 /f"
}
function enable-hyperv {
    bcdedit /set hypervisorlaunchtype auto
    write-host "hypervisorlaunchtype=auto. Reboot to apply:"
    write-host "shutdown /r /t 0 /f"
}

function grep {
    param($regex)

    begin {
    }

    process {
        $_ | Where-Object { $_ -match $regex }
    }

    end {        
    }

}

function notify {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$Text,
        [Parameter(Mandatory = $false)]$Channel,
        [Parameter(Mandatory = $false)]$AsUser
    )
    begin { 
        slack "[$(get-date -Format "yyyy-MM-dd HH:mm:ss.ff")] Starting $Text" -Channel $Channel -AsUser:$AsUser 
    }
    process {
        write-verbose "notify"
    }    
    end {
        if ($Text -is [System.Management.Automation.ErrorRecord]) {
            slack "[$(get-date -Format "yyyy-MM-dd HH:mm:ss.ff")] FAIL $Text" -Channel $Channel -AsUser:$AsUser
        }
        else {
            slack "[$(get-date -Format "yyyy-MM-dd HH:mm:ss.ff")] DONE $Text" -Channel $Channel -AsUser:$AsUser
        }
    }
}

function foreach-repo ([scriptblock] $ScriptBlock, $argumentList) {
    foreach ($d in (Get-ChildItem . -Directory)) {
        try {
            if (Test-Path "$($d.name)/.hg") {
                Push-Location 
                Set-Location $d.name
                try {
                    Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList (@("hg") + $argumentList)
                }
                finally {
                    Pop-Location
                }
            }
            if (test-path "$($d.name)/.git") {
                Push-Location 
                Set-Location $d.name
                try {
                    Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList (@("git") + $argumentList)
                }
                finally {
                    Pop-Location
                }
            }
        }
        catch {
            Write-Error $_
        }
    }
}

function pull-all {
    foreach-repo {
        param($command)
        invoke $command pull
    }
}

function update-all ($rev) {
    foreach-repo {
        param($command, $rev)
        if ($command -eq "hg") {
            invoke $command update $rev
        }
        else {
            Write-Warning "don't know how to git update"
        }
    } 
}

function tryloop {
    param([scriptblock]$cmd, $interval = 1)
    while (1) {
        try {
            Invoke-Command $cmd -ErrorAction Stop
            break
        }
        catch {
            Write-Warning $_.Message
            Start-Sleep $interval
        }
    }
}

function Register-FileSystemWatcher {
    
    Param(
        [Parameter(Mandatory = $true)][string]$file, 
        [Parameter(Mandatory = $true)][scriptblock] $cmd,        
        $filter = "*.*",
        [ValidateSet("Created", "Changed", "Deleted", "Renamed")]
        $events = @("Created", "Changed", "Deleted", "Renamed"),
        [switch][bool] $loop,
        [switch][bool] $nowait         
    ) 

    ### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = (Get-Item $file).FullName
    $watcher.Filter = $filter
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true  

    ### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
    $action = { 
        try {
            #$event | format-table | out-string | write-verbose -verbose
            #$event.MessageData | out-string | write-verbose -verbose
            #$event.MessageData.gettype() | out-string | write-verbose -verbose
            $path = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
                        
            Write-Verbose "[$(Get-Date)] $changeType, $path" -Verbose
            Invoke-Command $event.MessageData.cmd -ArgumentList $path, $changeType -Verbose
            Write-Verbose "[$(Get-Date)] DONE $changeType, $path" -Verbose
            if ($event.MessageData.loop) {
                #Register-ObjectEvent $event.sender -EventName $changeType -Action $event.MessageData.action -MessageData $event.MessageData
            }
        }
        catch {
            Write-Error $_
            throw                    
        }
    }          

    ### DECIDE WHICH EVENTS SHOULD BE WATCHED 

    $jobs = $events | ForEach-Object {
        Register-ObjectEvent $watcher $_ -Action $action -MessageData @{ action = $action; cmd = $cmd; loop = $loop }
    }
    if (!$nowait) {
        try {
            while ($true) { Start-Sleep 1 }
        }
        finally {
            Stop-Job $jobs
        }
    }
}


new-alias tp test-path
new-alias git-each invoke-giteach
new-alias gitr git-each
new-alias x1b write-controlchar
new-alias swt set-windowtitle
new-alias pin-totaskbar Install-TaskBarPinnedItem
new-alias killall stop-allprocesses
new-alias tee-filter split-output
new-alias any test-any
new-alias relmo reload-module
new-alias tcpping test-tcp
#new-alias is-admin test-isadmin
new-alias slack send-slack
new-alias watch-file Register-FileSystemWatcher 
new-alias watch watch-file
Export-ModuleMember -Function * -Cmdlet * -Alias *

