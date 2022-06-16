Function Get-FileAndFolderPermissions {
	<#
		.SYNOPSIS
			Get-FileAndFolderPermissions can be used to extract file or folder permissions for a given path.
		
		.DESCRIPTION
			Get-FileAndFolderPermissions can be used to extract file or folder permissions for a given path. You can choose between 'File' or 'Folder' permissions and you can choose whther or not to recurse through the folder structure of the given path.
		
		.PARAMETER SourcePath
			Enter the path for the folder that you would like to extract the permissions.
		
		.PARAMETER FileFolder
			Specify whether you would like to get 'File' or 'Folder' permissions. The Default is Folder permissions.
		
		.PARAMETER Recurse
			 Specify whether you would like to recurse the folder structure for permissions. The Default is disabled.
		
		.EXAMPLE
			PS C:\> Get-FileAndFolderPermissions

		.EXAMPLE
			PS C:\> Get-FileAndFolderPermissions -SourcePath C:\
	
		.EXAMPLE
			PS C:\> Get-FileAndFolderPermissions -SourcePath C:\ -Recurse true

		.OUTPUTS
			object
		
		.NOTES
			Author:     Luke Leigh
			Website:    https://scripts.lukeleigh.com/
			LinkedIn:   https://www.linkedin.com/in/lukeleigh/
			GitHub:     https://github.com/BanterBoy/
			GitHubGist: https://gist.github.com/BanterBoy
	
		.LINK
			https://github.com/BanterBoy/scripts-blog
			Get-Childitem
			Get-Acl
			New-Object
			Where-Object
			ForEach-Object
			Write-Warning
			Write-Output
	#>
	
	[CmdletBinding(DefaultParameterSetName = 'Default',
		ConfirmImpact = 'Medium',
		PositionalBinding = $true,
		SupportsShouldProcess = $true)]
	[Alias('GFPR')]
	[OutputType([object], ParameterSetName = 'Default')]
	Param
	(
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			Position = 1,
			HelpMessage = 'Enter the directory string that you want to search. Default is the current directory.')]
		[Alias('sp')]
		[String]$SourcePath = ".",

		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipelineByPropertyName = $true,
			Position = 2,
			HelpMessage = 'Specify whether you want to search for files or folders. Default is folders.')]
		[ValidateSet('File', 'Folder')]
		[Alias('ff')]
		[string]$FileFolder = 'Folder',
		
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipelineByPropertyName = $true,
			Position = 3,
			HelpMessage = 'When enabled, this will recurse through all the subfolders. Default is disabled.')]
		[ValidateSet('true', 'false')]
		[Alias('rec')]
		[string]$Recurse = 'false',
        
		[Parameter(
			Mandatory = $false,
			Position = 4,
			ParameterSetName = "Default",
			ValueFromPipelineByPropertyName,
			HelpMessage = "Select the file extension you are looking for. Defaults to '*.*' files.")]
		[ValidateSet('.AIFF', '.AIF', '.AU', '.AVI', '.BAT', '.BMP', '.CHM', '.CLASS', '.CONFIG', '.CSS', '.CSV', '.CVS', '.DBF', '.DIF', '.DOC', '.DOCX', '.DLL', '.DOTX', '.EPS', '.EXE', '.FM3', '.GIF', '.HQX', '.HTM', '.HTML', '.ICO', '.INF', '.INI', '.JAVA', '.JPG', '.JPEG', '.JSON', '.LOG', '.MD', '.MP4', '.MAC', '.MAP', '.MDB', '.MID', '.MIDI', '.MKV', '.MOV', '.QT', '.MTB', '.MTW', '.PDB', '.PDF', '.P65', '.PNG', '.PPT', '.PPTX', '.PSD', '.PSP', '.PS1', '.PSD1', '.PSM1', '.QXD', '.RA', '.RTF', '.SIT', '.SVG', '.TAR', '.TIF', '.T65', '.TXT', '.VBS', '.VSDX', '.WAV', '.WK3', '.WKS', '.WPD', '.WP5', '.XLS', '.XLSX', '.XML', '.YML', '.ZIP', '.*') ]
		[string]$Extension = '*.*'
	)
	
	Begin {
		
	}
	
	Process {
		Switch ($Recurse) {
			true {
				If ($pscmdlet.ShouldProcess("$SourcePath", "Extracting for permissions")) {
					if ($FileFolder = 'File') {
						$fileType = '*' + $Extension
						$Search = Get-ChildItem $SourcePath -Recurse | Where-Object {
							($_.psiscontainer -eq $false) -And ($_.FullName -Match $fileType)
						}
					}
					ElseIf ($FileFolder -eq 'Folder') {
						$Search = Get-ChildItem $SourcePath | Where-Object {
							$_.psiscontainer -eq $true
						}
					}
					ForEach ($item In $Search) {
						$ACLs = Get-Acl $item.fullname | ForEach-Object {
							$_.Access
						}
						Try {
							ForEach ($ACL In $ACLs) {
								$OutInfo = @{
									Fullname          = $item.Fullname
									IdentityReference = $ACL.IdentityReference
									AccessControlType = $ACL.AccessControlType
									IsInherited       = $ACL.IsInherited
									InheritanceFlags  = $ACL.InheritanceFlags
									PropagationFlags  = $ACL.PropagationFlags
								}
								$obj = New-Object -TypeName PSObject -Property $OutInfo
								Write-Output $obj
							}
						}
						Catch {
							Write-Warning "$_"
						}
					}
				}
			}
			false {
				If ($pscmdlet.ShouldProcess("$SourcePath", "Extracting for permissions")) {
					if ($FileFolder = 'File') {
						$fileType = '*' + $Extension
						$Search = Get-ChildItem $SourcePath -Recurse | Where-Object {
							($_.psiscontainer -eq $false) -And ($_.FullName -Match $fileType)
						}
					}
					ElseIf ($FileFolder -eq 'Folder') {
						$Search = Get-ChildItem $SourcePath | Where-Object {
							$_.psiscontainer -eq $true
						}
					}
					ForEach ($item In $Search) {
						$ACLs = Get-Acl $item.fullname | ForEach-Object {
							$_.Access
						}
						Try {
							ForEach ($ACL In $ACLs) {
								$OutInfo = @{
									Fullname          = $item.Fullname
									IdentityReference = $ACL.IdentityReference
									AccessControlType = $ACL.AccessControlType
									IsInherited       = $ACL.IsInherited
									InheritanceFlags  = $ACL.InheritanceFlags
									PropagationFlags  = $ACL.PropagationFlags
								}
								$obj = New-Object -TypeName PSObject -Property $OutInfo
								Write-Output $obj
							}
						}
						Catch {
							Write-Warning "$_"
						}
					}
				}
			}
			Default {
				If ($pscmdlet.ShouldProcess("$SourcePath", "Extracting for permissions")) {
					$Folders = Get-ChildItem $SourcePath | Where-Object {
						$_.psiscontainer -eq $true
					}
					ForEach ($Folder In $Folders) {
						$ACLs = Get-Acl $Folder.FullName | ForEach-Object {
							$_.Access
						}
						Try {
							ForEach ($ACL In $ACLs) {
								$OutInfo = @{
									Fullname          = $Folder.Fullname
									IdentityReference = $ACL.IdentityReference
									AccessControlType = $ACL.AccessControlType
									IsInherited       = $ACL.IsInherited
									InheritanceFlags  = $ACL.InheritanceFlags
									PropagationFlags  = $ACL.PropagationFlags
								}
								$obj = New-Object -TypeName PSObject -Property $OutInfo
								Write-Output $obj
							}
						}
						Catch {
							Write-Warning "$_"
						}
					}
				}
				
			}
		}
	}
	End {
		Write-Verbose "Search for files completed."
	}
}
