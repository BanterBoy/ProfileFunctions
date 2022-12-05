<#
    .SYNOPSIS
    HRDataNewUser.ps1 - New User Automation Script. Automates creation of both Head Office and Store users.
    .DESCRIPTION
    HRDataNewUser.ps1 - New User Automation Script.
    •	This script Automates the creation of both Head Office and Store users. The script reads the contents of the HR Export of new users, cycles through the list and creates an AD Account for each entry.
    •	The required modules are installed and imported - AzureAD, PoshLog, ActiveDirectory, Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore
    •	The data from the HR Export field headings are transposed and additional fields are populated.
    •	New User password is extracted from Secret Store for security.
    •	New User accounts are created in the New Starters OU - OU=New Starters,OU=Disabled Accounts,DC=uk,DC=cruk,DC=net
    •	All user creation is logged.
    •	Log is Emailed to luke.leigh@carpetright.co.uk
    .EXAMPLE
    PS C:\> .\HRDataNewUser.ps1
    Script will run and create Active Directory accounts for all users listed in the export.
    .INPUTS
    None
    .OUTPUTS
    None
    .NOTES
    Author	: Luke Leigh
    Website	: https://blog.lukeleigh.com
    Twitter	: https://twitter.com/luke_leighs
    GitHub  : https://github.com/BanterBoy
#>

$LogFile = "C:\Scripts\Logging\" + ([datetime]::Today).ToShortDateString().replace("/", "-") + "-" + ([datetime]::Now).ToLongTimeString().replace(":", "-") + "-NewUserManualRun.csv"

New-Logger |
Set-MinimumLevel -Value Verbose |
Add-SinkFile -Path $LogFile |
Add-SinkConsole |
Start-Logger

Test-RequiredModules
Import-Module -Name CarpetrightToolkit

$OU = "OU=New Starters,OU=Disabled Accounts,DC=uk,DC=cruk,DC=net"
$Password = Get-Secret -Name NewUser -AsPlainText

$Date = Get-Date (Get-Date).AddDays(-5) -Format dd-MM-yyyy
$FileName = Get-ChildItem -Path ("\\CSOHRSQL01\Teamspirit_files\AD Accounts" + "\STARTERS - $($Date).csv")
$HRStarters = Set-HRDataExporttoAD -FilePath $FileName.FullName

