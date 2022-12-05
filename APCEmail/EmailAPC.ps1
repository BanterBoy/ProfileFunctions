$Content = @"
<!DOCTYPE html>
<html>

<head>
    <style>
        h1 {
            padding-left: 20px;
            color: blue;
            font-family: Calibri;
            font-size: 14pt;
        }

        h2 {
            color: cornflowerblue;
            font-family: Calibri;
            font-size: 12pt;
            font-style: italic;
        }

        pre {
            color: cornflowerblue;
            font-family: Calibri;
            font-style: italic;
            font-size: 10pt;
        }

        p {
            color: black;
            font-family: Calibri;
            font-size: 11pt;
        }

        cnumber {
            padding: 4px;
            color: steelblue;
            font-weight: bold;
        }
    </style>
</head>

<body style="background-color:azure;">
    <hr>
    <h1>Consignment Number<cnumber>| 0031615 | </cnumber>
    </h1>
    <hr>
    <p>Hello</p>
    <p>Please can you advise when my package will arrive. Payment was made for a Saturday Delivery but at present it
        has not been delivered.</p>
    <p>As requested on the website, I have tried to contact you with a query by calling the APC Overnight Delivery Depot
        on <strong>01268 776402</strong> and I have also emailed using the address
        <strong>depot219@apc-overnight.com</strong>
    </p>
    <p>Despite trying to call for 2 hours, the phone was constantly engaged and I have not yet received a response to my
        email.</p>

    <p>The tracking information as previously advised states that the consignment was at the depot for delivery on
        Saturday morning but has not arrived and not contact has been made to advise why it has not been delivered.</p>

    <h2>Consignment Summary</h2>
    <pre>
        Consignment Number: 0031615
        Dispatch Date: 02 Dec 2022
        Number of Parcels/Items: 1
        Total Weight (kg): 5.9
        Consignment Service Code: ND16 (Next Business Day Standard Parcel)
        Sender's Reference: SO230726/IF250429
    </pre>

    <h2>Parcel Journey</h2>
    <pre>
        At Sending Depot (02 Dec 2022 18:16:28)
        At Hub (02 Dec 2022 23:51:14)
        At Delivery Depot (03 Dec 2022 06:57:16)
    </pre>
    <p>Please can you provide some sort of update to the tracking information and advise why this package was not
        delivered? As I have run out of patience and have not been able to talk to anyone, I have setup an automated
        task to email regularly for an update until such time as I receive a response.</p>
    <p>Regards</p>
    <br>

    <div>
        <table>
            <tbody>
                <td valign="top" style="border:none;border-right:solid darkgray 1.5pt;padding:0cm 11.25pt 0cm 0cm">
                    <table>
                        <tbody>

                            <p style="margin:0cm;font-size:11pt;font-family:Calibri, sans-serif">
                                <b><span style="font-size: 10pt; color: darkslategray ">Luke Leigh</span></b>
                            </p>
                </td>
                </tr>
            </tbody>
        </table>
        </td>
        <td style="padding:0cm 0cm 0cm 11.25pt">
            <table>
                <tbody>

                    <p style="margin:0cm;font-size:11pt;font-family:Calibri, sans-serif">
                        <b>
                            <span style="font-size: 10pt; color: darkslategray ">Mob:</span></b>
                        <span style="font-size: 10pt; font-family: Calibri">
                            <a href="tel:07977532524" target="_blank">
                                <span style="color: rgb(103, 156, 255)">07977 532524</span></a>
                    </p>
        </td>
        <tr>
            <p style="margin:0cm;font-size:11pt;font-family:Calibri, sans-serif">
                <b><span style="font-size: 10pt; color: darkslategray ">Email:</span></b>
                <span style="font-size: 10pt; font-family: Calibri">
                    <a href="mailto:luke@leigh-services.com" target="_blank">
                        <span style="color: rgb(103, 156, 255) ">luke@leigh-services.com</span></a>
                    <span style="font-size: 10pt; color: darkslategray "><br>
                        <b><span style="font-size: 10pt; color: darkslategray ">Blog:</span></b>
                        <span style="font-size: 10pt; font-family: Calibri">
                            <a href="https://blog.lukeleigh.com/" target="_blank">
                                <span style="color: rgb(103, 156, 255) ">blog.lukeleigh.com</span></a>
                            <span style="font-size:10.0pt;font-family:Calibri;font-family:Times New Roman;"><br>
                                <b><span style="color: darkslategray ">Scripts:</span></b>
                                <span style="font-size: 10pt; font-family: Calibri">
                                    <a href="https://scripts.lukeleigh.com/" target="_blank">
                                        <span style="color: rgb(103, 156, 255) ">scripts.lukeleigh.com</span></a>
            </p>
            <p style="margin:0cm;font-size:11pt;font-family:Calibri, sans-serif">
                <b><span style="font-size: 10pt; color: darkslategray">Website:</span></b>
                <span style="font-size: 10pt; font-family: Calibri">
                    <a href="https://www.leigh-services.com/" target="_blank">
                        <span style="color: rgb(103, 156, 255) "></span>www.leigh-services.com</span></a>
            </p>
        </tr>
        </tbody>
        </table>
        </td>
        </tr>
        </tbody>
        </table>
        <p style="margin: 0cm; font-size: 11pt; font-family: Calibri, sans-serif; background-color: rgb(51, 51, 51) "
            data-ogsb="white
        <p style=" margin: 0cm; font-size: 11pt; font-family: Calibri, sans-serif;><i><span
                    style="font-size: 8pt; font-family: Consolas; color: rgb(255, 255, 255)"><br>Those who forget to
                    script are doomed to repeat their work.<br></span></i></p>
</body>

</html>
"@

$Credential = [System.Management.Automation.PSCredential]::new("luke@leigh-services.com", (ConvertTo-SecureString -String "IamGroot.3188" -AsPlainText -Force))
$To = "luke@leigh-services.com"
# $CCList = ""
# $BCCList = ""
$Subject = "Undelivered Parcel - Consignment 0031615"
$SmtpServer = "smtp.office365.com"
$From = "luke+stroppy@leigh-services.com"
$Port = "587" # or '25' if not using TLS

$mailParams = @{
    RecipientList                  = $To
    # CCList                         = $CCList
    # Bcc                            = $BCCList
    From                           = $From
    Subject                        = $Subject
    HTMLBody                       = $Content
    SMTPServer                     = $SMTPserver
    Port                           = $Port
    UseSecureConnectionIfAvailable = $true
    ErrorAction                    = 'Stop'
}
Send-MailKitMessage -Credential $Credential @mailParams

<#

$Credential = Get-Office365Credentials
$To = "luke@leigh-services.com"
# $CCList = ""
# $BCCList = ""
$Subject = "Undelivered Parcel - Consignment 0031615"
$SmtpServer = "leighservices-com01c.mail.protection.outlook.com"
$From = "luke+stroppy@leigh-services.com"
# $Port = "587" # or '25' if not using TLS

$mailParams = @{
    RecipientList                  = $To
    # CCList                         = $CCList
    # Bcc                            = $BCCList
    From                           = $From
    Subject                        = $Subject
    HTMLBody                       = $Content
    SMTPServer                     = $SMTPserver
    # Port                           = $Port
    UseSecureConnectionIfAvailable = $true
    ErrorAction                    = 'Stop'
}
Send-MailKitMessage -Credential $Credential @mailParams

#>