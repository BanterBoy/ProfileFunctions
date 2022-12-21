<#
        The tenant-wide admin consent URL follows the following format:

        HTTP

        Copy
        https://login.microsoftonline.com/{tenant-id}/adminconsent?client_id={client-id}
        where:

        {client-id} is the application's client ID (also known as app ID).
        {tenant-id} is your organization's tenant ID or any verified domain name.



        # $CertThum = "33DEE4F7329508AD86F0FD3C5B97DB42B76063BD"
        # connect-MgGraph -ClientId $ClientId -TenantId $TenantId -CertificateThumbprint $CertThum

#>

$ClientId = "072e4d5f-35f8-4060-ab1f-ffca4aeae666"
$TenantId = "3ab8c573-cfde-4a33-b33a-6bd96f601c18"
$ClientSecret = "YGG8Q~oOuBD7gs5JFc8qzmPrSbWUkG7JtLS3Dacd"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/x-www-form-urlencoded")
$headers.Add("Cookie", "fpc=AlG9T5NiY1VHik3OOT8wj3uCCbohAQAAAAILJ9sOAAAA; stsservicecookie=estsfd; x-ms-gateway-slice=estsfd")
$body = "grant_type=client_credentials&client_id=$ClientId&scope=https%3A%2F%2Fgraph.microsoft.com%2F.default&client_secret=$ClientSecret"
$URL = 'https://login.microsoftonline.com/' + $TenantId + '/oauth2/v2.0/token'
$response = Invoke-RestMethod -Uri $URL -Method 'PUT' -Headers $headers -Body $body

#Configure Mail Properties
$MailSender = "luke@leigh-services.com"
$Attachment = "C:\GitRepos\AGAMAR.docx"
$Recipient = "luke+O365test@leigh-services.com"

#Get File Name and Base64 string
$FileName = (Get-Item -Path $Attachment).name
$base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Attachment))

$headers = @{
    "Authorization" = "Bearer $($response.access_token)"
    "Content-type"  = "application/json"
}

#Send Mail    
$URLsend = "https://graph.microsoft.com/v1.0/users/$MailSender/sendMail"
$BodyJsonsend = @"
{
    "message": {
        "subject": "Hello World from Microsoft Graph API",
        "body": {
        "contentType": "HTML",
        "content": "This Mail is sent via Microsoft <br> GRAPH <br> API<br> and an Attachment <br>"
        },
        
        "toRecipients": [
        {
            "emailAddress": {
            "address": "$Recipient"
            }
        }
        ]
        ,"attachments": [
        {
            "@odata.type": "microsoft.graph.fileAttachment",
            "name": "$FileName",
            "contentType": "text/plain",
            "contentBytes": "$base64string"
        }
        ]
    },
    "saveToSentItems": "false"
    }
"@

Invoke-RestMethod -Method POST -Uri $URLsend -Headers $headers -Body $BodyJsonsend

$ClientId = "072e4d5f-35f8-4060-ab1f-ffca4aeae666"
$TenantId = "3ab8c573-cfde-4a33-b33a-6bd96f601c18"
$Something = "https://login.microsoftonline.com/$TenantId/adminconsent?client_id=$ClientId"
Start-Process $Something
