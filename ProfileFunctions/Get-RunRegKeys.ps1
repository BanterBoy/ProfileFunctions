function Get-RunRegKeys {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        supportsShouldProcess = $true,
        HelpUri = 'https://github.com/BanterBoy'
    )]
    [OutputType([string])]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter computer name or pipe input'
        )]
        [Alias('cn')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter computer name or pipe input'
        )]
        [Alias('cred')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    $scriptBlock = {
        $path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
        Get-ItemProperty -Path $path
    }

    foreach ($Computer in $ComputerName) {
        if ($Credential) {
            Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock $scriptBlock
        } else {
            Invoke-Command -ComputerName $Computer -ScriptBlock $scriptBlock
        }
    }
}
