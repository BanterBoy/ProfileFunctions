<#
.SYNOPSIS
Adds a member to a distribution group in Exchange.

.DESCRIPTION
The Add-MemberToGroup function adds a member to a distribution group in Exchange. It checks if the provided email address is a mail contact in your Exchange and if it is not already a member of the distribution group. If the email address is a duplicate, it logs the duplicate email and skips adding it to the group. The function also exports the logs to a CSV file.

.PARAMETER email
The email address of the member to be added to the distribution group.

.PARAMETER distributionGroupName
The name of the distribution group to which the member will be added.

.PARAMETER logPath
The path where the logs will be exported. If no path is provided, the logs will be exported to the Documents folder.

.EXAMPLE
Add-MemberToGroup -email "john.doe@example.com" -distributionGroupName "Sales Group" -logPath "C:\Logs"

This example adds the email address "john.doe@example.com" to the "Sales Group" distribution group and exports the logs to the "C:\Logs" folder.

.NOTES
Author: Your Name
Date: Today's Date
#>

function Add-MemberToGroup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$email,
        [Parameter(Mandatory = $true)]
        [string]$distributionGroupName,
        [Parameter(Mandatory = $false)]
        [string]$logPath = "$HOME\Documents"  # Default to the Documents folder if no path is provided
    )

    # Create an empty array for logging duplicate emails
    $duplicateEmails = @()

    # Get the distribution group members
    $groupMembers = Get-DistributionGroupMember -Identity $distributionGroupName

    # Check if the email is a mail contact in your Exchange
    $contacts = Get-Recipient -Filter "EmailAddresses -eq '$email'"

    if ($contacts.Count -gt 1) {
        # Log the duplicate email and skip adding it to the group
        Write-Verbose "Duplicate email detected: $email"
        $duplicateEmails += New-Object PSObject -Property @{Email = $email }
    }
    elseif ($contacts.Count -eq 1) {
        # If the email is not in the distribution group, add it
        $groupMemberEmails = $groupMembers | ForEach-Object { $_.PrimarySmtpAddress }
        if ($email -notin $groupMemberEmails) {
            Add-DistributionGroupMember -Identity $distributionGroupName -Member $email
            Write-Verbose "$email added to the distribution group"
        }
    }

    # Export the logs to a CSV file
    $duplicateEmails | Export-Csv -Path "$logPath\DuplicateEmails.csv" -NoTypeInformation

    Write-Verbose "Logs exported to CSV file"
}