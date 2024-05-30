Function Set-DigitalSignature {

    <#
	.SYNOPSIS
		Set-DigitalSignature can be used to set the digital signature of a file.
	
	.DESCRIPTION
		Set-DigitalSignature will extract the Digital Code Signing Certificate from your Personal Store and set it as the digital signature of the file.
	
	.PARAMETER Path
		This paramter is the path to the file you want to set the digital signature of.
	
	.EXAMPLE
        Set-DigitalSignature -Path C:\Users\Administrator\Desktop\UnsignedScript.ps1

        Extracts the digital signature from the Personal Store and sets it as the digital signature of the file.	
	.OUTPUTS
		string
	
	.NOTES
		Additional information about the function.
    #>
	
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        PositionalBinding = $true)]
    [OutputType([string], ParameterSetName = 'Default')]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Enter the path to the file to be signed.")]
        [string]
        $Path
    )
    $codesigningcert = @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]
    Set-AuthenticodeSignature -FilePath $Path -Certificate $codesigningcert
}
