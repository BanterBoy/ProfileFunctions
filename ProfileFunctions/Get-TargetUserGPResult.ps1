function Get-TargetUserGPResult
{
<#
	.SYNOPSIS
		A brief description of the Get-TargetUserGPResult function.
	
	.DESCRIPTION
		A detailed description of the Get-TargetUserGPResult function.
		
		GPRESULT [/S system [/U username [/P [password]]]] [/SCOPE scope] [/USER targetusername] [/R | /V | /Z] [(/X | /H) <filename> [/F]]
		Description:
		This command line tool displays the Resultant Set of Policy (RSoP) information for a target user and computer.
		Parameter List:
		/S        system           Specifies the remote system to connect to.
		/U        [domain\]user    Specifies the user context under which the command should run. Can not be used with /X, /H.
		/P        [password]       Specifies the password for the given user context. Prompts for input if omitted. Cannot be used with /X, /H.
		/SCOPE    scope            Specifies whether the user or the computer settings need to be displayed. Valid values: "USER", "COMPUTER".
		/USER     [domain\]user    Specifies the user name for which the RSoP data is to be displayed.
		/X        <filename>       Saves the report in XML format at the location and with the file name specified by the <filename> parameter. (valid in Windows Vista SP1 and later and Windows Server 2008 and later)
		/H        <filename>       Saves the report in HTML format at the location and with the file name specified by the <filename> parameter. (valid in Windows at least Vista SP1 and at least Windows Server 2008)
		/F                         Forces Gpresult to overwrite the file name specified in the /X or /H command.
		/R                         Displays RSoP summary data.
		/V                         Specifies that verbose information should be displayed. Verbose information provides additional detailed settings that have been applied with a precedence of 1.
		/Z                         Specifies that the super-verbose information should be displayed. Super-verbose information provides additional detailed settings that have been applied with a precedence of 1 and higher. This allows you to see if a setting was set in multiple places. See the Group Policy online help topic for more information.
		/?                         Displays this help message.
		Examples:
		GPRESULT /R
		GPRESULT /H GPReport.html
		GPRESULT /USER targetusername /V
		GPRESULT /S system /USER targetusername /SCOPE COMPUTER /Z
		GPRESULT /S system /U username /P password /SCOPE USER /V
	
	.PARAMETER ComputerName
		A description of the ComputerName parameter.
	
	.PARAMETER TargetUser
		A description of the TargetUser parameter.
	
	.PARAMETER Path
		A description of the Path parameter.
	
	.PARAMETER FileName
		A description of the FileName parameter.
	
	.EXAMPLE
		PS C:\> Get-TargetUserGPResult -ComputerName 'value1' -TargetUser 'value2'
	
	.OUTPUTS
		System.String
	
	.NOTES
		Additional information about the function.
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
		[string[]]$ComputerName,
		[Parameter(ParameterSetName = 'Default',
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 1,
				   HelpMessage = 'Enter the SamAccountName for the user')]
		[string]$TargetUser,
		[Parameter(ParameterSetName = 'Default',
				   Mandatory = $false,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 2,
				   HelpMessage = 'Enter the file path for the exported report')]
		[string]$Path = "C:\Temp\",
		[Parameter(ParameterSetName = 'Default',
				   Mandatory = $false,
				   Position = 3,
				   HelpMessage = 'Enter the filename for the report')]
		[string]$FileName = "GPReport.html"
	)
	
	Begin
	{
	}
	
	Process
	{
		if ($PSCmdlet.ShouldProcess("$($Computer)", "Export GPResult for User."))
		{
			ForEach ($Computer In $ComputerName)
			{
				try
				{
					$Date = (Get-Date).ToString("yyyyMMddHHmmss")
					GPRESULT /S $Computer /SCOPE USER /USER $TargetUser /H $Path\$Date-$Computer-$FileName
				}
				catch
				{
					Write-Error -Message "Error: $($_.Exception.Message)"
				}
			}
		}
	}
	
	End
	{
	}
}
