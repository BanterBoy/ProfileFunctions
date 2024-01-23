function Get-MgMFAStatus {
  <#
.Synopsis
  Get the MFA status for all users or a single user with Microsoft Graph

.DESCRIPTION
  This script will get the Azure MFA Status for your users. You can query all the users, admins only or a single user.
   
	It will return the MFA Status, MFA type and registered devices.

  Note: Default MFA device is currently not supported https://docs.microsoft.com/en-us/graph/api/resources/authenticationmethods-overview?view=graph-rest-beta
        Hardwaretoken is not yet supported

.NOTES
  Name: Get-MgMFAStatus
  Author: R. Mens - LazyAdmin.nl
  Version: 1.1
  DateCreated: Jun 2022
  Purpose/Change: Add Directory.Read.All scope

.LINK
  https://lazyadmin.nl

.EXAMPLE
  Get-MgMFAStatus

  Get the MFA Status of all enabled and licensed users and check if there are an admin or not

.EXAMPLE
  Get-MgMFAStatus -UserPrincipalName 'johndoe@contoso.com','janedoe@contoso.com'

  Get the MFA Status for the users John Doe and Jane Doe

.EXAMPLE
  Get-MgMFAStatus -withOutMFAOnly

  Get only the licensed and enabled users that don't have MFA enabled

.EXAMPLE
  Get-MgMFAStatus -adminsOnly

  Get the MFA Status of the admins only

.EXAMPLE
  Get-MgUser -Filter "country eq 'Netherlands'" | ForEach-Object { Get-MgMFAStatus -UserPrincipalName $_.UserPrincipalName }

  Get the MFA status for all users in the Country The Netherlands. You can use a similar approach to run this
  for a department only.

.EXAMPLE
  Get-MgMFAStatus -withOutMFAOnly| Export-CSV c:\temp\userwithoutmfa.csv -noTypeInformation

  Get all users without MFA and export them to a CSV file
#>

  [CmdletBinding(DefaultParameterSetName = "Default")]
  param(
    [Parameter(
      Mandatory = $false,
      ParameterSetName = "UserPrincipalName",
      HelpMessage = "Enter a single UserPrincipalName or a comma separted list of UserPrincipalNames",
      Position = 0
    )]
    [string[]]$UserPrincipalName,

    [Parameter(
      Mandatory = $false,
      ValueFromPipeline = $false,
      ParameterSetName = "AdminsOnly"
    )]
    # Get only the users that are an admin
    [switch]$adminsOnly = $false,

    [Parameter(
      Mandatory = $false,
      ValueFromPipeline = $false,
      ParameterSetName = "Licensed"
    )]
    # Check only the MFA status of users that have license
    [switch]$IsLicensed = $false,

    [Parameter(
      Mandatory = $false,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true,
      ParameterSetName = "withOutMFAOnly"
    )]
    # Get only the users that don't have MFA enabled
    [switch]$withOutMFAOnly = $false,

    [Parameter(
      Mandatory = $false,
      ValueFromPipeline = $false
    )]
    # Check if a user is an admin. Set to $false to skip the check
    [switch]$listAdmins = $false,

    [Parameter(
      Mandatory = $false,
      HelpMessage = "Enter path to save the CSV file"
    )]
    [string]$path = ".\MFAStatus-$((Get-Date -format "MMM-dd-yyyy").ToString()).csv"
  )

  Function Get-MgAdmins {
    <#
  .SYNOPSIS
    Get all user with an Admin role
  #>
    process {
      $admins = Get-MgDirectoryRole | Select-Object DisplayName, Id | 
      ForEach-Object -Process { $role = $_.DisplayName; Get-MgDirectoryRoleMember -DirectoryRoleId $_.id | 
        Where-Object -FilterScript { $_.AdditionalProperties."@odata.type" -eq "#microsoft.graph.user" } | 
        ForEach-Object -Process { Get-MgUser -userid $_.id }
      } | 
      Select-Object -Property @{Name = "Role"; Expression = { $role } }, DisplayName, UserPrincipalName, Mail, Id | Sort-Object -Property Mail -Unique
    
      return $admins
    }
  }

  Function Get-Users {
    <#
  .SYNOPSIS
    Get users from the requested DN
  #>
    process {
      # Set the properties to retrieve
      $select = @(
        'id',
        'DisplayName',
        'userprincipalname',
        'mail'
      )

      $properties = $select + "AssignedLicenses"

      # Get enabled, disabled or both users
      switch ($enabled) {
        "true" { $filter = "AccountEnabled eq true and UserType eq 'member'" }
        "false" { $filter = "AccountEnabled eq false and UserType eq 'member'" }
        "both" { $filter = "UserType eq 'member'" }
      }
    
      # Check if UserPrincipalName(s) are given
      if ($UserPrincipalName) {
        Write-Output "Get users by name"

        $users = @()
        foreach ($user in $UserPrincipalName) {
          try {
            $users += Get-MgUser -UserId $user -Property $properties | Select-Object -Property $select -ErrorAction Stop
          }
          catch {
            [PSCustomObject]@{
              DisplayName       = " - Not found"
              UserPrincipalName = $User
              isAdmin           = $null
              MFAEnabled        = $null
            }
          }
        }
      }
      elseif ($adminsOnly) {
        Write-Output "Get admins only"

        $users = @()
        foreach ($admin in $admins) {
          $users += Get-MgUser -UserId $admin.UserPrincipalName -Property $properties | Select-Object $select
        }
      }
      else {
        if ($IsLicensed) {
          # Get only licensed users
          $users = Get-MgUser -Filter $filter -Property $properties -all | Where-Object { ($_.AssignedLicenses).count -gt 0 } | Select-Object $select
        }
        else {
          $users = Get-MgUser -Filter $filter -Property $properties -all | Select-Object $select
        }
      }
      return $users
    }
  }

  Function Get-MFAMethods {
    <#
      .SYNOPSIS
        Get the MFA status of the user
    #>
    param(
      [Parameter(Mandatory = $true)] $userId
    )
    process {
      # Get MFA details for each user
      [array]$mfaData = Get-MgUserAuthenticationMethod -UserId $userId
  
      # Create MFA details object
      $mfaMethods = [PSCustomObject][Ordered]@{
        status                  = "-"
        authApp                 = "-"
        phoneAuth               = "-"
        fido                    = "-"
        helloForBusiness        = "-"
        emailAuth               = "-"
        tempPass                = "-"
        passwordLess            = "-"
        softwareAuth            = "-"
        authDevice              = "-"
        authPhoneNr             = "-"
        SSPREmail               = "-"
        fidoDetails             = "-"
        helloForBusinessDetails = "-"
        tempPassDetails         = "-"
        passwordLessDetails     = "-"
      }
  
      ForEach ($method in $mfaData) {
        Switch ($method.AdditionalProperties["@odata.type"]) {
          "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" { 
            # Microsoft Authenticator App
            $mfaMethods.authApp = $true
            $mfaMethods.authDevice = $method.AdditionalProperties["displayName"] 
            $mfaMethods.status = "enabled"
          } 
          "#microsoft.graph.phoneAuthenticationMethod" { 
            # Phone authentication
            $mfaMethods.phoneAuth = $true
            $mfaMethods.authPhoneNr = $method.AdditionalProperties["phoneType", "phoneNumber"] -join ' '
            $mfaMethods.status = "enabled"
          } 
          "#microsoft.graph.fido2AuthenticationMethod" { 
            # FIDO2 key
            $mfaMethods.fido = $true
            $fifoDetails = $method.AdditionalProperties["model"]
            $mfaMethods.fidoDetails = $fifoDetails
            $mfaMethods.status = "enabled"
          } 
          "#microsoft.graph.passwordAuthenticationMethod" { 
            # Password
            # When only the password is set, then MFA is disabled.
            if ($mfaMethods.status -ne "enabled") { $mfaMethods.status = "disabled" }
          }
          "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" { 
            # Windows Hello
            $mfaMethods.helloForBusiness = $true
            $helloForBusinessDetails = $method.AdditionalProperties["displayName"]
            $mfaMethods.helloForBusinessDetails = $helloForBusinessDetails
            $mfaMethods.status = "enabled"
          } 
          "#microsoft.graph.emailAuthenticationMethod" { 
            # Email Authentication
            $mfaMethods.emailAuth = $true
            $mfaMethods.SSPREmail = $method.AdditionalProperties["emailAddress"] 
            $mfaMethods.status = "enabled"
          }               
          "microsoft.graph.temporaryAccessPassAuthenticationMethod" { 
            # Temporary Access pass
            $mfaMethods.tempPass = $true
            $tempPassDetails = $method.AdditionalProperties["lifetimeInMinutes"]
            $mfaMethods.tempPassDetails = $tempPassDetails
            $mfaMethods.status = "enabled"
          }
          "#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod" { 
            # Passwordless
            $mfaMethods.passwordLess = $true
            $passwordLessDetails = $method.AdditionalProperties["displayName"]
            $mfaMethods.passwordLessDetails = $passwordLessDetails
            $mfaMethods.status = "enabled"
          }
          "#microsoft.graph.softwareOathAuthenticationMethod" { 
            # ThirdPartyAuthenticator
            $mfaMethods.softwareAuth = $true
            $mfaMethods.status = "enabled"
          }
        }
      }
      Return $mfaMethods
    }
  }

  Function Get-Manager {
    <#
    .SYNOPSIS
      Get the manager users
  #>
    param(
      [Parameter(Mandatory = $true)] $userId
    )
    process {
      $manager = Get-MgUser -UserId $userId -ExpandProperty manager | Select-Object @{Name = 'name'; Expression = { $_.Manager.AdditionalProperties.displayName } }
      return $manager.name
    }
  }

  Function Get-MFAStatusUsers {
    <#
    .SYNOPSIS
      Get all AD users
  #>
    process {

      # Collect users
      $users = Get-Users
    
      # Collect and loop through all users
      $users | ForEach-Object {
      
        $mfaMethods = Get-MFAMethods -userId $_.id
        $manager = Get-Manager -userId $_.id

        if ($withOutMFAOnly) {
          if ($mfaMethods.status -eq "disabled") {
            [PSCustomObject]@{
              "Name"            = $_.DisplayName
              Emailaddress      = $_.mail
              UserPrincipalName = $_.UserPrincipalName
              isAdmin           = if ($listAdmins -and ($admins.UserPrincipalName -match $_.UserPrincipalName)) { $true } else { "-" }
              MFAEnabled        = $false
              "Phone number"    = $mfaMethods.authPhoneNr
              "Email for SSPR"  = $mfaMethods.SSPREmail
            }
          }
        }
        else {
          [pscustomobject]@{
            "Name"                  = $_.DisplayName
            Emailaddress            = $_.mail
            UserPrincipalName       = $_.UserPrincipalName
            isAdmin                 = if ($listAdmins -and ($admins.UserPrincipalName -match $_.UserPrincipalName)) { $true } else { "-" }
            "MFA Status"            = $mfaMethods.status
            # "MFA Default type" = ""  - Not yet supported by MgGraph
            "Phone Authentication"  = $mfaMethods.phoneAuth
            "Authenticator App"     = $mfaMethods.authApp
            "Passwordless"          = $mfaMethods.passwordLess
            "Hello for Business"    = $mfaMethods.helloForBusiness
            "FIDO2 Security Key"    = $mfaMethods.fido
            "Temporary Access Pass" = $mfaMethods.tempPass
            "Authenticator device"  = $mfaMethods.authDevice
            "Phone number"          = $mfaMethods.authPhoneNr
            "Email for SSPR"        = $mfaMethods.SSPREmail
            "Manager"               = $manager
          }
        }
      }
    }
  }

  # Get Admins
  # Get all users with admin role
  $admins = $null

  if (($listAdmins) -or ($adminsOnly)) {
    $admins = Get-MgAdmins
  } 

  # Get MFA Status
  Get-MFAStatusUsers | Sort-Object Name | Export-CSV -Path $path -NoTypeInformation

}
