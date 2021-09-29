<#

    .SYNOPSIS
    Send-MailKitMessage.ps1 - Cmdlet to replace deprecated Send-MailMessage functionality using .Net nuget packages Mailkit & MimeKit.

    .NOTES
    Author	: Luke Leigh
    Website	: https://blog.lukeleigh.com
    Twitter	: https://twitter.com/luke_leighs

    Additional Credits: [REFERENCE]
    Website: [URL]
    Twitter: [URL]

    Change Log
    [VERSIONS]
    
    .DESCRIPTION
	[DESC]

    .PARAMETER  

    
    .INPUTS
    None. Does not accepted piped input.

    .OUTPUTS
    None. Returns no objects or output.
    System.Boolean  True if the current Powershell is elevated, false if not.
    [use a | get-member on the script to see exactly what .NET obj TypeName is being returning for the info above]

    .EXAMPLE
    $AutoSecret = Get-Secret -Vault AutomationDbase -Name "AutoUser"
    $AutoUserCreds = New-Object -TypeName PSCredential -ArgumentList "AutoUser", $AutoSecret
    .\New-SendMailKitMessage.ps1 -To "luke.leigh@carpetright.co.uk" -From "on-boarding@carpetright.co.uk" -Subject "This is a test." -Body "Some testy type text or something needs to appear here, so I am typing something." -Credential $AutoUserCreds
    
    [use an .EXAMPLE keyword per syntax sample]
    .LINK


    .FUNCTIONALITY

#>

[CmdletBinding(DefaultParameterSetName = 'Default',
    SupportsShouldProcess = $true,
    HelpUri = 'http://www.microsoft.com/',
    ConfirmImpact = 'Low')]
[Alias('smkm')]
[OutputType([String])]
Param (
    # Brief explanation of the parameter and its requirements/function
    [Parameter(Mandatory = $false,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false, 
        ParameterSetName = 'Default',
        HelpMessage = "Brief explanation of the parameter and its requirements/function")]
    [String]
    $To,

    [Parameter( Position = 1,
        Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false, 
        ParameterSetName = 'Default',
        HelpMessage = "Brief explanation of the parameter and its requirements/function")]
    [String]
    $Subject,

    [Parameter( Position = 2,
        Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false, 
        ParameterSetName = 'Default',
        HelpMessage = "Brief explanation of the parameter and its requirements/function")]
    [String]
    $Body,

    [Parameter( Position = 3,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false, 
        ParameterSetName = 'Default',
        HelpMessage = "Brief explanation of the parameter and its requirements/function")]
    [String]
    $SmtpServer = $PSEmailServer,

    [Parameter( Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false, 
        ParameterSetName = 'Default',
        HelpMessage = "Brief explanation of the parameter and its requirements/function")]
    [String]
    $From,

    [Parameter( ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false, 
        ParameterSetName = 'Default',
        HelpMessage = "Brief explanation of the parameter and its requirements/function")]
    [String]
    $CC,

    [Parameter( ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false, 
        ParameterSetName = 'Default',
        HelpMessage = "Brief explanation of the parameter and its requirements/function")]
    [String]
    $BCC,

    [Parameter( ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false, 
        ParameterSetName = 'Default',
        HelpMessage = "Brief explanation of the parameter and its requirements/function")]
    [Switch]
    $BodyAsHtml,
        
    [Parameter( ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false, 
        ParameterSetName = 'Default',
        HelpMessage = "Brief explanation of the parameter and its requirements/function")]
    [pscredential]
    $Credential,

    [Parameter( ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false, 
        ParameterSetName = 'Default',
        HelpMessage = "Brief explanation of the parameter and its requirements/function")]
    [Int32]
    $Port = 25

)

Begin {
    Add-Type -Path ".\MailKit\MailKit.dll"
    Add-Type -Path ".\MimeKit\MimeKit.dll"
}

Process {
    $SMTP = New-Object MailKit.Net.Smtp.SmtpClient
    $Message = New-Object MimeKit.MimeMessage
  
    If ($BodyAsHtml) {
        $TextPart = [MimeKit.TextPart]::new("html")
    }
    Else {
        $TextPart = [MimeKit.TextPart]::new("plain")
    }
      
    $TextPart.Text = $Body
  
    $Message.From.Add($From)
    $Message.To.Add($To)
      
    If ($CC) {
        $Message.CC.Add($CC)
    }
      
    If ($BCC) {
        $Message.BCC.Add($BCC)
    }
  
    $Message.Subject = $Subject
    $Message.Body = $TextPart
  
    $SMTP.Connect($SmtpServer, $Port, $False)
  
    If ($Credential) {
        $SMTP.Authenticate($Credential.UserName, $Credential.GetNetworkCredential().Password)
    }
  
    If ($PSCmdlet.ShouldProcess('Send the mail message via MailKit.')) {
        $SMTP.Send($Message)
    }
    
}

end {
    $SMTP.Disconnect($true)
    $SMTP.Dispose()
}

