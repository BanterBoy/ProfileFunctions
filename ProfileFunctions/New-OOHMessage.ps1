<#
.SYNOPSIS
    Generates an out of office message in HTML format and saves it to a file.
.DESCRIPTION
    The New-OOHMessage function generates an out of office message in HTML format with the specified return date, contact email, closing remark, and sender name. The generated message is saved to a file with a filename based on the current date in the specified output directory.
.PARAMETER returnDate
    The return date of the sender in the format of "Month Day, Year".
.PARAMETER contactEmail
    The email address to contact if the email relates to the Train Drivers Academy.
.PARAMETER closingRemark
    The closing remark to include in the message.
.PARAMETER senderName
    The name of the sender.
.PARAMETER outputDirectory
    The directory to save the generated message file. The default value is the system temporary directory.
.EXAMPLE
New-OOHMessage -returnDate "December 31, 2022" -contactEmail "contact@example.com" -closingRemark "Thank you for your understanding." -senderName "John Doe" -RelatesTo "Project X"

In this example, a temporary out of office message is generated. The message indicates that the sender will return on December 31, 2022. If the email relates to "Project X", the recipient is advised to contact "contact@example.com". The closing remark is "Thank you for your understanding." and the sender's name is "John Doe".

.EXAMPLE
New-OOHMessage -permanent $true -contactEmail "contact@example.com" -closingRemark "Best regards." -senderName "John Doe" -RelatesTo "Project X"

In this example, a permanent out of office message is generated. The message indicates that the sender is no longer with the company. If the email relates to "Project X", the recipient is advised to contact "contact@example.com". The closing remark is "Best regards." and the sender's name is "John Doe".

#>

function New-OOHMessage {
    [CmdletBinding(DefaultParameterSetName = 'Temporary')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Temporary')][string]$returnDate,
        [Parameter(Mandatory = $true)][string]$contactEmail,
        [Parameter(Mandatory = $true)][string]$closingRemark,
        [Parameter(Mandatory = $true)][string]$senderName,
        [Parameter(Mandatory = $true, ParameterSetName = 'Temporary')][string]$RelatesTo,
        [Parameter(ParameterSetName = 'Permanent')][switch]$permanent,
        [Parameter(Mandatory = $false)][string]$outputDirectory = $Env:Temp
    )

    $message = if ($permanent) {
        "Thank you for your email. I am no longer for the Rail Delivery Group. Please Direct any queries to $contactEmail, $relatesTo"
    }
    else {
        "Thank you for your email, I am currently on leave, my next working day $returnDate. I will respond to your email upon my return. If your email relates to $RelatesTo, please contact $contactEmail"
    }

    $htmlContent = @"
    <html>
    <body style="font-family:Arial; font-size:13px">
        <font size="2"><span lang="EN-GB">
                <p dir="ltr" align="left">$message</p>
                <p dir="ltr" align="left">$closingRemark</p>
                <p dir="ltr" align="left">$senderName</p>
            </span>
    </body>
    </html>
"@

    # Generate the filename based on the current date
    $filename = "OOHMessage_" + (Get-Date -Format "yyyyMMdd") + ".html"
    $outputFilePath = Join-Path -Path $outputDirectory -ChildPath $filename

    # Write the HTML content to the specified file with UTF8 encoding
    $htmlContent | Out-File -FilePath $outputFilePath -Encoding UTF8
}
