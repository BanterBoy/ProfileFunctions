function New-SendMailKitMessage {

    [CmdletBinding()]
    param (
        [Parameter()]
        [TypeName]
        $ParameterName
    )    

    begin {

        Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MailKit.2.8.0\lib\netstandard2.0\MailKit.dll"
        Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MimeKit.2.9.1\lib\netstandard2.0\MimeKit.dll"

    }

    process {

        $SMTP = New-Object MailKit.Net.Smtp.SmtpClient
        $Message = New-Object MimeKit.MimeMessage
        $TextPart = [MimeKit.TextPart]::new("plain")
        $TextPart.Text = "This is a test."
    
        $Message.From.Add("user@mydomain.com")
        $Message.To.Add("recipient@mydomain.com")
        $Message.Subject = 'Test Message'
        $Message.Body = $TextPart
    
        $SMTP.Connect('{tenant}.mail.protection.outlook.com', 25, [MailKit.Security.SecureSocketOptions]::StartTls, $False)
        $SMTP.Authenticate('user@mydomain.com', 'mypassword' )

    }

    end {

        $SMTP.Send($Message)
        $SMTP.Disconnect($true)
        $SMTP.Dispose()

    }

}


https://adamtheautomator.com/powershell-email/