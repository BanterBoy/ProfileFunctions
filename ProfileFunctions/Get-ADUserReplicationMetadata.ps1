function Get-ADUserReplicationMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateScript({Get-ADUser -Filter {SamAccountName -eq $_} -ErrorAction SilentlyContinue})]
        [string]$UserIdentity,  # Username (SamAccountName)

        [Parameter(Mandatory=$false, Position=1)]
        [ValidateSet("proxyAddresses", "title", "mail", "displayName", "department", "company", "description", "otherMailbox")]
        [string]$AttributeName = "proxyAddresses",  # Attribute to check replication metadata

        [Parameter(Mandatory=$false, Position=2)]
        [ValidateScript({Get-ADDomainController -Identity $_ -ErrorAction SilentlyContinue})]
        [string]$ReferenceDC = "RDGLONALDIDC001",  # Known working domain controller

        [Parameter(Mandatory=$false, Position=3)]
        [int]$Hours = 1  # Time range filter (default: last 1 hour)
    )

    # Get all domain controllers
    $domainControllers = Get-ADDomainController -Filter * | Where-Object { $_.HostName -notlike 'RDGDC01*' } | Select-Object -ExpandProperty HostName

    if (-not $domainControllers) {
        Write-Error "No domain controllers found!"
        return
    }

    # Retrieve the Distinguished Name (DN) for the user
    try {
        $dn = (Get-ADUser -Identity $UserIdentity -Server $ReferenceDC).DistinguishedName
        if (-not $dn) {
            Write-Error "User '$UserIdentity' not found on reference DC '$ReferenceDC'."
            return
        }
    } catch {
        Write-Error "Error retrieving user '$UserIdentity' from '$ReferenceDC': $_"
        return
    }

    # Initialize results array
    $results = @()

    # Query each DC for replication metadata
    foreach ($dc in $domainControllers) {
        Write-Verbose "Querying DC: $dc..."

        try {
            $metadata = Get-ADReplicationAttributeMetadata -Object $dn -Server $dc -ShowAllLinkedValues |
                        Where-Object { $_.AttributeName -eq $AttributeName -and ($_.LastOriginatingChangeTime -ge (Get-Date).AddHours(-$Hours)) }

            if ($metadata) {
                $metadata | ForEach-Object {
                    $results += [PSCustomObject]@{
                        DomainController = $dc
                        AttributeName    = $_.AttributeName
                        AttributeValue   = ($_.AttributeValue -join ", ") -replace "`n", ", " # Clean up multi-line values
                        LastChangeTime   = $_.LastOriginatingChangeTime
                        Version          = $_.Version
                    }
                }
            } else {
                Write-Warning "No replication data found on $dc"
            }
        } catch {
            Write-Error "Error querying DC '$dc': $_"
        }
    }

    # Output results
    if ($results) {
        $results | Sort-Object LastChangeTime -Descending | Format-Table -AutoSize
    } else {
        Write-Warning "No replication changes found for '$AttributeName' in the last $Hours hours."
    }
}
