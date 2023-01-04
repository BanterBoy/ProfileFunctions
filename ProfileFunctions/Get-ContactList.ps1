function Get-ContactList {

    [CmdletBinding(DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        HelpUri = 'http://scripts.lukeleigh.com/')]
    [OutputType([string], ParameterSetName = 'Default')]
    [Alias('gcl')]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the name/s of the Distribution Group/s to export.')]
        [Alias('gn')]
        [string[]]$GroupName
    )

    begin {
    }

    process {
        if ($PSCmdlet.ShouldProcess("Target", "Operation")) {
            $DistributionGroups = Get-DistributionGroup -Filter " Name -like '$GroupName' "  | Select-Object -Property Name, DisplayName, GroupType, PrimarySmtpAddress
            foreach ($DistributionGroup in $DistributionGroups) { 
                $Group = Get-DistributionGroup $($DistributionGroup.Name) | Select-Object -Property *
                $Members = Get-DistributionGroupMember -Identity $Group.Name
                foreach ($Member in $Members) {
                    try {
                        $properties = [ordered]@{
                            GroupName               = $Group.DisplayName
                            GroupDescription        = $Group.Description
                            GroupSamAccountName     = $Group.SamAccountName
                            GroupManagedBy          = $Group.ManagedBy
                            GroupPrimarySmtpAddress = $Group.PrimarySmtpAddress
                            MemberName              = $Member.Name
                            MemberSamAccountName    = $Member.SamAccountName
                            DisplayName             = $Member.DisplayName
                            Title                   = $Member.Title
                            Company                 = $Member.Company
                            Manager                 = $Member.Manager
                            Identity                = $Member.Identity
                            PrimarySmtpAddress      = $Member.PrimarySmtpAddress
                            ExternalEmailAddress    = $Member.ExternalEmailAddress
                            WindowsEmailAddress     = $Member.WindowsEmailAddress
                            RecipientTypeDetails    = $Member.RecipientTypeDetails
                        }
                    }
                    catch [System.Exception] {
                        Write-Error -Message $_
                    }
                    finally {
                        $obj = New-Object PSObject -Property $properties
                        Write-Output $obj
                    }
                }
            }
        }
    }

    end {
    }

}