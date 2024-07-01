<#
.SYNOPSIS
    Tests Active Directory replication by creating and deleting a test user.

.DESCRIPTION
    This function creates a test user on a random Domain Controller and then checks if the user is replicated to the specified server within a specified waiting time.

.PARAMETER serverName
    The name of the Domain Controller to test. If not specified, the hostname of the machine running the script will be used.

.PARAMETER waitingTime
    The time in seconds to wait for replication to occur. Default is 900 seconds.

.PARAMETER testOU
    The Organizational Unit (OU) where the test user will be created. If not specified, defaults to the "Users" container of the domain where the script is executed.

.EXAMPLE
    PS C:\> Test-ADReplication -serverName "tatooine" -Verbose
    Starts the AD replication test on the specified server with a waiting time of 15 minutes.

.NOTES
    Author: Your Name
    Date: 2024-06-30
#>

function Test-ADReplication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False, Position = 1)]
        [string]$serverName,
        
        [Parameter(Mandatory = $False, Position = 2)]
        [int]$waitingTime = 900,
        
        [Parameter(Mandatory = $False, Position = 3)]
        [string]$testOU
    )

    function New-SecurePassword {
        param (
            [int]$length = 12,
            [int]$minUpperCase = 1,
            [int]$minLowerCase = 1,
            [int]$minDigits = 1,
            [int]$minSpecialChars = 1
        )

        begin {
            if ($length -lt ($minUpperCase + $minLowerCase + $minDigits + $minSpecialChars)) {
                throw "The length of the password must be greater than or equal to the sum of the minimum number of uppercase, lowercase, digit, and special characters."
            }
        }

        process {
            $upperCase = 65..90 | ForEach-Object { [char]$_ }
            $lowerCase = 97..122 | ForEach-Object { [char]$_ }
            $digits = 48..57 | ForEach-Object { [char]$_ }
            $specialChars = "!@#$%&*()-=+[{]}|;:"

            $passwordChars = @(
                ($upperCase | Get-Random -Count $minUpperCase)
                ($lowerCase | Get-Random -Count $minLowerCase)
                ($digits | Get-Random -Count $minDigits)
                ($specialChars.ToCharArray() | Get-Random -Count $minSpecialChars)
            ) + (($upperCase + $lowerCase + $digits + $specialChars.ToCharArray()) | Get-Random -Count ($length - $minUpperCase - $minLowerCase - $minDigits - $minSpecialChars))

            -join ($passwordChars | Get-Random -Count $length)
        }

        end {}
    }

    ## Init section
    Write-Verbose "Starting DC server sync test"
    
    if (-not $serverName) {
        $serverName = $env:COMPUTERNAME
    }
    Write-Verbose "DC name: $serverName"
    
    # Determine the default testOU if not specified
    if (-not $testOU) {
        $domainDN = (Get-ADDomain).DistinguishedName
        $testOU = "CN=Users,$domainDN"
    }
    Write-Verbose "Test OU: $testOU"
    
    $dCList = (Get-ADForest).Domains | ForEach-Object { Get-ADDomainController -Filter * -Server $_ } | Select-Object -ExpandProperty Name
    
    if ($dCList -notcontains $serverName) {
        Write-Error "The server $serverName is not a Domain Controller"
        return
    }

    $defaultPasswordPolicy = Get-ADDefaultDomainPasswordPolicy

    $password = New-SecurePassword -length $defaultPasswordPolicy.MinPasswordLength `
        -minUpperCase 1 `
        -minLowerCase 1 `
        -minDigits 1 `
        -minSpecialChars 1
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force

    $testUserName = "DC_" + $serverName + "_test"
    $randomDC = $dCList | Where-Object { $_ -ne $serverName } | Get-Random
    Write-Verbose "Random DC selected: $randomDC"
    ## End of init section
            
    # Script body
    Write-Verbose "The test user name is $testUserName"

    # Check if the test user already exists and delete it if it does
    try {
        $existingUser = Get-ADUser -Identity $testUserName -Server $randomDC -ErrorAction Stop
        if ($existingUser) {
            Write-Verbose "Test user $testUserName already exists. Deleting it..."
            Remove-ADUser -Identity $testUserName -Server $randomDC -Confirm:$false
            Write-Verbose "Test user $testUserName deleted."
        }
    }
    catch {
        Write-Verbose "Test user $testUserName does not exist on $randomDC. Proceeding with creation."
    }
    
    try {
        New-ADUser -Name $testUserName -SamAccountName $testUserName -UserPrincipalName "$testUserName@domain.local" -Path $testOU -AccountPassword $securePassword -Enabled $true -PasswordNeverExpires $true -CannotChangePassword $true -Server $randomDC
        Write-Verbose "Test user $testUserName created on $randomDC"
    }
    catch {
        Write-Error "Failed to create test user $testUserName on {$randomDC}: $_"
        return
    }
    
    Start-Sleep -Seconds 1
    
    if (Get-ADUser -Identity $testUserName -Server $randomDC -ErrorAction SilentlyContinue) {
        Write-Output "Test user $testUserName successfully created on $randomDC"
    }
    else {
        Write-Error "There was an issue with the test account $testUserName creation on $randomDC"
        return
    }
    
    Get-Date
    Write-Verbose "Waiting for $waitingTime seconds for replication"
    Start-Sleep -Seconds $waitingTime
    Get-Date

    # Check if the user exists on the target server after replication time
    try {
        $userExistsOnTarget = Get-ADUser -Identity $testUserName -Server $serverName -ErrorAction Stop
        Write-Output "$serverName test successful. Deleting the test user $testUserName"
        Remove-ADUser -Identity $testUserName -Server $serverName -Confirm:$false
        Write-Output "The test user $testUserName has been successfully deleted from $serverName"
    }
    catch {
        Write-Error "Cannot find the test user $testUserName on $serverName. There might be an AD replication issue."
    }

    # Clean up on the source server if needed
    try {
        $userExistsOnSource = Get-ADUser -Identity $testUserName -Server $randomDC -ErrorAction Stop
        Write-Verbose "Cleaning up the test user $testUserName from $randomDC."
        Remove-ADUser -Identity $testUserName -Server $randomDC -Confirm:$false
        Write-Output "The test user $testUserName has been successfully deleted from $randomDC"
    }
    catch {
        Write-Verbose "Test user $testUserName does not exist on $randomDC during clean-up."
    }
    
    # Verbose output indicating the end of the function
    Write-Verbose "DC server sync test completed."
}

# Example call to the function with verbose output
# Test-ADReplication -serverName "tatooine" -Verbose
