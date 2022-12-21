<#
    Graph PowerShell App

    Display name
    MSGraphPowerShellApp
    
    Application (client) ID
    $ClientID = "072e4d5f-35f8-4060-ab1f-ffca4aeae666"
    
    Object ID
    ccd60873-3edd-494c-a709-06fed1cdd217
    
    Directory (tenant) ID
    $TenantID = "3ab8c573-cfde-4a33-b33a-6bd96f601c18"
    
    Supported account types
    My organization only
    
    MSGraphPowerShellApp
    
    MSGraphPSClientSecret
    Expires = 12/10/2023
    SecretID = 29ed93bd-3462-40e5-8532-322f4fe6cce3
    $Value = "YGG8Q~oOuBD7gs5JFc8qzmPrSbWUkG7JtLS3Dacd"

    
#>

$ClientId = "072e4d5f-35f8-4060-ab1f-ffca4aeae666"
$TenantId = "3ab8c573-cfde-4a33-b33a-6bd96f601c18"
$CertThum = "33DEE4F7329508AD86F0FD3C5B97DB42B76063BD"



#Configure Mail Properties
$MailSender = "luke@leigh-services.com"
$Attachment = "C:\GitRepos\AGAMAR.docx"
$Recipient = "luke+O365test@leigh-services.com"

#Get File Name and Base64 string
$FileName = (Get-Item -Path $Attachment).name
$base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Attachment))


#Connect to GRAPH API
$tokenBody = @{
  Grant_Type    = "client_credentials"
  Scope         = "https://graph.microsoft.com/.default"
  Client_Id     = $ClientID
  Client_Secret = $Clientsecret
}


{
  "token_type": "Bearer",
  "expires_in": 3599,
  "ext_expires_in": 3599,
  "access_token": "eyJ0eXAiOiJKV1QiLCJub25jZSI6IlJsUTQ5eGhmSmlhM3ZpQy1Qd19zSnhZMGJJWWR5Q0hzMi1GcGRWOEI5M3ciLCJhbGciOiJSUzI1NiIsIng1dCI6IjJaUXBKM1VwYmpBWVhZR2FYRUpsOGxWMFRPSSIsImtpZCI6IjJaUXBKM1VwYmpBWVhZR2FYRUpsOGxWMFRPSSJ9.eyJhdWQiOiJodHRwczovL2dyYXBoLm1pY3Jvc29mdC5jb20iLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC8zYWI4YzU3My1jZmRlLTRhMzMtYjMzYS02YmQ5NmY2MDFjMTgvIiwiaWF0IjoxNjcwNzE0MjgzLCJuYmYiOjE2NzA3MTQyODMsImV4cCI6MTY3MDcxODE4MywiYWlvIjoiRTJaZ1lKQU43dWtKbFQzSGYzajVtMjZGMC83TEFBPT0iLCJhcHBfZGlzcGxheW5hbWUiOiJNU0dyYXBoUG93ZXJTaGVsbEFwcCIsImFwcGlkIjoiMDcyZTRkNWYtMzVmOC00MDYwLWFiMWYtZmZjYTRhZWFlNjY2IiwiYXBwaWRhY3IiOiIxIiwiaWRwIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvM2FiOGM1NzMtY2ZkZS00YTMzLWIzM2EtNmJkOTZmNjAxYzE4LyIsImlkdHlwIjoiYXBwIiwib2lkIjoiNTcwZjBjMjEtYjdjMy00ZmE1LThiMzEtZDMwMzA3NzFlZDRiIiwicmgiOiIwLkFWd0FjOFc0T3Q3UE0wcXpPbXZaYjJBY0dBTUFBQUFBQUFBQXdBQUFBQUFBQUFCY0FBQS4iLCJzdWIiOiI1NzBmMGMyMS1iN2MzLTRmYTUtOGIzMS1kMzAzMDc3MWVkNGIiLCJ0ZW5hbnRfcmVnaW9uX3Njb3BlIjoiRVUiLCJ0aWQiOiIzYWI4YzU3My1jZmRlLTRhMzMtYjMzYS02YmQ5NmY2MDFjMTgiLCJ1dGkiOiJpVmc0X0I3akVFV0owQ0dtektnb0FRIiwidmVyIjoiMS4wIiwid2lkcyI6WyIwOTk3YTFkMC0wZDFkLTRhY2ItYjQwOC1kNWNhNzMxMjFlOTAiXSwieG1zX3RjZHQiOjE1ODkyMjc1NzJ9.ZIKiogw5Caq1d8cFbLjmIw5KPmSSiCGZr-g3SZP5X--cBwts4ETUjiK3xPC_lUdw_B_oekmJ5JoPes1380R40z-pFtUES_Zmgvp2MpIj_F3DG5IiFscXUhMdFRUjmtQIlNKLvVoY1jSDGVf0rfESt7Sbh7plTbJu5ucGNJvlpkGtjFtrmIXDnNyKs1eN9tdmihb2-r4jInz8Ho8FZ0xFs3cNRquYFm-Ya80YOzd-VTIjjiR4EMl0xdur_isHiVZ-csqpHOWm7Z_KosTEqcEGZf-s65TH7UVE9Il-JVXr3JG_aJhbv9EDc4PPfHkcE87G9M2C11shsnmdUK6EKuoR5g"
}


$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $tokenBody
$headers = @{
  "Authorization" = "Bearer $($tokenResponse.access_token)"
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
                            "content": "This Mail is sent via Microsoft <br>
                            GRAPH <br>
                            API<br>
                            and an Attachment <br>
                            "
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
                              "@odata.type": "#microsoft.graph.fileAttachment",
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