foreach ($item in $HRStarters) {
    # Check to see if the user needs to be Head Office or Store
    # If user will be a Store user proceed
    if ( !($item.ExtensionAttribute2 -eq "SSO") ) {
        # Check to see if the user already exists in AD
        if ( !(Get-CarpetrightUser -EmployeeID $item.employeeID) ) {

            $userSettings = @{
                Name                  = $item.DisplayName;
                GivenName             = $item.Nickname;
                Surname               = $item.Surname;
                DisplayName           = $item.DisplayName;
                SamAccountName        = $item.SamAccountName;
                Title                 = $item.Title;
                Description           = $item.Title;
                Department            = $item.department;
                Company               = $item.Company;
                Office                = $item.Office;
                StreetAddress         = $item.streetAddress;
                City                  = $item.Town;
                State                 = $item.County;
                PostalCode            = $item.PostalCode;
                employeeID            = $item.employeeID;
                UserPrincipalName     = $item.employeeID + "@carpetright.co.uk";
                Country               = "GB";
                HomePage              = $item.WWWHomePage;
                Path                  = $OU;
                AccountPassword       = (ConvertTo-SecureString "$Password" -AsPlainText -Force);
                ChangePasswordAtLogon = $True;
                Enabled               = $false;
            }
            
            New-ADUser @userSettings
    
            Set-ADUser -Identity $item.SamAccountName -Replace @{ "departmentNumber" = "$($item."Department Code")" }
            Set-ADUser -Identity $item.SamAccountName -Add @{ "extensionAttribute1" = "$($item.extensionAttribute1)" }
            Set-ADUser -Identity $item.SamAccountName -Add @{ "extensionAttribute2" = "$($item.extensionAttribute2)" }
            Set-ADUser -Identity $item.SamAccountName -Add @{ "extensionAttribute3" = "$($item.extensionAttribute3)" }
    
            Add-ADGroupMember -Identity "UK All Interact and Glo" -Members $item.SamAccountName

            Write-InfoLog ",NewRetailUser,Created with AD details,$($item.SamAccountName),$($item.GivenName),$($item.Surname),$($item.Title),$($item.employeeID),$($item.DisplayName),$($item.Company),$($item.Office),$($item.Department),$($item.departmentName),$($item.County),$($item.Town),$($item.StreetAddress),$($item.PostalCode),$($item.Country),$($item.Website),$($item.cn),$($item.Manager)"
    
        }
    
        else {
            # Log details used for User Creation.
            Write-InfoLog ",ExistingUser,A user account with EmployeeID $($item.SamAccountName) already exist in Active Directory."
        }
    
    }

    # If user will be a Head Office user proceed
    else {
        # Check to see if the user already exists in AD
        if ( !(Get-CarpetrightUser -EmployeeID $item.employeeID) ) {

            $userSettings = @{
                Name                  = $item.DisplayName;
                GivenName             = $item.Nickname;
                Surname               = $item.Surname;
                DisplayName           = $item.DisplayName;
                SamAccountName        = $item.SamAccountName;
                Title                 = $item.Title;
                Description           = $item.Title;
                Department            = $item.department;
                Company               = $item.Company;
                Office                = $item.Office;
                StreetAddress         = $item.streetAddress;
                City                  = $item.Town;
                State                 = $item.County;
                PostalCode            = $item.PostalCode;
                employeeID            = $item.employeeID;
                UserPrincipalName     = $item.employeeID + "@carpetright.co.uk";
                Country               = "GB";
                HomePage              = $item.wWWHomePage;
                ScriptPath            = "logon_xp.bat";
                Path                  = $OU;
                AccountPassword       = (ConvertTo-SecureString "$Password" -AsPlainText -Force);
                ChangePasswordAtLogon = $True;
                Enabled               = $false;
            }
            
            New-ADUser @userSettings
            
            Set-ADUser -Identity $item.SamAccountName -Replace @{ "departmentNumber" = "$($item."Department Code")" }
            Set-ADUser -Identity $item.SamAccountName -Add @{ "extensionAttribute1" = "$($item.extensionAttribute1)" }
            Set-ADUser -Identity $item.SamAccountName -Add @{ "extensionAttribute2" = "$($item.extensionAttribute2)" }
            Set-ADUser -Identity $item.SamAccountName -Add @{ "extensionAttribute3" = "$($item.extensionAttribute3)" }

            Add-ADGroupMember -Identity "UK All Interact and Glo" -Members $item.SamAccountName
    
            # Log details used for User Creation.
            Write-InfoLog ",NewSSOUser,Created with AD details,$($item.SamAccountName),$($item.GivenName),$($item.Surname),$($item.Title),$($item.employeeID),$($item.DisplayName),$($item.Company),$($item.Office),$($item.Department),$($item.departmentName),$($item.County),$($item.Town),$($item.StreetAddress),$($item.PostalCode),$($item.Country),$($item.wWWHomePage),$($item.Manager)"
    
        }
    
        else {
            # Check to see if the user already exists in AD
            Write-InfoLog ",ExistingUser,A user account with EmployeeID $($item.SamAccountName) already exist in Active Directory."
        }
            
    }

}

Close-Logger


$Content = @"
<!DOCTYPE html>
<html>
    <head>
        <style>
        h1 {
            color: blue;
            font-family: Calibri;
            font-size: 130%;
        }
        p  {
            color: black;
            font-family: Calibri;
            font-size: 115%;
        }
        </style>
    </head>
    <body>
        <div style="background-color:white;color:white;padding:20px;">
            <h1>New Users have been created - Manual Run</h1>
            <hr>
            <p>New User Password is <strong><span style="border: 1px solid black;padding:4px;color:red;"> $($Password) </span></strong></p>
            <p>Please see attached log.</p>
        </div>
    </body>
</html>
"@

Send-MailKitMessage -RecipientList "luke.leigh@carpetright.co.uk" -From "on-boarding@carpetright.co.uk" -Subject "New Users Processed." -HTMLBody $Content -AttachmentList $LogFile -SMTPServer CSOCAS01 -Port 25
