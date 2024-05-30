function Update-DistributionList {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string]$csvFilePath,
        [string]$distributionGroupName,
        [string]$logPath = "$HOME\Documents"  # Default to the Documents folder if no path is provided
    )

    # Create empty arrays for logging
    $addedEmails = @()
    $removedEmails = @()
    $duplicateEmails = @()

    # Import the CSV file
    $csvEmails = Import-Csv -Path $csvFilePath | ForEach-Object { $_.Email }  # Assuming 'Members' is the column name in your CSV

    Write-Verbose "CSV file imported"

    # Get the distribution group members
    $groupMembers = Get-DistributionGroupMember -Identity $distributionGroupName

    Write-Verbose "Distribution group members retrieved"

    # Check for duplicate emails in the CSV file
    $group = $csvEmails | Group-Object
    $duplicates = $group | Where-Object { $_.Count -gt 1 }
    if ($duplicates) {
        foreach ($duplicate in $duplicates) {
            $duplicateEmails += New-Object PSObject -Property @{Email = $duplicate.Name }
        }
    }

    # Compare the lists and update the distribution group
    foreach ($email in $csvEmails) {
        # Check if the email is a mail contact in your Exchange
        $contact = Get-MailContact -Filter "EmailAddresses -eq '$email'"

        if ($contact) {
            # If the email is not in the distribution group, add it
            $groupMemberEmails = $groupMembers | ForEach-Object { $_.PrimarySmtpAddress }
            if ($email -notin $groupMemberEmails) {
                if ($PSCmdlet.ShouldProcess("$email", "Add to distribution group")) {
                    Add-DistributionGroupMember -Identity $distributionGroupName -Member $email
                    $addedEmails += New-Object PSObject -Property @{Email = $email }
                    Write-Verbose "$email added to the distribution group"
                }
            }
        }
    }

    foreach ($member in $groupMembers) {
        # If the member is not in the CSV file, remove it from the distribution group
        if ($member.PrimarySmtpAddress -notin $csvEmails) {
            if ($PSCmdlet.ShouldProcess("$member.PrimarySmtpAddress", "Remove from distribution group")) {
                Remove-DistributionGroupMember -Identity $distributionGroupName -Member $member.PrimarySmtpAddress -Confirm:$false
                $removedEmails += New-Object PSObject -Property @{Email = $member.PrimarySmtpAddress }
                Write-Verbose "$member.PrimarySmtpAddress removed from the distribution group"
            }
        }
    }

    # Get the current date and time
    $date = Get-Date -Format "yyyyMMddHHmm"

    # Export the logs to CSV files
    $addedEmails | Export-Csv -Path "$logPath\AddedEmails-$date.csv" -NoTypeInformation
    $removedEmails | Export-Csv -Path "$logPath\RemovedEmails-$date.csv" -NoTypeInformation
    $duplicateEmails | Export-Csv -Path "$logPath\DuplicateEmails-$date.csv" -NoTypeInformation

    Write-Verbose "Logs exported to CSV files"
}

# Update-DistributionList -csvFilePath "C:\GitRepos\RDG\Scripts\DistributionLists\RARSCommsList.csv" -distributionGroupName "RARS Comms" -WhatIf
# Update-DistributionList -csvFilePath "C:\path\to\your\file.csv" -distributionGroupName "RARS Comms" -logPath "C:\path\to\your\logs" -Verbose

