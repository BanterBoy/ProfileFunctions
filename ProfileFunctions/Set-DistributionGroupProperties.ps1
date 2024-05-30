function Set-DistributionGroupProperties {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Group')]
        [PSObject]$DistributionGroup
    )

    begin {
        Write-Verbose "Starting Set-DistributionGroupProperties function"
    }

    process {
        try {
            $PrimarySmtpAddress = $DistributionGroup.PrimarySmtpAddress
            Write-Verbose "Working on Group: $($DistributionGroup.Name)"

            if ($PSCmdlet.ShouldProcess("Distribution Group: $($DistributionGroup.Name)", "Set properties")) {
                Set-DistributionGroup -Identity $DistributionGroup.NEWName -Name $DistributionGroup.Name -Alias $DistributionGroup.Alias -DisplayName $DistributionGroup.DisplayName -PrimarySmtpAddress $PrimarySmtpAddress -HiddenFromAddressListsEnabled $false
                Write-Verbose "Properties set for Group: $($DistributionGroup.Name)"
            }

            if ($PSCmdlet.ShouldProcess("Distribution Group: $($DistributionGroup.Name)", "Remove new primary SMTP address")) {
                Set-DistributionGroup -Identity $DistributionGroup.PrimarySmtpAddress -EmailAddresses @{remove = $DistributionGroup.NEWPrimarySmtpAddress }
                Write-Verbose "New primary SMTP address removed for Group: $($DistributionGroup.Name)"
            }

            if ($PSCmdlet.ShouldProcess("Distribution Group: $($DistributionGroup.Name)", "Add full address")) {
                Set-DistributionGroup -Identity $DistributionGroup.PrimarySmtpAddress -EmailAddresses @{Add = $DistributionGroup.FULLADDRESS }
                Write-Verbose "Full address added for Group: $($DistributionGroup.Name)"
            }

            if ($PSCmdlet.ShouldProcess("Distribution Group: $($DistributionGroup.Name)", "Add x500 address")) {
                $LegacyExchangeDN = "x500:" + $DistributionGroup.LegacyExchangeDN
                Set-DistributionGroup $DistributionGroup.PrimarySmtpAddress -EmailAddresses @{Add = $LegacyExchangeDN }
                Write-Verbose "x500 address added for Group: $($DistributionGroup.Name)"
            }
        }
        catch {
            Write-Error "An error occurred: $_"
        }
    }

    end {
        Write-Verbose "Ending Set-DistributionGroupProperties function"
    }
}

# You can use the `Import-Csv` cmdlet to read the CSV file and then pipe the results to the `Set-DistributionGroupProperties` function. Here's an example:
# Import-Csv -Path 'path_to_your_csv_file.csv' | Set-DistributionGroupProperties
# Replace `'path_to_your_csv_file.csv'` with the actual path to your CSV file. This command will read each line of the CSV file as a custom object, and these objects will be passed to the `Set-DistributionGroupProperties` function.
# Please ensure that the CSV file has the appropriate columns that match the properties expected by the `Set-DistributionGroupProperties` function. For instance, the CSV file should have columns for `PrimarySmtpAddress`, `Name`, `NEWName`, `Alias`, `DisplayName`, `NEWPrimarySmtpAddress`, `FULLADDRESS`, and `LegacyExchangeDN`.
# Also, remember to navigate to the directory where the `Set-DistributionGroupProperties` function is defined before running the command, or include the full path to the function if it's saved in a separate script file.

