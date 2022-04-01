function New-OnPremExchangeSession {
    param (
        [Parameter(ValueFromPipeline = $True,
            HelpMessage = "Enter preferred Exchange Server")]
        [ValidateSet('CSOMBXEX03.uk.cruk.net', 'DRMBXEX01.uk.cruk.net', 'CSOCAS01.uk.cruk.net') ]
        [string[]]
        $ComputerName,

        [Parameter(ValueFromPipeline = $True,
            HelpMessage = "Enter your credentials")]
        [pscredential]
        $Credentials

    )
    switch ($ComputerName) {
        CSOCAS01.uk.cruk.net {
            $OnPremSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://CSOCAS01.uk.cruk.net/PowerShell/ -Authentication Kerberos -Credential $Credentials
            Import-PSSession $OnPremSession -DisableNameChecking
        }
        CSOMBXEX03.uk.cruk.net {
            $OnPremSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://CSOMBXEX03.uk.cruk.net/PowerShell/ -Authentication Kerberos -Credential $Credentials
            Import-PSSession $OnPremSession -DisableNameChecking
        }
        DRMBXEX01.uk.cruk.net {
            $OnPremSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://DRMBXEX01.uk.cruk.net/PowerShell/ -Authentication Kerberos -Credential $Credentials
            Import-PSSession $OnPremSession -DisableNameChecking
        }
        default {
            $OnPremSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://CSOCAS01.uk.cruk.net/PowerShell/ -Authentication Kerberos -Credential $Credentials
            Import-PSSession $OnPremSession -DisableNameChecking
        }
    }
}
