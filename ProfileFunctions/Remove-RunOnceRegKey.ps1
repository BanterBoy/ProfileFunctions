function Remove-RunOnceRegKey {
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
        $Credential,
        [Parameter(Mandatory = $true)]
        [string]$KeyName
    )

    $scriptBlock = {
        param($KeyName)
        $path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        try {
            Get-ItemProperty -Path $path -Name $KeyName -ErrorAction Stop
            Remove-ItemProperty -Path $path -Name $KeyName
        } catch {
            Write-Output "Key $KeyName does not exist."
        }
    }

    foreach ($Computer in $ComputerName) {
        if ($Credential) {
            Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock $scriptBlock -ArgumentList $KeyName
        } else {
            Invoke-Command -ComputerName $Computer -ScriptBlock $scriptBlock -ArgumentList $KeyName
        }
    }
}