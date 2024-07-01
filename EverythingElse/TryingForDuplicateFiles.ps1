# function Get-Files {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$Path,
#         [Parameter(Mandatory = $true)]
#         [string]$Extension,
#         [switch]$Recurse
#     )

#     $ChildItemParams = @{
#         LiteralPath = $Path
#         File        = $true
#         Recurse     = $Recurse.IsPresent
#         Filter      = "*$($Extension)"
#     }

#     Get-ChildItem @ChildItemParams | Select-Object -Property FullName, Name, Length, LastWriteTime, Extension, DirectoryName
# }

# function Compare-Files {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [array]$SourceFiles,
#         [Parameter(Mandatory = $true)]
#         [array]$DestinationFiles
#     )

#     Compare-Object -ReferenceObject $SourceFiles -DifferenceObject $DestinationFiles -Property Name -PassThru | ForEach-Object {
#         if ($_.SideIndicator -ne '==') {
#             $_ | Add-Member -MemberType NoteProperty -Name IsDuplicate -Value $false -Force -PassThru
#         }
#         else {
#             $_ | Add-Member -MemberType NoteProperty -Name IsDuplicate -Value $true -Force -PassThru
#         }
#     } | Where-Object { $_.IsDuplicate }
# }

# function Remove-Files {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [array]$Files,
#         [switch]$Delete
#     )

#     if ($Delete.IsPresent) {
#         $Files | Remove-Item -Force
#     }

#     $Files
# }

# function Find-DuplicateFiles {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$SourcePath,
#         [Parameter(Mandatory = $true)]
#         [string]$DestinationPath,
#         [Parameter(Mandatory = $true)]
#         [string]$SourceExtension,
#         [Parameter(Mandatory = $true)]
#         [string]$DestinationExtension,
#         [switch]$Recurse
#     )

#     begin {
#         Write-Verbose -Message "Starting processing of $($SourcePath) files with extension $($SourceExtension) and $($DestinationPath) files with extension $($DestinationExtension)"
#     }

#     process {
#         $SourceFiles = Get-Files -Path $SourcePath -Extension $SourceExtension -Recurse:$Recurse
#         $DestinationFiles = Get-Files -Path $DestinationPath -Extension $DestinationExtension -Recurse:$Recurse

#         $DuplicateFiles = Compare-Files -SourceFiles $SourceFiles -DestinationFiles $DestinationFiles

#         $DuplicateFiles | Select-Object -Property FullName, Name, Length, LastWriteTime, Extension, DirectoryName, @{Name = 'IsDuplicate'; Expression = { $_.IsDuplicate } }, @{Name = 'SideIndicator'; Expression = { $_.SideIndicator -replace '==', 'Duplicate' } }
#     }

#     end {
#         Write-Verbose -Message "Finished processing of $($SourcePath) files with extension $($SourceExtension) and $($DestinationPath) files with extension $($DestinationExtension)"
#     }
# }