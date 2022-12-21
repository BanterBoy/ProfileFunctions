<#
    Script for sending email with send-mgusermail
    
    Ref:

    https://mikecrowley.us/2021/10/27/sending-email-with-send-mgusermail-microsoft-graph-powershell
    https://docs.microsoft.com/en-us/graph/api/user-sendmail
    https://docs.microsoft.com/en-us/powershell/module/microsoft.graph.users.actions/send-mgusermail

#>

#region 1: Setup

$emailRecipients = @(
    'luke@leigh-services.com'
    # 'user2@domain.biz'
)
$emailSender = 'luke@leigh-services.com'

$emailSubject = "Sample Email | " + (Get-Date -UFormat %e%b%Y)

$MgConnectParams = @{
    ClientId              = '<your app>'
    TenantId              = '<your tenant id>'
    CertificateThumbprint = '<your thumbprint>'
}

Function ConvertTo-IMicrosoftGraphRecipient {
    [cmdletbinding()]
    Param(
        [array]$SmtpAddresses        
    )
    foreach ($address in $SmtpAddresses) {
        @{
            emailAddress = @{address = $address }
        }    
    }    
}

Function ConvertTo-IMicrosoftGraphAttachment {
    [cmdletbinding()]
    Param(
        [string]$UploadDirectory        
    )
    $directoryContents = Get-ChildItem $UploadDirectory -Attributes !Directory -Recurse
    foreach ($file in $directoryContents) {
        $encodedAttachment = [convert]::ToBase64String((Get-Content $file.FullName -Encoding byte))
        @{
            "@odata.type" = "#microsoft.graph.fileAttachment"
            name          = ($File.FullName -split '\\')[-1]
            contentBytes  = $encodedAttachment
        }   
    }    
}

#endregion 1


#region 2: Run

[array]$toRecipients = ConvertTo-IMicrosoftGraphRecipient -SmtpAddresses $emailRecipients 

# $attachments = ConvertTo-IMicrosoftGraphAttachment -UploadDirectory C:\tmp

$emailBody = @{
    ContentType = 'html'
    Content     = Get-Content 'C:\GitRepos\ProfileFunctions\APCEmail\EmailTemplate.html'    
}

Connect-Graph @MgConnectParams
Select-MgProfile v1.0

$body += @{subject = $emailSubject }
$body += @{toRecipients = $toRecipients }    
# $body += @{attachments  = $attachments}
$body += @{body = $emailBody }

$bodyParameter += @{'message' = $body }
$bodyParameter += @{'saveToSentItems' = $true }

Send-MgUserMail -UserId $emailSender -BodyParameter $bodyParameter

#endregion 2