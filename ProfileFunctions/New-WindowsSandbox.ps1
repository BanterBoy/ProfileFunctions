function New-WindowsSandbox {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Please enter the full path to the profile, including the filename.'
        )]
        [string]
        $ProfilePath = $PROFILE
    )

    # include the powershell script
    . 'C:\GitRepos\Windows-Sandbox\Start-WindowsSandbox.ps1'
    Start-WindowsSandbox -Memory 8  -NotepadPlusPlus -ReadWriteMappings @('C:\Temp\', 'C:\GitRepos\') -CopyPsProfile -CustomPsProfilePath $ProfilePath
}
