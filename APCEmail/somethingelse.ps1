#requires -modules Microsoft.Graph.Authentication,Microsoft.Graph.Mail,Microsoft.Graph.Users

# Graph PowerShell App
# Application (client) ID
$AppID = "63bf362a-c7f3-4a05-ba69-c4c2630c2a11"

# Directory (tenant) ID
$TenantId = "3ab8c573-cfde-4a33-b33a-6bd96f601c18"

# MSGraphPSClientSecret
# Expires
# 12/10/2023
$Clientsecret = "YGG8Q~oOuBD7gs5JFc8qzmPrSbWUkG7JtLS3Dacd"
$SecretID = "29ed93bd-3462-40e5-8532-322f4fe6cce3"


$tokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $ClientID
    Client_Secret = $Clientsecret
}
Connect-Graph @tokenBody

# Email Content
$EmailContent = Get-Content -Path C:\GitRepos\ProfileFunctions\APCEmail\EmailTemplate.html

#recipients
$EmailAddress = @{address = 'luke@leigh-services.com' } # https://docs.microsoft.com/en-us/graph/api/resources/recipient?view=graph-rest-1.0
$Recipient = @{EmailAddress = $EmailAddress }  # https://docs.microsoft.com/en-us/graph/api/resources/emailaddress?view=graph-rest-1.0

#Body
$body = @{
    content     = $EmailContent
    ContentType = 'html'
}

#Attachments
# If over ~3MB: https://docs.microsoft.com/en-us/graph/outlook-large-attachments?tabs=http
$AttachmentPath = 'C:\tmp\Book1.xlsx'
$EncodedAttachment = [convert]::ToBase64String((Get-Content $AttachmentPath -Encoding byte)) 
$Attachment = @{
    "@odata.type" = "#microsoft.graph.fileAttachment"
    name          = ($AttachmentPath -split '\\')[-1]
    contentBytes  = $EncodedAttachment
}

#Create Message (goes to drafts)
$Message = New-MgUserMessage -UserId me@mydomain.com -Body $body -ToRecipients $Recipient -Subject Subject1 -Attachments $Attachment

#Send Message
Send-MgUserMessage -UserId me@mydomain.com -MessageId $Message.Id
 

#end
