# Ensure the ExchangeOnlineManagement module is installed
Install-Module -Name ExchangeOnlineManagement -Force

# Connect to Exchange Online
Connect-ExchangeOnline -UserPrincipalName <your-admin-username> -ShowProgress $true

# Load custom format data
Update-FormatData -PrependPath .\QuarantineEmail.Format.ps1xml

# Function to list quarantined emails with filtering options
function Get-QuarantinedEmails {
    [CmdletBinding()]
    param (
        [string[]]$Recipient,
        [string]$Sender,
        [string]$Subject,
        [datetime]$StartReceivedDate,
        [datetime]$EndReceivedDate,
        [int]$PageSize = 100,
        [int]$Page = 1,
        [ValidateSet("Bulk", "HighConfPhish", "Malware", "Phish", "Spam", "SPOMalware", "TransportRule")]
        [string[]]$QuarantineTypes
    )

    # Initialize filter parameters
    $filterParams = @{}
    if ($Recipient) { $filterParams['RecipientAddress'] = $Recipient }
    if ($Sender) { $filterParams['SenderAddress'] = $Sender }
    if ($Subject) { $filterParams['Subject'] = $Subject }
    if ($StartReceivedDate) { $filterParams['StartReceivedDate'] = $StartReceivedDate }
    if ($EndReceivedDate) { $filterParams['EndReceivedDate'] = $EndReceivedDate }
    if ($PageSize) { $filterParams['PageSize'] = $PageSize }
    if ($Page) { $filterParams['Page'] = $Page }
    if ($QuarantineTypes) { $filterParams['QuarantineTypes'] = $QuarantineTypes }

    Write-Verbose "Starting to retrieve quarantined emails with the following filters: $filterParams"

    # Retrieve quarantined emails
    try {
        $quarantinedEmails = Get-QuarantineMessage @filterParams
        Write-Verbose "Retrieved $(($quarantinedEmails).Count) quarantined emails."
    }
    catch {
        Write-Error "Failed to retrieve quarantined emails. Error: $_"
        return
    }

    # Select relevant information
    $emailInfo = $quarantinedEmails | Select-Object ReceivedTime, Type, SenderAddress, RecipientAddress, Subject, Size, Expires
    Write-Verbose "Filtered email information ready for output."

    return $emailInfo
}

# Function to release quarantined email by MessageId
function Release-QuarantinedEmail {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MessageId
    )

    Write-Verbose "Attempting to release email with MessageId: $MessageId"

    try {
        Release-QuarantineMessage -Identity $MessageId -ReleaseToAllRecipients
        Write-Output "Message with ID $MessageId has been released successfully."
    }
    catch {
        Write-Error "Failed to release message with ID $MessageId. Error: $_"
    }
}

# Example usage to list quarantined emails for specific recipients with optional filters
$Recipients = @("user1@example.com", "user2@example.com")
$Sender = "specific.sender@example.com"
$Subject = "Important Subject"
$StartReceivedDate = Get-Date "2024-06-01"
$EndReceivedDate = Get-Date "2024-06-09"
$PageSize = 50
$Page = 1
$QuarantineTypes = @("Spam", "Phish")

$quarantinedEmails = Get-QuarantinedEmails -Recipient $Recipients -Sender $Sender -Subject $Subject -StartReceivedDate $StartReceivedDate -EndReceivedDate $EndReceivedDate -PageSize $PageSize -Page $Page -QuarantineTypes $QuarantineTypes -Verbose

# Display the quarantined emails in a table format
$quarantinedEmails | Format-Table -AutoSize

# Example usage to release a specific email
# Replace 'example-message-id' with the actual MessageId
$MessageId = "example-message-id"
Release-QuarantinedEmail -MessageId $MessageId -Verbose
