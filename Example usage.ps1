# Example usage
$mailContactObject = New-MailContactObject -Name "Kurtis Marsden" -Alias "KurtisMarsdenRDG" -FirstName "Kurtis" -LastName "Marsden" -Title "IT Manager" -Department "IT and Facilities" -Company "Rail Delivery Group Ltd" -StreetAddress "1 Puddle Dock" -City "London" -StateOrProvince "Greater London" -PostalCode "EC4V 3DS" -CountryOrRegion "GB" -Phone "+44 20 7841 8000" -MobilePhone "+44 7442 691933" -ExternalEmailAddress "kurtis.marsden@raildeliverygroup.com" -EmailAddress "kurtis.marsden@raildeliverygroup.com" -Groups @("Group1", "Group2")

# Display the mail contact object
$mailContactObject | Format-List

# Migrate the contact to Exchange Online
Set-MailContactDetailsOnline -ContactDetails $mailContactObject -UpdateExisting

$mailContactObject = @{
    Name                 = "Jeff Jefferty"
    Alias                = "JeffJefferty"
    FirstName            = "Jeff"
    LastName             = "Jefferty"
    Title                = "Chief Clown"
    Department           = "Clowns"
    Company              = "Clown Enterprises"
    StreetAddress        = "1 Jefferty Road"
    City                 = "Jeff Ville"
    StateOrProvince      = "Jefferton"
    PostalCode           = "CL0 WN1"
    CountryOrRegion      = "GB"
    Phone                = "+44 12 1234 1234"
    MobilePhone          = "+44 1234 123456"
    ExternalEmailAddress = "jeff.jefferty@example.com"
    EmailAddress         = "jeff.jefferty@example.com"
}



# Example usage
$mailContactObject = New-Object -TypeName PSObject -Property @{
    Identity             = "jeff.jefferty@example.com"
    Name                 = "Jeff Jefferty"
    Alias                = "JeffJefferty"
    FirstName            = "Jeff"
    LastName             = "Jefferty"
    Title                = "Chief Clown"
    Department           = "Clowns"
    Company              = "Clown Enterprises"
    StreetAddress        = "1 Jefferty Road"
    City                 = "Jeff Ville"
    StateOrProvince      = "Jefferton"
    PostalCode           = "CL0 WN1"
    CountryOrRegion      = "GB"
    Phone                = "+44 12 1234 1234"
    MobilePhone          = "+44 1234 123456"
    ExternalEmailAddress = "jeff.jefferty@example.com"
    EmailAddress         = "jeff.jefferty@example.com"
    DisplayName          = "Jeff Jefferty" # Ensure DisplayName is set
    AssistantName        = "Assistant Name"
    Initials             = "JJ"
    Office               = "Office 101"
    TelephoneAssistant   = "+44 12 3456 7890"
    WebPage              = "https://example.com"
    Notes                = "Notes about Jeff Jefferty"
}

Set-MailContactDetailsOnline -ContactDetails $mailContactObject -UpdateExisting -Verbose

