function Get-ComputerIP {

    [cmdletbinding(
        SupportsShouldProcess = $True,
        DefaultParameterSetName = 'computer',
        ConfirmImpact = 'low'
    )]
    param(
        [Parameter(
            Mandatory = $False,
            ParameterSetName = 'computer',
            ValueFromPipeline = $True)]
        [string]$Computer,
        [Parameter(
            Mandatory = $False,
            ParameterSetName = 'file')]
        [string]$File,
        [Parameter(
            Mandatory = $False,
            ParameterSetName = '')]
        [switch]$credential
    )
    If ($File) {
        $Computers = Get-Content $File
    }
    Else {
        $Computers = $Computer
    }
    If ($credential) {
        $cred = Get-Credential
    }
    $report = @()
    ForEach ($Computer in $Computers) {
        if ($PSCmdlet.ShouldProcess("Target", "Operation")) {
            Try {
                $tempreport = New-Object PSObject
                If ($credential) {
                    $IP = ((Test-Connection -ErrorAction Stop -Count 1 -ComputerName $Computer -Credential $cred).IPV4Address).IPAddresstoString
                }
                Else {
                    $IP = ((Test-Connection -ErrorAction Stop -Count 1 -ComputerName $Computer).IPV4Address).IPAddresstoString
                }
                $tempreport | Add-Member NoteProperty Computer $Computer
                $tempreport | Add-Member NoteProperty Status “Up”
                $tempreport | Add-Member NoteProperty IP $IP
                $report += $tempreport
            }
            Catch {
                $tempreport = New-Object PSObject
                $tempreport | Add-Member NoteProperty Computer $Computer
                $tempreport | Add-Member NoteProperty Status “Down”
            }
        }
    }
    $report

}
