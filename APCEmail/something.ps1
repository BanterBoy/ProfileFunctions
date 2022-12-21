# Graph PowerShell App
# Application (client) ID
$clientid = "072e4d5f-35f8-4060-ab1f-ffca4aeae666"

# Directory (tenant) ID
$TenantId = "3ab8c573-cfde-4a33-b33a-6bd96f601c18"

# MSGraphPSClientSecret
# Expires
# 12/10/2023
$Clientsecret = "YGG8Q~oOuBD7gs5JFc8qzmPrSbWUkG7JtLS3Dacd"
$SecretID = "29ed93bd-3462-40e5-8532-322f4fe6cce3"


# The resource URI
$resource = "https://graph.microsoft.com"
$redirectUri = "https://localhost"

# UrlEncode the ClientID and ClientSecret and URL's for special characters 
$clientIDEncoded = [System.Web.HttpUtility]::UrlEncode($clientid)
$clientSecretEncoded = [System.Web.HttpUtility]::UrlEncode($clientSecret)
$redirectUriEncoded = [System.Web.HttpUtility]::UrlEncode($redirectUri)
$resourceEncoded = [System.Web.HttpUtility]::UrlEncode($resource)
$scopeEncoded = [System.Web.HttpUtility]::UrlEncode("https://outlook.office.com/user.readwrite.all")

# Function to popup Auth Dialog Windows Form
Function Get-AuthCode {
    Add-Type -AssemblyName System.Windows.Forms

    $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width = 440; Height = 640 }
    $web = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width = 420; Height = 600; Url = ($url -f ($Scope -join "%20")) }

    $DocComp = {
        $Global:uri = $web.Url.AbsoluteUri        
        if ($Global:uri -match "error=[^&]*|code=[^&]*") { $form.Close() }
    }
    $web.ScriptErrorsSuppressed = $true
    $web.Add_DocumentCompleted($DocComp)
    $form.Controls.Add($web)
    $form.Add_Shown({ $form.Activate() })
    $form.ShowDialog() | Out-Null

    $queryOutput = [System.Web.HttpUtility]::ParseQueryString($web.Url.Query)
    $output = @{}
    foreach ($key in $queryOutput.Keys) {
        $output["$key"] = $queryOutput[$key]
    }

    $output
}


# Get AuthCode
$url = "https://login.microsoftonline.com/common/oauth2/authorize?response_type=code&redirect_uri=$redirectUriEncoded&client_id=$clientID&resource=$resourceEncoded&prompt=admin_consent&scope=$scopeEncoded"
Get-AuthCode
# Extract Access token from the returned URI
$regex = '(?<=code=)(.*)(?=&)'
$authCode = ($uri | Select-string -pattern $regex).Matches[0].Value

Write-output "Received an authCode, $authCode"

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
