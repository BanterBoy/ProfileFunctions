<#
.SYNOPSIS
    Tests the mail records (MX, SPF, DKIM, DMARC) for a given domain using a specified DNS server.

.DESCRIPTION
    This function queries the MX, SPF, DKIM, and DMARC records for a specified domain using a given DNS server.
    It returns a custom object containing the results of these queries.

.PARAMETER DomainName
    The domain name for which the mail records are to be tested. This parameter is mandatory.

.PARAMETER DnsServer
    The DNS server to be used for the queries. If not specified, the default value of "1.1.1.1" will be used.

.EXAMPLE
    Test-DomainMailRecords -DomainName "example.com"

    This example tests the mail records for the domain "example.com" using the default DNS server.

.EXAMPLE
    Test-DomainMailRecords -DomainName "example.com" -DnsServer "8.8.8.8"

    This example tests the mail records for the domain "example.com" using the DNS server "8.8.8.8".

.NOTES
    Author: Your Name
    Date: Today's Date

#>

function Test-DomainMailRecords {
    [CmdletBinding()]
    param (
        # Domain name to be tested
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$DomainName,

        # DNS server to be used for the queries
        [Parameter(Mandatory = $false)]
        [string]$DnsServer = "1.1.1.1"
    )

    begin {
        Write-Verbose "Starting to test mail records for domain: $DomainName using DNS server: $DnsServer"
    }

    process {
        # Initialize the result object with default values
        $result = [PSCustomObject]@{
            DomainName  = $DomainName
            MXRecords   = $null
            SPFRecord   = $null
            Selector    = $null
            DKIMRecords = @()
            DMARCRecord = $null
            MX          = $null
            IPAddress   = $null
            QueryServer = $DnsServer
        }

        # Query MX records
        try {
            Write-Verbose "Querying MX records for $DomainName using DNS server $DnsServer"
            $mxRecords = Find-MXRecord -DomainName $DomainName -DnsServer $DnsServer
            if ($mxRecords) {
                $result.MXRecords = $mxRecords.MX
                $result.MX = $mxRecords.MX
                $result.IPAddress = $mxRecords.IPAddress
                Write-Verbose "MX records found: $($mxRecords.MX -join ', ')"
            }
        }
        catch {
            Write-Warning "Failed to query MX records for {$DomainName}: $_"
        }

        # Query SPF record
        try {
            Write-Verbose "Querying SPF record for $DomainName using DNS server $DnsServer"
            $spfRecord = Find-SPFRecord -DomainName $DomainName -DnsServer $DnsServer
            if ($spfRecord) {
                $result.SPFRecord = $spfRecord.SPF
                Write-Verbose "SPF record found: $spfRecord.SPF"
            }
        }
        catch {
            Write-Warning "Failed to query SPF record for {$DomainName}: $_"
        }

        # Query DKIM records
        try {
            Write-Verbose "Querying DKIM records for $DomainName using DNS server $DnsServer"
            $dkimRecords = Find-DKIMRecord -DomainName $DomainName -DnsServer $DnsServer
            if ($dkimRecords) {
                $result.Selector = $dkimRecords.Selector
                $dkimRecords | ForEach-Object {
                    $result.DKIMRecords += $_.DKIM
                }
                Write-Verbose "DKIM records found: $($dkimRecords.DKIM -join ', ')"
            }
        }
        catch {
            Write-Warning "Failed to query DKIM records for {$DomainName}: $_"
        }

        # Query DMARC record
        try {
            Write-Verbose "Querying DMARC record for $DomainName using DNS server $DnsServer"
            $dmarcRecord = Find-DMARCRecord -DomainName $DomainName -DnsServer $DnsServer
            if ($dmarcRecord) {
                $result.DMARCRecord = $dmarcRecord.DMARC
                Write-Verbose "DMARC record found: $dmarcRecord.DMARC"
            }
        }
        catch {
            Write-Warning "Failed to query DMARC record for {$DomainName}: $_"
        }

        # Return the result object
        $result
    }
}
