function Get-ComputerIP {

    <#
    .SYNOPSIS
    Tests computer for connection and lists status with IP address.
    .DESCRIPTION
    Tests computer for connection and lists status with IP address.
    .PARAMETER server
    Name of server to test connection to.
    .PARAMETER file
    Name of host file to test connection to.
    .PARAMETER credential
    Allows the use of alternate credentials, if required.
    .NOTES
    Name: Get-ComputerIP.ps1
    Author: Boe Prox
    DateCreated: 05Aug2010

    .LINK 
    http://
    .EXAMPLE
    Get-ComputerIP

    #>
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
    $report

}
