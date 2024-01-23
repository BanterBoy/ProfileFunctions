function Connect-toMSGraphApplicationWithCertificate {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (

        [Parameter(Mandatory = $true, HelpMessage = "Enter the MSGraph tenant ID.")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if ($_ -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') { $true } else { throw "Invalid TenantId format. It should be a GUID." }
            })]
        [string]
        $TenantId,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the MSGraph client ID.")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if ($_ -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') { $true } else { throw "Invalid ClientId format. It should be a GUID." }
            })]
        [string]
        $ClientId,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the certificate name.")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if ($_ -match '^[a-zA-Z0-9 *?]+$') { $true } else { throw "Invalid CertName format. It should be an alphanumeric string with optional spaces and wildcard characters." }
            })]
        [string]
        $CertName
    )

    $InformationPreference = "Continue"
    
    if ($PSCmdlet.ShouldProcess("Connecting to MSGraph with Application: $ClientId")) {
        try {
            $CertificateThumbprint = (Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -match $CertName }).Thumbprint
            if (!$CertificateThumbprint) {
                throw "Certificate with name $CertName not found in the CurrentUser\My store."
            }
            Connect-MgGraph -ClientId $ClientID -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint
            Write-Verbose "Connected to MSGraph with ClientId: $ClientId and CertificateThumbprint: $CertificateThumbprint at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        }
        catch {
            Write-Error "Failed to connect to MSGraph: $_"
        }
    }
}
