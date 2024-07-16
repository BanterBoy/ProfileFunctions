param (
    [switch]$TestMode
)

$tenantId = ############################
$clientId = ############################
$clientSecret = ############################
$from = "luke@leigh-services.com"
$subject = "Immediate Assistance Required: Service Complaint Ignored - Order #65407"
$body = @"
<html>
<head>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 10px;
            background-color: #f9f9f9;
        }
        .header {
            text-align: center;
            border-bottom: 1px solid #ddd;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
        }
        .content p {
            margin: 0 0 10px;
        }
        .footer {
            text-align: center;
            font-size: 12px;
            color: #777;
            margin-top: 20px;
            border-top: 1px solid #ddd;
            padding-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Customer Service Inquiry - Order #65407</h1>
        </div>
        <div class="content">
            <p>Tiger Team,</p>
            <p>Will someone please have the decency to reply to my message with something that isn't automated and actually answers my question?</p>
            <p>I have spoken with the customer service team and I was advised someone would be in touch but this is yet to happen.</p>
            <p>I have contacted Klarna and payments have been stopped. This is an excessive amount of effort to expect any customer to have to put in to get a response.</p>
            <p>All I want to know is when you are coming to collect your product from my garden and refund my money. This is an appalling service.</p>
            <p>Luke Leigh</p>
        </div>
        <div class="footer">
            <p>This email was sent from an automated system. Please do not reply directly to this email.</p>
        </div>
    </div>
</body>
</html>
"@

# List of email addresses to cycle through
$recipients = @(
    "customersupport@tigersheds.com",
    "sales@tigersheds.com",
    "pr@tigersheds.com",
    "sales@tigerbox.co.uk",
    "lauren.coley@tigersheds.com"
)

# Loop to send 15 emails per minute, up to a maximum of 7200 emails over 8 hours
$emailsPerMinute = 15
$totalEmails = 7200
$sentEmails = 0

# Calculate total batches
$totalBatches = [math]::Ceiling($totalEmails / $emailsPerMinute)
$recipientIndex = 0

# Initialize Progress Bar
$progressActivity = "Sending Emails"
$progressStatus = "Emails Sent"
$progressPercent = 0

Write-Verbose "Starting email sending process. Total emails to send: $totalEmails"

while ($sentEmails -lt $totalEmails) {
    for ($i = 1; $i -le $emailsPerMinute; $i++) {
        if ($sentEmails -ge $totalEmails) {
            break
        }
        $to = $recipients[$recipientIndex]
        $recipientIndex = ($recipientIndex + 1) % $recipients.Count

        if ($TestMode) {
            Write-Output "Test Mode: Simulating sending email $($sentEmails + 1) of $totalEmails to $to"
        }
        else {
            Write-Output "Sending email $($sentEmails + 1) of $totalEmails to $to"
            Send-EmailUsingAzureApp -TenantID $tenantId -ClientID $clientId -ClientSecret $clientSecret -To $to -From $from -Subject $subject -Body $body -Verbose
        }
        
        # Update Progress Bar
        $sentEmails++
        $progressPercent = ($sentEmails / $totalEmails) * 100
        Write-Progress -Activity $progressActivity -Status $progressStatus -PercentComplete $progressPercent -CurrentOperation "Email $sentEmails of $totalEmails"

        # Sleep for 4 seconds between each email
        Start-Sleep -Seconds 4
    }
    Write-Verbose "Batch of $emailsPerMinute emails sent. Waiting for the next batch..."
}

Write-Verbose "Email sending process completed. Total emails sent: $sentEmails"
