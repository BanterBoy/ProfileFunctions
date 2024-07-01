<#
.SYNOPSIS
    Generates an out of office message in HTML format and saves it to a file.

.DESCRIPTION
    The New-OOHMessage function generates an out of office message in HTML format with the specified return date, contact email, closing remark, and sender name. The generated message is saved to a file with a filename based on the current date in the specified output directory.

.PARAMETER returnDate
    The return date of the sender in the format of "Day Month Year" (e.g., "31 December 2022"). Mandatory for temporary messages.

.PARAMETER contactEmail
    The email address to contact if the email relates to the specified subject.

.PARAMETER closingRemark
    The closing remark to include in the message.

.PARAMETER senderName
    The name of the sender.

.PARAMETER outputDirectory
    The directory to save the generated message file. The default value is the system temporary directory.

.PARAMETER RelatesTo
    The subject the email relates to. Mandatory for temporary messages.

.PARAMETER permanent
    Indicates that the out of office message is permanent. When set, the return date and subject are not required.

.EXAMPLE
    New-OOHMessage -returnDate "31 December 2022" -contactEmail "contact@example.com" -closingRemark "Thank you for your understanding." -senderName "John Doe" -RelatesTo "Project X"

    In this example, a temporary out of office message is generated. The message indicates that the sender will return on 31 December 2022. If the email relates to "Project X", the recipient is advised to contact "contact@example.com". The closing remark is "Thank you for your understanding." and the sender's name is "John Doe".

.EXAMPLE
    New-OOHMessage -permanent -contactEmail "contact@example.com" -closingRemark "Best regards." -senderName "John Doe" -RelatesTo "Project X"

    In this example, a permanent out of office message is generated. The message indicates that the sender is no longer with the company. If the email relates to "Project X", the recipient is advised to contact "contact@example.com". The closing remark is "Best regards." and the sender's name is "John Doe".

.NOTES
    Author: Luke Leigh
    Website: https://blog.lukeleigh.com
    Twitter: https://twitter.com/luke_leighs

#>

function New-OOHMessage {
    [CmdletBinding(DefaultParameterSetName = 'Temporary')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Temporary', HelpMessage = "The return date of the sender in the format of 'Day Month Year'.")]
        [ValidatePattern("^\d{1,2} (January|February|March|April|May|June|July|August|September|October|November|December) \d{4}$")]
        [string]$returnDate,

        [Parameter(Mandatory = $true, HelpMessage = "The email address to contact if the email relates to the specified subject.")]
        [ValidatePattern("^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")]
        [string]$contactEmail,

        [Parameter(Mandatory = $true, HelpMessage = "The closing remark to include in the message.")]
        [string]$closingRemark,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the sender.")]
        [string]$senderName,

        [Parameter(Mandatory = $true, ParameterSetName = 'Temporary', HelpMessage = "The subject the email relates to.")]
        [string]$RelatesTo,

        [Parameter(ParameterSetName = 'Permanent', HelpMessage = "Indicates that the out of office message is permanent.")]
        [switch]$permanent,

        [Parameter(Mandatory = $false, HelpMessage = "The directory to save the generated message file. The default value is the system temporary directory.")]
        [string]$outputDirectory = $Env:Temp
    )

    begin {
        Write-Verbose "Starting New-OOHMessage function."
    }

    process {
        try {
            $message = if ($permanent) {
                "Thank you for your email. I am no longer with the Rail Delivery Group. Please direct any queries to $contactEmail."
            }
            else {
                "Thank you for your email. I am currently on leave and will return on $returnDate. I will respond to your email upon my return. If your email relates to $RelatesTo, please contact $contactEmail."
            }

            $htmlContent = @"
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; font-size: 13px; }
        .message { margin-bottom: 20px; }
        .closing { font-style: italic; }
        .signature { font-weight: bold; }
    </style>
</head>
<body>
    <div class="message">$message</div>
    <div class="closing">$closingRemark</div>
    <div class="signature">$senderName</div>
</body>
</html>
"@

            # Generate the filename based on the current date
            $filename = "OOHMessage_" + (Get-Date -Format "yyyyMMdd") + ".html"
            $outputFilePath = Join-Path -Path $outputDirectory -ChildPath $filename

            # Write the HTML content to the specified file with UTF8 encoding
            Write-Verbose "Saving the HTML content to $outputFilePath."
            $htmlContent | Out-File -FilePath $outputFilePath -Encoding UTF8

            Write-Output "Out of office message saved successfully to $outputFilePath."
        }
        catch {
            Write-Error "Failed to create out of office message: $_"
        }
    }

    end {
        Write-Verbose "New-OOHMessage function execution completed."
    }
}
