function Update-ModulePSM1 {

    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Please enter the directory path to create your PSM1 file."
        )]
        [string]
        $FilePath
    )

    $ModuleName = $path.Parent.name[0]

    $Scripts = Get-ChildItem -Path $FilePath\Public -File | Select-Object -Property FullName
    Remove-Item -Path $FilePath\$ModuleName.psm1

    foreach ( $Script in $Scripts) {
        $Content = Get-Content -Path "$($Script.fullname)"
        Add-Content -Path $FilePath\$ModuleName.psm1 -Value $Content
    }
}
