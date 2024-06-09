<#
.SYNOPSIS
    Retrieves and displays quarantined emails based on specified filters.

.DESCRIPTION
    The Get-QuarantinedEmailMessages function retrieves quarantined emails from a quarantine system based on specified filters such as recipient, sender, subject, received date, page size, page number, and quarantine types. It uses the QuarantinedEmailManager class to manage the filters and retrieve the emails.

.PARAMETER Recipient
    Specifies the recipient email addresses to filter the quarantined emails. Multiple recipients can be specified by providing an array of email addresses.

.PARAMETER EmailSender
    Specifies the sender email address to filter the quarantined emails. Wildcards (*) can be used to match any characters before and after the specified sender address.

.PARAMETER Subject
    Specifies the subject of the quarantined emails to filter. Wildcards (*) can be used to match any characters before and after the specified subject.

.PARAMETER StartReceivedDate
    Specifies the start date of the received time range to filter the quarantined emails. Only emails received on or after this date will be included.

.PARAMETER EndReceivedDate
    Specifies the end date of the received time range to filter the quarantined emails. Only emails received on or before this date will be included.

.PARAMETER PageSize
    Specifies the number of quarantined emails to retrieve per page. The default value is 100.

.PARAMETER Page
    Specifies the page number of the quarantined emails to retrieve. The default value is 1.

.PARAMETER QuarantineTypes
    Specifies the types of quarantined emails to filter. Valid values are "Bulk", "HighConfPhish", "Malware", "Phish", "Spam", "SPOMalware", and "TransportRule". Multiple types can be specified by providing an array of values.

.EXAMPLE
    $Recipients = @("user1@example.com", "user2@example.com")
    $EmailSender = "specific.sender@example.com"
    $Subject = "Important Subject"
    $StartReceivedDate = Get-Date "2024-06-01"
    $EndReceivedDate = Get-Date "2024-06-09"
    $PageSize = 50
    $Page = 1
    $QuarantineTypes = @("Spam", "Phish")

    Get-QuarantinedEmailMessages -Recipient $Recipients -EmailSender $EmailSender -Subject $Subject -StartReceivedDate $StartReceivedDate -EndReceivedDate $EndReceivedDate -PageSize $PageSize -Page $Page -QuarantineTypes $QuarantineTypes -Verbose

    Retrieves and displays quarantined emails for the specified recipients, sender, subject, received date range, page size, page number, and quarantine types. The verbose output is enabled to provide additional information during the retrieval process.

.EXAMPLE
    Get-QuarantinedEmailMessages -Recipient "user1@example.com" -EmailSender "specific.sender@example.com"

    Retrieves and displays quarantined emails for the specified recipient and sender.

.EXAMPLE
    Get-QuarantinedEmailMessages -Recipient "user1@example.com" -Subject "Important Subject" -QuarantineTypes "Spam"

    Retrieves and displays quarantined emails for the specified recipient, subject, and quarantine type.

.EXAMPLE
    $StartReceivedDate = Get-Date "2024-06-01"
    $EndReceivedDate = Get-Date "2024-06-09"
    Get-QuarantinedEmailMessages -Recipient "user1@example.com" -StartReceivedDate $StartReceivedDate -EndReceivedDate $EndReceivedDate

    Retrieves and displays quarantined emails for the specified recipient and received date range.

.EXAMPLE
    Get-QuarantinedEmailMessages -Recipient "user1@example.com" -PageSize 50 -Page 2

    Retrieves and displays quarantined emails for the specified recipient, page size, and page number.

.EXAMPLE
    $Recipients = @("user1@example.com", "user2@example.com")
    $QuarantineTypes = @("Spam", "Phish")
    Get-QuarantinedEmailMessages -Recipient $Recipients -QuarantineTypes $QuarantineTypes

    Retrieves and displays quarantined emails for the specified recipients and quarantine types.

.NOTES
    This code assumes the existence of a Get-QuarantineMessage function that retrieves quarantined emails based on the provided filters. The QuarantinedEmail and QuarantinedEmailManager classes are defined to manage and represent the quarantined emails.

