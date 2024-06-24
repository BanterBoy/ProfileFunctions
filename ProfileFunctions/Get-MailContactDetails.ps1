# Function to get a single mail contact's detailed information and distribution group memberships
function Get-MailContactDetails {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ContactEmail
    )

    # Get the mail contact
    $mailContact = Get-MailContact -Identity $ContactEmail | Select-Object -Property *

    if ($null -eq $mailContact) {
        Write-Error "Mail contact with email address $ContactEmail not found."
        return $null
    }

    # Get the underlying contact object
    $contact = Get-Contact -Identity $ContactEmail | Select-Object -Property *

    # Get the distribution groups the contact is a member of
    $groups = Get-DistributionGroup -ResultSize Unlimited | Where-Object {
        (Get-DistributionGroupMember -Identity $_.Identity | Where-Object { $_.PrimarySmtpAddress -eq $ContactEmail })
    }

    $groupNames = $groups | Select-Object -ExpandProperty Name -Unique

    # Create a custom object with the contact's detailed information and group memberships
    $contactDetails = [PSCustomObject]@{
        DisplayName               = $mailContact.DisplayName
        EmailAddress              = $mailContact.PrimarySmtpAddress
        Alias                     = $mailContact.Alias
        FirstName                 = $contact.FirstName
        LastName                  = $contact.LastName
        ExternalEmailAddress      = $mailContact.ExternalEmailAddress
        OrganizationalUnit        = $mailContact.OrganizationalUnit
        DistinguishedName         = $mailContact.DistinguishedName
        Title                     = $contact.Title
        Department                = $contact.Department
        Company                   = $contact.Company
        StreetAddress             = $contact.StreetAddress
        City                      = $contact.City
        StateOrProvince           = $contact.StateOrProvince
        PostalCode                = $contact.PostalCode
        CountryOrRegion           = $contact.CountryOrRegion
        Phone                     = $contact.Phone
        Fax                       = $contact.Fax
        HomePhone                 = $contact.HomePhone
        MobilePhone               = $contact.MobilePhone
        Pager                     = $contact.Pager
        Notes                     = $contact.Notes
        CustomAttribute1          = $mailContact.CustomAttribute1
        CustomAttribute2          = $mailContact.CustomAttribute2
        CustomAttribute3          = $mailContact.CustomAttribute3
        CustomAttribute4          = $mailContact.CustomAttribute4
        CustomAttribute5          = $mailContact.CustomAttribute5
        CustomAttribute6          = $mailContact.CustomAttribute6
        CustomAttribute7          = $mailContact.CustomAttribute7
        CustomAttribute8          = $mailContact.CustomAttribute8
        CustomAttribute9          = $mailContact.CustomAttribute9
        CustomAttribute10         = $mailContact.CustomAttribute10
        ExtensionCustomAttribute1 = $mailContact.ExtensionCustomAttribute1
        ExtensionCustomAttribute2 = $mailContact.ExtensionCustomAttribute2
        ExtensionCustomAttribute3 = $mailContact.ExtensionCustomAttribute3
        ExtensionCustomAttribute4 = $mailContact.ExtensionCustomAttribute4
        ExtensionCustomAttribute5 = $mailContact.ExtensionCustomAttribute5
        Groups                    = $groupNames -join ";"
    }

    return $contactDetails
}
