function Get-CertificateExpiry {

    [CmdletBinding(DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        HelpUri = 'http://scripts.lukeleigh.com/')]
    [OutputType([string], ParameterSetName = 'Default')]
    [Alias('gcexp')]
    [OutputType([String])]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Enter the Name of the computer you would like to connect to.')]
        [Alias('cn')]
        [string[]]
        $ComputerName = $env:COMPUTERNAME,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter computer name or pipe input'
        )]
        [Alias('cred')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter a text string that you want to search for.')]
        [ValidateNotNullOrEmpty()]
        [Alias('fn')]
        [string]$FriendlyName,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter number of days before expiry.')]
        [ValidateNotNullOrEmpty()]
        [Alias('ds')]
        [int]$Days,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            HelpMessage = 'Check if certificate has expired.')]
        [Alias('ex')]
        [switch]$Expired
    )

    begin {

        foreach ($Computer in $ComputerName) {

            if ($null -eq $ComputerName) {

                if ($Days) {

                    if ($Expired) {
    
                        $certchk = Invoke-Command -ComputerName $Computer -Credential $Credential {
                            Get-ChildItem -Path Cert:\* -Recurse -ExpiringInDays 0 | Select-Object -Property * | Where-Object -FilterScript { $_.EnhancedKeyUsageList.FriendlyName -like "*Authentication*" -and $_.Issuer -notlike "CN=MS-Organization-P2P-Access*" } |  Where-Object -FilterScript { $_.FriendlyName -like "$FriendlyName" }
                        }
                    }
                    else {
                    }
                    $certchk = Invoke-Command -ComputerName $Computer -Credential $Credential {
                        Get-ChildItem -Path Cert:\* -Recurse -ExpiringInDays $Days | Select-Object -Property * | Where-Object -FilterScript { $_.EnhancedKeyUsageList.FriendlyName -like "*Authentication*" -and $_.Issuer -notlike "CN=MS-Organization-P2P-Access*" } |  Where-Object -FilterScript { $_.FriendlyName -like "$FriendlyName" }
                    }

                }
                else {
                    $certchk = Invoke-Command -ComputerName $Computer -Credential $Credential {
                        Get-ChildItem -Path Cert:\* -Recurse | Select-Object -Property * | Where-Object -FilterScript { $_.EnhancedKeyUsageList.FriendlyName -like "*Authentication*" -and $_.Issuer -notlike "CN=MS-Organization-P2P-Access*" } |  Where-Object -FilterScript { $_.FriendlyName -like "$FriendlyName" }
                    }
                }

            }
            else {

                if ($Days) {

                    if ($Expired) {
    
                        $certchk = Get-ChildItem -Path Cert:\* -Recurse -ExpiringInDays 0 | Select-Object -Property * | Where-Object -FilterScript { $_.EnhancedKeyUsageList.FriendlyName -like "*Authentication*" -and $_.Issuer -notlike "CN=MS-Organization-P2P-Access*" } |  Where-Object -FilterScript { $_.FriendlyName -like "$FriendlyName" }
                    }
                    else {
                        $certchk = Get-ChildItem -Path Cert:\* -Recurse -ExpiringInDays $Days | Select-Object -Property * | Where-Object -FilterScript { $_.EnhancedKeyUsageList.FriendlyName -like "*Authentication*" -and $_.Issuer -notlike "CN=MS-Organization-P2P-Access*" } |  Where-Object -FilterScript { $_.FriendlyName -like "$FriendlyName" }
                    }

                }
                else {
                    $certchk = Get-ChildItem -Path Cert:\* -Recurse | Select-Object -Property * | Where-Object -FilterScript { $_.EnhancedKeyUsageList.FriendlyName -like "*Authentication*" -and $_.Issuer -notlike "CN=MS-Organization-P2P-Access*" } |  Where-Object -FilterScript { $_.FriendlyName -like "$FriendlyName" }
                }
    
            }

        }

    }

    process {

        if ($PSCmdlet.ShouldProcess($FriendlyName, "Checking expiry date for certificate friendlyname")) {

            foreach ($cert in $certchk) {
                $ExpiryDays = New-timeSpan -Start ($cert.NotAfter)

                if ($ExpiryDays.Days -le $Days) {

                    try {
                        $properties = [ordered]@{
                            FriendlyName     = $cert.FriendlyName
                            NotBefore        = $cert.NotBefore
                            NotAfter         = $cert.NotAfter
                            Subject          = $cert.Subject
                            SubjectName      = $cert.SubjectName
                            ExpireInDays     = $ExpiryDays.Days
                            CertificateStore = ($cert.PSParentPath -split "::")[1]
                            Issuer           = $cert.Issuer
                            ComputerName     = $Computer
                            Thumbprint       = $cert.Thumbprint
                            AuthUse          = $cert.EnhancedKeyUsageList
                            HasPrivateKey    = $cert.HasPrivateKey
                            PrivateKey       = $cert.PrivateKey
                            DnsNameList      = $cert.DnsNameList
                        }
                    }
                    catch {
                        Write-Error -Message $_
                    }
                    finally {
                        $obj = New-Object -TypeName PSObject -Property $properties
                        Write-Output $obj
                    }
                }

            }

        }

    }

    end {

    }

}
# Get-CertificateExpiry -FriendlyName "*.raildeliverygroup.com" -Days 10