# Function to create a new mail contact object
function New-MailContactObject {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$EmailAddress,
        [Parameter(Mandatory = $false)]
        [string]$Alias,
        [Parameter(Mandatory = $false)]
        [string]$FirstName,
        [Parameter(Mandatory = $false)]
        [string]$LastName,
        [Parameter(Mandatory = $false)]
        [string]$ExternalEmailAddress,
        [Parameter(Mandatory = $false)]
        [string]$Title,
        [Parameter(Mandatory = $false)]
        [string]$Department,
        [Parameter(Mandatory = $false)]
        [string]$Company,
        [Parameter(Mandatory = $false)]
        [string]$StreetAddress,
        [Parameter(Mandatory = $false)]
        [string]$City,
        [Parameter(Mandatory = $false)]
        [string]$StateOrProvince,
        [Parameter(Mandatory = $false)]
        [string]$PostalCode,
        [Parameter(Mandatory = $false)]
        [string]$CountryOrRegion,
        [Parameter(Mandatory = $false)]
        [string]$Phone,
        [Parameter(Mandatory = $false)]
        [string]$Fax,
        [Parameter(Mandatory = $false)]
        [string]$HomePhone,
        [Parameter(Mandatory = $false)]
        [string]$MobilePhone,
        [Parameter(Mandatory = $false)]
        [string]$Pager,
        [Parameter(Mandatory = $false)]
        [string]$Notes,
        [Parameter(Mandatory = $false)]
        [string]$CustomAttribute1,
        [Parameter(Mandatory = $false)]
        [string]$CustomAttribute2,
        [Parameter(Mandatory = $false)]
        [string]$CustomAttribute3,
        [Parameter(Mandatory = $false)]
        [string]$CustomAttribute4,
        [Parameter(Mandatory = $false)]
        [string]$CustomAttribute5,
        [Parameter(Mandatory = $false)]
        [string]$CustomAttribute6,
        [Parameter(Mandatory = $false)]
        [string]$CustomAttribute7,
        [Parameter(Mandatory = $false)]
        [string]$CustomAttribute8,
        [Parameter(Mandatory = $false)]
        [string]$CustomAttribute9,
        [Parameter(Mandatory = $false)]
        [string]$CustomAttribute10,
        [Parameter(Mandatory = $false)]
        [string]$ExtensionCustomAttribute1,
        [Parameter(Mandatory = $false)]
        [string]$ExtensionCustomAttribute2,
        [Parameter(Mandatory = $false)]
        [string]$ExtensionCustomAttribute3,
        [Parameter(Mandatory = $false)]
        [string]$ExtensionCustomAttribute4,
        [Parameter(Mandatory = $false)]
        [string]$ExtensionCustomAttribute5,
        [Parameter(Mandatory = $false)]
        [string[]]$Groups
    )

    $contactDetails = [PSCustomObject]@{
        DisplayName               = $Name
        EmailAddress              = $EmailAddress
        Alias                     = $Alias
        FirstName                 = $FirstName
        LastName                  = $LastName
        ExternalEmailAddress      = $ExternalEmailAddress
        Title                     = $Title
        Department                = $Department
        Company                   = $Company
        StreetAddress             = $StreetAddress
        City                      = $City
        StateOrProvince           = $StateOrProvince
        PostalCode                = $PostalCode
        CountryOrRegion           = $CountryOrRegion
        Phone                     = $Phone
        Fax                       = $Fax
        HomePhone                 = $HomePhone
        MobilePhone               = $MobilePhone
        Pager                     = $Pager
        Notes                     = $Notes
        CustomAttribute1          = $CustomAttribute1
        CustomAttribute2          = $CustomAttribute2
        CustomAttribute3          = $CustomAttribute3
        CustomAttribute4          = $CustomAttribute4
        CustomAttribute5          = $CustomAttribute5
        CustomAttribute6          = $CustomAttribute6
        CustomAttribute7          = $CustomAttribute7
        CustomAttribute8          = $CustomAttribute8
        CustomAttribute9          = $CustomAttribute9
        CustomAttribute10         = $CustomAttribute10
        ExtensionCustomAttribute1 = $ExtensionCustomAttribute1
        ExtensionCustomAttribute2 = $ExtensionCustomAttribute2
        ExtensionCustomAttribute3 = $ExtensionCustomAttribute3
        ExtensionCustomAttribute4 = $ExtensionCustomAttribute4
        ExtensionCustomAttribute5 = $ExtensionCustomAttribute5
        Groups                    = $Groups -join ";"
    }

    return $contactDetails
}
