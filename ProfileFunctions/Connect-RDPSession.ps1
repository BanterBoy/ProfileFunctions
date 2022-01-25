function Connect-RDPSession {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        PositionalBinding = $true)]
    [OutputType([string], ParameterSetName = 'Default')]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            Position = 1)]
        [string[]]$ComputerName
    )

    foreach ($Computer in $ComputerName) {
            Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$Computer"
    }
}
