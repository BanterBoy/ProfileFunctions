<#
.SYNOPSIS
Unblocks a quarantined email message and releases it.

.DESCRIPTION
The Unblock-QuarantineMessage function unblocks a quarantined email message and releases it for further processing. It takes the Identity of the email as a mandatory parameter and allows specifying specific recipients to release the email to.

.PARAMETER Identity
The Identity parameter specifies the unique identifier of the email to release from quarantine.

.PARAMETER Recipients
The Recipients parameter allows specifying specific recipients to release the email to. If not provided, the email will be released to all recipients.

.INPUTS
None. You cannot pipe objects to Unblock-QuarantineMessage.

.OUTPUTS
System.Management.Automation.PSCustomObject. An object with the following properties:
- Status: The status of the release operation, which will be "Released".
- Identity: The Identity of the released email.

.NOTES
- The Unblock-QuarantineMessage function supports the ShouldProcess common parameter, allowing you to confirm the release operation before proceeding.
- For more information and examples, visit the GitHub repository: https://github.com/BanterBoy

.EXAMPLE
Unblock-QuarantineMessage -Identity "12345"
Unblocks the email with the Identity "12345" and releases it to all recipients.

.EXAMPLE
Unblock-QuarantineMessage -Identity "12345" -Recipients "user1@example.com", "user2@example.com"
Unblocks the email with the Identity "12345" and releases it only to the specified recipients.
#>
function Unblock-QuarantineMessage {
    [CmdletBinding(DefaultParameterSetName = 'Default', 
        SupportsShouldProcess = $true,
        HelpUri = 'https://github.com/BanterBoy')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'Default', 
            Mandatory = $true, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true, 
            HelpMessage = 'Enter the Identity of the email to release')]
        [string]$Identity,
        
        [Parameter(ParameterSetName = 'Default', 
            Mandatory = $false, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true, 
            HelpMessage = 'Enter specific recipients to release the email to')]
        [string[]]$Recipients
    )

    process {
        if ($PSCmdlet.ShouldProcess($Identity, "Release quarantine message")) {
            try {
                if ($Recipients) {
                    Release-QuarantineMessage -Identity $Identity -User $Recipients
                }
                else {
                    Release-QuarantineMessage -Identity $Identity -ReleaseToAll
                }
                [PSCustomObject]@{
                    Status   = "Released"
                    Identity = $Identity
                }
            }
            catch {
                Write-Error "Failed to release email with Identity $Identity. Error: $_"
            }
        }
    }
}