function Test-ContactEmail {
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        HelpUri = 'http://scripts.lukeleigh.com/')
    ]
    [OutputType([psobject])]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the email address to check.'
        )]
        [string]$EmailAddress
    )

    begin {
    }

    process {
        if ($PSCmdlet.ShouldProcess("Check email address '$EmailAddress'", "Search for mail contact")) {
            $results = @()
            try {
                $Contact = Get-MailContact -Anr $EmailAddress -ErrorAction Stop
                if ($Contact) {
                    $properties = [ordered]@{
                        Name                          = $Contact.Name
                        DisplayName                   = $Contact.DisplayName
                        Alias                         = $Contact.Alias
                        Email                         = $Contact.PrimarySmtpAddress
                        Type                          = $Contact.RecipientType
                        AddressListMembership         = $Contact.AddressListMembership
                        EmailAddresses                = $Contact.EmailAddresses
                        ExternalEmailAddress          = $Contact.ExternalEmailAddress
                        HiddenFromAddressListsEnabled = $Contact.HiddenFromAddressListsEnabled
                        PrimarySmtpAddress            = $Contact.PrimarySmtpAddress
                        WindowsEmailAddress           = $Contact.WindowsEmailAddress                        
                    }
                    $obj = New-Object PSObject -Property $properties
                    $results += $obj
                }
            }
            catch {
                Write-Error "Failed to retrieve on-premises mail contact: $_"
            }

            try {
                $EXOContact = Get-EXORecipient -Identity $EmailAddress -ErrorAction Stop
                if ($EXOContact) {
                    $properties = [ordered]@{
                        Name           = $EXOContact.Name
                        DisplayName    = $EXOContact.DisplayName
                        Alias          = $EXOContact.Alias
                        Email          = $EXOContact.PrimarySmtpAddress
                        Type           = $EXOContact.RecipientType
                        EmailAddresses = $EXOContact.EmailAddresses
                        TypeDetails    = $EXOContact.RecipientTypeDetails
                    }
                    $obj = New-Object PSObject -Property $properties
                    $results += $obj
                }
            }
            catch {
                Write-Error "Failed to retrieve Exchange Online mail contact: $($_.Error.Message)"
            }

            if ($results.Count -eq 0) {
                Write-Warning "No mail contact found for email address '$EmailAddress'"
            }
            else {
                Write-Output $results
            }
        }
    }

    end {
    }
}
