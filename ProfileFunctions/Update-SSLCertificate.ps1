function Update-SSLCertificate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CertPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CertPassword,
        
        [Parameter(Mandatory = $true)]
        [string]$CertName,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Servers
    )
    
    try {
        # Import the PFX certificate to the local machine's personal certificate store
        $newCert = Import-PfxCertificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\My -Password $CertPassword
        
        # Copy the PFX certificate to the specified list of remote servers
        $Servers | ForEach-Object {
            Copy-Item -Path $CertPath -Destination "\\$_\c`$"
        }
        
        # Establish a connection to all of the specified remote servers
        $session = New-PSSession -ComputerName $Servers
        
        # Import the PFX certificate to the personal certificate store on the remote servers
        Invoke-Command -Session $session -ScriptBlock {
            Import-PfxCertificate -FilePath "c:\$using:CertName" -CertStoreLocation Cert:\LocalMachine\My -Password $using:CertPassword
            Remove-Item -Path "c:\$using:CertName"
        }
        
        # Update SSL bindings in IIS to use the new certificate on the local machine and remote servers
        Import-Module WebAdministration
        
        $sites = Get-ChildItem -Path IIS:\Sites
        
        foreach ($site in $sites) {
            foreach ($binding in $site.Bindings.Collection) {
                if ($binding.protocol -eq 'https') {
                    $search = "Cert:\LocalMachine\My\$($binding.certificateHash)"
                    $certs = Get-ChildItem -Path $search -Recurse
                    $hostname = hostname
                    
                    if (($certs.count -gt 0) -and ($certs[0].Subject.StartsWith("CN=$using:CertName"))) {
                        Write-Output "Updating $hostname, site: `"$($site.name)`", binding: `"$($binding.bindingInformation)`", current cert: `"$($certs[0].Subject)`", Expiry Date: `"$($certs[0].NotAfter)`""
                        $binding.AddSslCertificate($newCert.Thumbprint, "my")
                    }
                }
            }
        }
    }
    finally {
        # Clean up the PFX certificate file on the local machine
        Remove-Item -Path $CertPath
    }
}
