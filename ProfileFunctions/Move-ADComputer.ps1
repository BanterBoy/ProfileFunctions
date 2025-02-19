<#
.SYNOPSIS
    Moves a computer object from one OU to another in Active Directory.

.DESCRIPTION
    This function moves a computer object from one Organizational Unit (OU) to another in Active Directory.
    It accepts pipeline input from Get-ADComputer and outputs the results as a PSObject.

.PARAMETER Computer
    The computer object to be moved. This parameter accepts pipeline input.

.PARAMETER TargetOU
    The target Organizational Unit (OU) where the computer object will be moved.

.EXAMPLE
    Get-ADComputer -Filter * | Move-ADComputer -TargetOU "NewOU"

.NOTES
    Author: Your Name
    Date: 2025-02-19
    Version: 1.2

#>

function Move-ADComputer {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.ActiveDirectory.Management.ADComputer]$Computer,

        [Parameter(Mandatory = $true)]
        [string]$TargetOU
    )

    process {
        if ($PSCmdlet.ShouldProcess("$($Computer.Name) to $TargetOU")) {
            try {
                # Validate the target OU format
                if ($TargetOU -notmatch '^OU=.*') {
                    throw "Invalid TargetOU format. It should be in the format 'OU=Name,DC=domain,DC=com'."
                }

                # Check if the computer exists in AD
                if (-not (Get-ADComputer -Identity $Computer.DistinguishedName -ErrorAction SilentlyContinue)) {
                    throw "Computer $($Computer.Name) does not exist in Active Directory."
                }

                # Move the computer to the target OU
                Move-ADObject -Identity $Computer.DistinguishedName -TargetPath $TargetOU

                # Log the successful move
                Write-Verbose "Successfully moved $($Computer.Name) to $TargetOU"

                # Create a PSObject to output the result
                $result = [PSCustomObject]@{
                    ComputerName = $Computer.Name
                    TargetOU     = $TargetOU
                    Status       = "Success"
                    Message      = "Successfully moved $($Computer.Name) to $TargetOU"
                }
            }
            catch {
                # Log the error
                Write-Error "Failed to move $($Computer.Name): $_"

                # Create a PSObject to output the error
                $result = [PSCustomObject]@{
                    ComputerName = $Computer.Name
                    TargetOU     = $TargetOU
                    Status       = "Failed"
                    Message      = "Failed to move $($Computer.Name): $_"
                }
            }
            # Output the result
            $result
        }
    }
}

# Import the Active Directory module if not already imported
if (-not (Get-Module -Name ActiveDirectory)) {
    Import-Module ActiveDirectory
}