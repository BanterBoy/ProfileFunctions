function Repair-MissingOnPremMailbox {
    param (
        [String]
        $SamAccountName
    )
    $ADUserInfo = Get-ADUser -Identity $SamAccountName -Properties *
    $Name = $AdUserInfo.GivenName + "." + $AdUserInfo.Surname
    Set-ADUser -Identity $ADUserInfo.SamAccountName -add @{ProxyAddresses = "SMTP:$($Name)@raildeliverygroup.com,smtp:$($Name)@atoc.mail.onmicrosoft.com" -split "," }
    Enable-RemoteMailbox -Identity $ADUserInfo.SamAccountName-RemoteRoutingAddress "$($Name)@atoc.mail.onmicrosoft.com"
}
