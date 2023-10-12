<#
.SYNOPSIS
    Tests if a folder exists at the specified path. Returns $true if the folder exists, $false otherwise.
    If the -Create switch is used and the folder does not exist, it will be created.

.DESCRIPTION
    The Test-FolderExists function uses the Test-Path cmdlet to check if a folder exists at a given path.
    If the folder exists, it returns $true.
    If the folder does not exist, it returns $false.
    If the -Create switch is used and the folder does not exist, the function will create the folder.

.PARAMETER Path
    Specifies the path to the folder to be tested. This parameter is mandatory.

.PARAMETER Create
    If this switch is used and the folder specified by the Path parameter does not exist, the function will create the folder.

.EXAMPLE
    Test-FolderExists -Path "C:\Temp"
    This command tests if a folder exists at the path C:\Temp and returns $true or $false.

.EXAMPLE
    Test-FolderExists -Path "C:\Temp" -Create
    This command tests if a folder exists at the path C:\Temp. If the folder does not exist, it will be created.

.EXAMPLE
    Test-FolderExists -Path "C:\Temp" -Verbose
    This command tests if a folder exists at the path C:\Temp, returns $true or $false, and displays verbose output.

.INPUTS
    System.String
    You can pipe a string that contains a path to Test-FolderExists.

.OUTPUTS
    System.Boolean
    If the folder exists, Test-FolderExists returns $true. If the folder does not exist, it returns $false.

.NOTES
    Author: Unknown
    Last Edit: Unknown
#>
function Test-FolderExists {
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true
    )]
    param
    (
        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $true,
            Position = 1,
            HelpMessage = 'Enter the file path to test.'
        )]
        [string]
        $Path,

        [Parameter(
            ParameterSetName = 'Default'
        )]
        [switch]
        $Create
    )
    PROCESS {
        if ($PSCmdlet.ShouldProcess("$Path", "Testing this path...")) {
            $folderExists = Test-Path $Path -PathType Container
            if ($folderExists) {
                Write-Verbose -Message "Folder Exists."
            }
            else {
                Write-Verbose -Message "Folder does not exist."
                if ($Create) {
                    New-Item -ItemType Directory -Path $Path | Out-Null
                    Write-Verbose -Message "Folder created."
                    $folderExists = $true
                }
            }
            return $folderExists
        }
    }
}