$ClientID = '9e1b3c36'
$TenantID = 'ceb371f6'
$ClientSecret = 'NDE'
$Credentials = [pscredential]::new($ClientID, (ConvertTo-SecureString $ClientSecret -AsPlainText -Force))
Connect-MgGraph -ClientSecretCredential $Credentials -TenantId $TenantID -NoWelcome
