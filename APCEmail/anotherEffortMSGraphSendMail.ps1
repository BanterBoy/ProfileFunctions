GraphAPIGetAuthCode.ps1 -ClientId <clientId> -ClientSecret <clientSecret> -RedirectUrl <redirectUrl>

[CmdletBinding()]
PARAM(
    [parameter(ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        Mandatory = $true)]
    [string]$ClientId,

    [parameter(ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        Mandatory = $true)]
    [string]$ClientSecret,

    [parameter(ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        Mandatory = $true)]
    [string]$RedirectUrl
)
BEGIN
{
    $ResourceUrl = "https://graph.microsoft.com"
}
PROCESS
{
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

    # UrlEncode the ClientID and ClientSecret and URL's for special characters 
    $clientIDEncoded = [System.Web.HttpUtility]::UrlEncode($ClientId)
    $clientSecretEncoded = [System.Web.HttpUtility]::UrlEncode($ClientSecret)
    $redirectUrlEncoded = [System.Web.HttpUtility]::UrlEncode($RedirectUrl)
    $resourceUrlEncoded = [System.Web.HttpUtility]::UrlEncode($ResourceUrl)
    $scopeEncoded = [System.Web.HttpUtility]::UrlEncode("https://outlook.office.com/user.readwrite.all")

    # Get AuthCode
    $url = "https://login.microsoftonline.com/common/oauth2/authorize?response_type=code&redirect_uri=$redirectUrlEncoded&client_id=$clientID&resource=$resourceUrlEncoded&prompt=admin_consent&scope=$scopeEncoded"

    Get-AuthCode
  
    # Extract Access token from the returned URI
    $regex = '(?<=code=)(.*)(?=&)'
    $authCode = ($uri | Select-string -pattern $regex).Matches[0].Value

    # Store AuthCode
    Set-Content "$PSScriptRoot\AuthCode.txt" $authCode
}

{
    "AppId": {
        "ClientId": "fa9d9d34-7a2a-****-****-************",
        "ClientSecret": "J/WDSKLjE+XC9G0+ASDHUen31/***********=",
        "RedirectUrl": "https://localhost:8000",
        "ResourceUrl": "https://graph.microsoft.com"
    }
}
  