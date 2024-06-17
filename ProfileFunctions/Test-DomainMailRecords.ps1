function Test-DomainMailRecords {
    param (
        [string]$DomainName,
        [string]$DnsServer
    )

    if ($DomainName -and $DnsServer) {
        Find-MXRecord -DomainName $DomainName -DnsServer $DnsServer
        Find-SPFRecord -DomainName $DomainName -DnsServer $DnsServer
        Find-DKIMRecord -DomainName $DomainName -DnsServer $DnsServer
        Find-DMARCRecord -DomainName $DomainName -DnsServer $DnsServer
    }
}

# $DomainName = @("c2crail.net", "thetraindriveracademy.netdimensions.com", "raildeliverygroup.com", "pc-mail.peopleclick.eu.com", "thetraindriveracademy.com")
$DnsServer = "8.8.8.8"

foreach ($Domain in $DomainName) {
    Test-DomainMailRecords -DomainName $Domain -DnsServer $DnsServer
}
