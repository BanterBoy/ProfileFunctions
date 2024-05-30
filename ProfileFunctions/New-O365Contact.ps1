# Create New Contacts in Office 365 from a CSV file conataining PrimarySMTPAddress
# The function should accept a parameter of EmailAddress and create a new contact in Office 365
# It should parse the email address and create the values for Name, DisplayName, and Alias from the email address
# The can be used when connected to exhange online or exchange on-premises and should be able to handle both
# The function should create the new contacts in Office 365 using the New-MailContact cmdlet
# The function should accept piped input
# The function should return the new contact object
# The function should handle errors and return a custom error message
# The function should have a comment-based help

function New-O365Contact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$EmailAddress
    )
    process {
        try {
            $Name = $EmailAddress.Split('@')[0]
            $DisplayName = $Name
            $Alias = $Name
            $Contact = New-MailContact -Name $Name -DisplayName $DisplayName -Alias $Alias -ExternalEmailAddress $EmailAddress -WhatIf
            $Contact
        }
        catch {
            Write-Host "Failed to create contact for $EmailAddress"
        }
    }
}
