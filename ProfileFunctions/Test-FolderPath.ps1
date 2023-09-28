function Test-FolderExists {
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true
    )]
    param
    (
        <#
            Enter the file path to test. If folder does not exist, it will be created.
        #>
        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $true,
            Position = 1,
            HelpMessage = 'Enter the file path to test. If folder does not exist, it will be created.'
        )]
        [ValidateScript(
            {
                # Check if the From and To parameters are specified

                if (Test-Path $_ -PathType Container) {
                    $true
                    Write-Verbose -Message "Folder Exists."
                }
                else {
                    throw "Folder does not exist!"
                }
            }
        )]
        [string]
        $Path
    )
    BEGIN {
    }
    PROCESS {
        if ($PSCmdlet.ShouldProcess("$Path", "Testing this path...")) {
            if ($Path) {
                $Path
                Write-Verbose -Message "$($Path) - Folder Exists, yay!"
            }
        }
    }
    END {
    }
}
