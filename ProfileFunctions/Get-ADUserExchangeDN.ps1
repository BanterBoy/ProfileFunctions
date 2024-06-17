function Get-ADUserExchangeDN {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Identity
    )
    
    # Retrieve the user details
    try {
        $user = Get-ADUser -Identity $Identity -Properties proxyAddresses, legacyExchangeDN, mail, EmailAddress -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to retrieve user $Identity from Active Directory. $_"
        return
    }

    # Initialize an ordered dictionary to store user details and proxy addresses
    $summary = [ordered]@{
        Name              = $user.Name
        SamAccountName    = $user.SamAccountName
        UserPrincipalName = $user.UserPrincipalName
        Mail              = $user.Mail
        EmailAddress      = $user.EmailAddress
        LegacyExchangeDN  = $user.legacyExchangeDN
    }

    # Extract and process proxy addresses
    $x500Addresses = $user.proxyAddresses | Where-Object { $_ -like "x500:/o=ExchangeLabs*" }
    $legacyDN = $user.legacyExchangeDN
    $count = 1

    # Add non-x500 addresses to the summary
    foreach ($address in $user.proxyAddresses | Where-Object { $_ -notlike "x500:/o=ExchangeLabs*" }) {
        $summary.Add("proxyAddress$count", $address)
        $count++
    }

    # Identify the true duplicate x500 addresses
    $x500Bases = $x500Addresses | ForEach-Object { $_.Split('/')[-1] }
    $duplicates = @()

    foreach ($address in $x500Addresses) {
        $addressBase = $address.Split('/')[-1]
        if ($legacyDN -like "*$addressBase*") {
            $duplicates += $address
        }
        else {
            $summary.Add("proxyAddress$count", $address)
            $count++
        }
    }

    # Mark only the true duplicates for removal
    foreach ($address in $duplicates) {
        $summary.Add("proxyAddress$count", "REMOVE: $address")
        $count++
    }

    # Output the summary object
    return [PSCustomObject]$summary
}
