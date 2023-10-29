function Get-TargetGPResult {
	<#
	.SYNOPSIS
		Retrieves the Resultant Set of Policy (RSoP) information for a target user and computer.
	
	.DESCRIPTION
		The Get-TargetGPResult function connects to a remote system and retrieves the RSoP information for a specified user. The results are saved to an HTML file.
	
	.PARAMETER ComputerName
		The name of the remote system to connect to.
	
	.PARAMETER TargetUser
		The SamAccountName of the user for which to retrieve RSoP data.
	
	.PARAMETER Path
		The file path where the exported report will be saved. Defaults to "C:\Temp\".
	
	.PARAMETER FileName
		The filename for the report. Defaults to "GPReport.html".
	
	.EXAMPLE
		Get-TargetUserGPResult -ComputerName 'value1' -TargetUser 'value2'
	
	.EXAMPLE
		$Params = @{  
			ComputerName = 'COMPUTERNAME'
			TargetUser = 'UserName'
			Path = 'D:\'
			FileName = 'Test.html'
		}
		Get-TargetUserGPResult @params

	.OUTPUTS
		System.String
	
	.NOTES
		This function requires the GPResult command line tool.
	#>
	
	[CmdletBinding(DefaultParameterSetName = 'Default',
		PositionalBinding = $true,
		SupportsShouldProcess = $true)]
	[OutputType([string], ParameterSetName = 'Default')]
	param
	(
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $true,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			Position = 0,
			HelpMessage = 'Enter the Name for the computer source')]
		[ValidateNotNullOrEmpty()]
		[string[]]$ComputerName,
		
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $true,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			Position = 1,
			HelpMessage = 'Enter the SamAccountName for the user')]
		[ValidateNotNullOrEmpty()]
		[string]$TargetUser,
		
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			Position = 2,
			HelpMessage = 'Enter the file path for the exported report')]
		[string]$Path = $Env:TEMP,
		
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			Position = 3,
			HelpMessage = 'Enter the filename for the report')]
		[string]$FileName = "GPReport.html",
		
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			Position = 4,
			HelpMessage = 'Enter the scope for the report')]
		[ValidateSet('USER', 'COMPUTER')]
		[string]$Scope = "USER"
	)
	
	Begin {
	}
	
	Process {
		ForEach ($Computer In $ComputerName) {
			if ($PSCmdlet.ShouldProcess("$($Computer)", "Export GPResult for User: $($TargetUser)")) {
				try {
					$Date = (Get-Date).ToString("yyyyMMdd-HHmmss")
					GPRESULT /S $Computer /SCOPE $Scope /USER $TargetUser /H $Path\$Date-$Computer-$FileName
				}
				catch {
					Write-Error -Message "Error exporting GPResult for User: $($TargetUser) on Computer: $($Computer). Error: $($_.Exception.Message)"
				}
				finally {
					Write-Output "GPResult exported to $($Path)$($Date)-$($Computer)-$($FileName)"
				}
			}
		}
	}
	
	End {
	}
}