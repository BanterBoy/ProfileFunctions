function Set-OOHMessage {

    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Scheduled')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Identity,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Enabled", "Disabled", "Scheduled")]
        [string]$AutoReplyState,
        [Parameter(Mandatory = $true, ParameterSetName = 'Enabled')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Scheduled')]
        [ValidateNotNullOrEmpty()]
        [string]$InternalMessage,
        [Parameter(Mandatory = $true, ParameterSetName = 'Enabled')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Scheduled')]
        [ValidateNotNullOrEmpty()]
        [string]$ExternalMessage,
        [Parameter(Mandatory = $true, ParameterSetName = 'Scheduled')]
        [datetime]$StartTime,
        [Parameter(Mandatory = $true, ParameterSetName = 'Scheduled')]
        [datetime]$EndTime
    )

    process {
  
        if ($PSCmdlet.ShouldProcess($Identity, "Set AutoReplyState to $AutoReplyState")) {
            try {
                Set-MailboxAutoReplyConfiguration -Identity $Identity -AutoReplyState $AutoReplyState -InternalMessage $InternalMessage -ExternalMessage $ExternalMessage -StartTime $StartTime -EndTime $EndTime
            }
            catch {
                Write-Error "Failed to set auto-reply configuration: $_"
            }
        }

    }

}

# Without Schedule (Default Parameter Set):
# Set-OOHMessage -Identity "user@example.com" -AutoReplyState "Enabled" -InternalMessage "I am out of office" -ExternalMessage "I am out of office"

# Scheduled:
# Set-OOHMessage -Identity "user@example.com" -AutoReplyState "Scheduled" -InternalMessage "I am out of office" -ExternalMessage "I am out of office" -StartTime (Get-Date).AddDays(1) -EndTime (Get-Date).AddDays(7)

# Disabled:
# Set-OOHMessage -Identity "user@example.com" -AutoReplyState "Disabled"