.LINK
    https://example.com/quarantine-system-documentation
#>

function Get-QuarantinedEmailMessages {
    [CmdletBinding(DefaultParameterSetName = 'Default', 
        SupportsShouldProcess = $true,
        HelpUri = 'https://github.com/BanterBoy')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'Default', 
            Mandatory = $false, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true, 
            HelpMessage = 'Enter recipient email addresses')]
        [string[]]$Recipient,
        
        [Parameter(ParameterSetName = 'Default', 
            Mandatory = $false, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true, 
            HelpMessage = 'Enter email sender address')]
        [string]$EmailSender,
        
        [Parameter(ParameterSetName = 'Default', 
            Mandatory = $false, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true, 
            HelpMessage = 'Enter email subject')]
        [string]$Subject,
        
        [Parameter(ParameterSetName = 'Default', 
            Mandatory = $false, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true, 
            HelpMessage = 'Enter start received date')]
        [datetime]$StartReceivedDate,
        
        [Parameter(ParameterSetName = 'Default', 
            Mandatory = $false, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true, 
            HelpMessage = 'Enter end received date')]
        [datetime]$EndReceivedDate,
        
        [Parameter(ParameterSetName = 'Default', 
            Mandatory = $false, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true, 
            HelpMessage = 'Enter page size')]
        [int]$PageSize = 100,
        
        [Parameter(ParameterSetName = 'Default', 
            Mandatory = $false, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true, 
            HelpMessage = 'Enter page number')]
        [int]$Page = 1,
        
        [Parameter(ParameterSetName = 'Default', 
            Mandatory = $false, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true, 
            HelpMessage = 'Enter quarantine types')]
        [ValidateSet("Bulk", "HighConfPhish", "Malware", "Phish", "Spam", "SPOMalware", "TransportRule")]
        [string[]]$QuarantineTypes,

        [Parameter(ParameterSetName = 'Default', 
            Mandatory = $false, 
            HelpMessage = 'Show only released emails')]
        [switch]$Released
    )

    $filterParams = @{}
    if ($Recipient) { $filterParams['RecipientAddress'] = $Recipient }
    if ($EmailSender) { $filterParams['SenderAddress'] = $EmailSender }
    if ($Subject) { $filterParams['Subject'] = $Subject }
    if ($StartReceivedDate) { $filterParams['StartReceivedDate'] = $StartReceivedDate }
    if ($EndReceivedDate) { $filterParams['EndReceivedDate'] = $EndReceivedDate }
    if ($PageSize) { $filterParams['PageSize'] = $PageSize }
    if ($Page) { $filterParams['Page'] = $Page }
    if ($QuarantineTypes) { $filterParams['QuarantineTypes'] = $QuarantineTypes }

    Write-Verbose "Starting to retrieve quarantined emails with the following filters: $($filterParams | Out-String)"

    if ($PSCmdlet.ShouldProcess("Quarantine messages", "Retrieve quarantine messages")) {
        try {
            $quarantinedEmails = Get-QuarantineMessage @filterParams
            Write-Verbose "Retrieved $($quarantinedEmails.Count) quarantined emails."
        }
        catch {
            Write-Error "Failed to retrieve quarantined emails. Error: $_"
            return
        }

        $emailInfo = $quarantinedEmails | Select-Object -Property ReceivedTime, Type, SenderAddress, RecipientAddress, Subject, Size, Expires, Identity, Released

        # Filter by release status if the Released switch is specified
        if ($Released) {
            $emailInfo = $emailInfo | Where-Object { $_.Released -eq $true }
        }

        Write-Verbose "Filtered email information ready for output."

        return $emailInfo | ForEach-Object {
            [PSCustomObject]@{
                ReceivedTime     = $_.ReceivedTime
                Type             = $_.Type
                SenderAddress    = $_.SenderAddress
                RecipientAddress = ($_.RecipientAddress -join ', ')
                Subject          = $_.Subject
                Size             = $_.Size
                Expires          = $_.Expires
                Identity         = $_.Identity
                Released         = $_.Released
            }
        }
    }
}
