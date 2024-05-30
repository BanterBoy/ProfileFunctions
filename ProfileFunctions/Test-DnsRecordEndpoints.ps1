function Test-DnsRecordEndpoints {
    param (
        [psobject[]]$DnsRecords,
        [string]$RootDomain
    )

    $recordPatterns = @{
        SOA   = "(?msi)^(\S+)\s+\S+\s+IN\s+SOA\s+([^\s]+)\s+([^\s]+)\s+\((\s+[\d\s]+)+\)"
        A     = "(?msi)^(\S+)\s+\d+\s+IN\s+A\s+(\S+)"
        TXT   = "(?msi)^(\S+)\s+\d+\s+IN\s+TXT\s+(""[^""]+"")"
        CNAME = "(?msi)^(\S+)\s+\d+\s+IN\s+CNAME\s+(\S+)"
        MX    = "(?msi)^(\S+)\s+\d+\s+IN\s+MX\s+(\d+)\s+(\S+)"
        SRV   = "(?msi)^(\S+)\s+\d+\s+IN\s+SRV\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)"
        NS    = "(?msi)^(\S+)\s+\d+\s+IN\s+NS\s+(\S+)"
    }

    $results = @()

    foreach ($record in $DnsRecords) {
        $resolvedName = if ($record.Name -eq '@') { $RootDomain } else { $record.Name -replace '@', $RootDomain }
        # $resolvedContent = if ($record.Content -match '@') { $record.Content -replace '@', $RootDomain } else { $record.Content }
        $resolvedContent = if ($record.Content -match '[@#%&*]') { $record.Content -replace '[@#%&*]', $RootDomain } else { $record.Content }

        $result = [PSCustomObject]@{
            Type       = $record.Type
            RecordName = $resolvedName
            Content    = $resolvedContent
            Status     = "Not Tested"
            Details    = "No specific test applied."
        }

        switch ($record.Type) {
            "A" {
                if (Test-Connection -ComputerName $resolvedContent -Count 2 -Quiet) {
                    $result.Status = "Active"
                    $result.Details = "IP $resolvedContent is responding."
                }
                else {
                    $result.Status = "Inactive"
                    $result.Details = "IP $resolvedContent is not responding."
                }
            }
            "DMARC" {
                if ($dmarcRecord = Find-DMARCRecord -DomainName raildeliverygroup.com -DNSProvider Cloudflare -ErrorAction Stop) {
                    $result.Status = "Info"
                    $result.Details = "$dmarcRecord.DMARC"
                }
                else {
                    $result.Status = "Failed"
                    $result.Details = "Failed to resolve DMARC"
                }
            }
            "DKIM" {
                if ($dkimRecord = Find-DKIMRecord -DomainName $resolvedContent -DNSProvider Cloudflare -ErrorAction Stop) {
                    $result.Status = "Info"
                    $result.Details = "$dkimRecord.DKIM"
                }
                else {
                    $result.Status = "Failed"
                    $result.Details = "Failed to resolve DMARC"
                }
            }
            "CNAME" {
                try {
                    $resolvedIP = Resolve-DnsName -Name $resolvedContent -Type A -ErrorAction Stop
                    if ($resolvedIP.IPAddress) {
                        if (Test-Connection -ComputerName $resolvedIP.IPAddress -Count 2 -Quiet) {
                            $result.Status = "Active"
                            $result.Details = "IP $($resolvedIP.IPAddress) is responding."
                        }
                        else {
                            $result.Status = "Inactive"
                            $result.Details = "IP $($resolvedIP.IPAddress) is not responding."
                        }
                    }
                    else {
                        $result.Status = "Failed"
                        $result.Details = "Failed to resolve IP address for $resolvedContent."
                    }
                }
                catch {
                    $result.Status = "Failed"
                    $result.Details = "Failed to resolve CNAME record: $_"
                }
            }
            "MX" {
                try {
                    $mxLookup = Find-MxRecord -DomainName $resolvedContent -DNSProvider Cloudflare -ErrorAction Stop
                    $result.Status = "Resolved"
                    $result.Details = "MX record points to $($mxLookup.MX)"
                }
                catch {
                    $result.Status = "Failed"
                    $result.Details = "Failed to resolve $($resolvedContent): $($_.Exception.Message)"
                }
            }
            "TXT" {
                if ($resolvedContent -match '"(spf1)"') {
                    $resolvedContent = $matches[1]
                    if ($spfRecord = Find-SPFRecord -DomainName $resolvedContent -DNSProvider Cloudflare -ErrorAction Stop) {
                        $result.Status = "Info"
                        $result.Details = "$spfRecord.SPF"
                    }
                    else {
                        $result.Status = "Failed"
                        $result.Details = "Failed to resolve $($resolvedContent): $($_.Exception.Message)"
                        }
    
                }
                $result.Status = "Info"
                $result.Details = "TXT record content: '$resolvedContent'"
            }
            "SRV" {
                $result.Status = "Info"
                $result.Details = "$($record.Type) record is present."
            }
            "NS" {
                $result.Status = "Info"
                $result.Details = "$($record.Type) record is present."
            }
            "SOA" {
                $result.Status = "Info"
                $result.Details = "$($record.Type) record is present."
            }
            "WWW" {
                if ($record.Name -like "*www*") {
                    $url = "http://$resolvedContent"
                    try {
                        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10
                        $result.Status = "Reachable"
                        $result.Details = "HTTP status: $($response.StatusCode)"
                    }
                    catch {
                        $result.Status = "Unreachable"
                        $result.Details = "Website $($url) is not reachable: $($_.Exception.Message)"
                    }
                }
            }
            default {
                $result.Status = "Not Applicable"
                $result.Details = "$($record.Type) record type not actively tested."
            }
        }

        $results += $result
    }

    return $results
}

<# Example usage
$RootDomain = "raildeliverygroup.com"
$dnsRecords = Convert-DnsZoneFile -FilePath "C:\GitRepos\Output\DNSMigration\GoDaddyDomains\raildeliverygroup.com.txt"
$results = Test-DnsRecordEndpoints -DnsRecords $dnsRecords -RootDomain $RootDomain
$results | Format-Table -AutoSize
#>
