function Add-SMEADGroupWithUsers {
<#

.SYNOPSIS
Adds a member to one or more Active Directory groups.

.DESCRIPTION
Adds a member to one or more Active Directory groups.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountNameGroup,
    [Parameter(Mandatory = $true)]
    [String[]]
    $SamAccountNameUsers
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Add-ADGroupMember -Identity $SamAccountNameGroup -Members $SamAccountNameUsers
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main
}
## [END] Add-SMEADGroupWithUsers ##
function Add-SMEADUserToGroups {
<#

.SYNOPSIS
Adds a member to one or more Active Directory groups.

.DESCRIPTION
Adds a member to one or more Active Directory groups.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountNameUser,
    [Parameter(Mandatory = $true)]
    [String[]]
    $SamAccountNameGroups
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Add-ADPrincipalGroupMembership -Identity $SamAccountNameUser -MemberOf $SamAccountNameGroups
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main

}
## [END] Add-SMEADUserToGroups ##
function Disable-SMEADAccount {
<#

.SYNOPSIS
Disable an AD account.

.DESCRIPTION
Disable an AD account.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Disable-ADAccount -Identity $SamAccountName
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main

}
## [END] Disable-SMEADAccount ##
function Edit-SMEADGroup {
<#

.SYNOPSIS
Edits an AD Group.

.DESCRIPTION
Edits an AD Group.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName,

    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountNameNew,

    [Parameter(Mandatory = $true)]
    [String]
    $GroupScope,

    [Parameter(Mandatory = $true)]
    [String]
    $DisplayName,

    [Parameter(Mandatory = $false)]
    [String]
    $Description,

    [Parameter(Mandatory = $false)]
    [String]
    $GroupCategory,

    [Parameter(Mandatory = $false)]
    [String]
    $mail,

    [Parameter(Mandatory = $false)]
    [String]
    $info
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Identity = $SamAccountName
        DisplayName = $DisplayName
    }

    if ($SamAccountNameNew) {
    $Arg["SamAccountName"] = $SamAccountNameNew;
    }
    if ($GroupScope) {
        $Arg["GroupScope"] = $GroupScope;
    }
    if ($Description) {
        $Arg["Description"] = $Description;
    }
    if ($GroupCategory) {
        $Arg["GroupCategory"] = $GroupCategory;
    }
    if ($mail -or $info) {
        if ($mail -and $info) {
            $Arg["replace"] = @{info=$info; mail=$mail};
        } elseif ($mail) {
            $Arg["replace"] = @{mail=$mail};
        } else {
            $Arg["replace"] = @{info=$info};
        }
    }

    Set-ADGroup @Arg
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        Get-AdGroup -Identity $SamAccountNameNew | Rename-ADObject -NewName $DisplayName
        if ($error) {
            $code = $error[0].Exception.HResult
            @{ status = "error"; code = $code; message = $error }
        } else {
            @{ status = "ok"; }
        }
    }
}

return main
}
## [END] Edit-SMEADGroup ##
function Edit-SMEADUser {
<#

.SYNOPSIS
Edits an AD User.

.DESCRIPTION
Edits an AD User.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName,
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountNameNew,
    [Parameter(Mandatory = $true)]
    [String]
    $Name,
    [Parameter(Mandatory = $false)]
    [String]
    $GivenName,
    [Parameter(Mandatory = $false)]
    [String]
    $SurName,
    [Parameter(Mandatory = $false)]
    [String]
    $UserPrincipalName,
    [Parameter(Mandatory = $false)]
    [Bool]
    $ChangePasswordAtLogon,
    [Parameter(Mandatory = $false)]
    [Bool]
    $CannotChangePassword,
    [Parameter(Mandatory = $false)]
    [Bool]
    $PasswordNeverExpires,
    [Parameter(Mandatory = $false)]
    [Bool]
    $SmartCardLogonRequired,
    [Parameter(Mandatory = $false)]
    [String]
    $AccountExpirationDate,
    [Parameter(Mandatory = $false)]
    [Bool]
    $AccountNeverExpires
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Identity = $SamAccountName
    }

    if ($SamAccountNameNew) {
        $Arg["SamAccountName"] = $SamAccountNameNew;
    }
    if ($GivenName) {
        $Arg["GivenName"] = $GivenName;
    }
    if ($SurName) {
        $Arg["SurName"] = $SurName;
    }
    if ($UserPrincipalName) {
        $Arg["UserPrincipalName"] = $UserPrincipalName;
    }
    $Arg["SmartCardLogonRequired"] = $SmartCardLogonRequired;
    $Arg["CannotChangePassword"] = $CannotChangePassword;
    $Arg["PasswordNeverExpires"] = $PasswordNeverExpires;
    $Arg["ChangePasswordAtLogon"] = $ChangePasswordAtLogon;
    if ($AccountNeverExpires -eq $true) {
        $Arg["Replace"] = @{accountExpires=0};
    } else {
        $Arg["AccountExpirationDate"] = $AccountExpirationDate;
    }

    Set-ADUser @Arg
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        Get-AdUser -Identity $SamAccountNameNew | Rename-ADObject -NewName $Name
        if ($error) {
            $code = $error[0].Exception.HResult
            @{ status = "error"; code = $code; message = $error }
        } else {
            @{ status = "ok"; }
        }
    }

}

return main
}
## [END] Edit-SMEADUser ##
function Edit-SMEADUserId {
<#

.SYNOPSIS
Edits an AD User Id.

.DESCRIPTION
Edits an AD User Id.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName,
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountNameNew,
    [Parameter(Mandatory = $true)]
    [String]
    $Name
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Identity = $SamAccountName
    }

    if ($SamAccountNameNew) {
        $Arg["SamAccountName"] = $SamAccountNameNew;
    }

    Set-ADUser @Arg
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        if ($SamAccountNameNew) {
            Get-AdUser -Identity $SamAccountNameNew | Rename-ADObject -NewName $Name;
            if ($error) {
                $code = $error[0].Exception.HResult
                @{ status = "error"; code = $code; message = $error }
            } else {
                @{ status = "ok"; }
            }
        } else {
            @{ status = "ok"; }
        }
        
    }
}

return main
}
## [END] Edit-SMEADUserId ##
function Enable-SMEADAccount {
<#

.SYNOPSIS
Enable an AD account.

.DESCRIPTION
Enable an AD account.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Enable-ADAccount -Identity $SamAccountName
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
    
}

return main

}
## [END] Enable-SMEADAccount ##
function Get-SMEADComputer {
<#

.SYNOPSIS
Gets computer objects.

.DESCRIPTION
Gets computer objects.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)] 
    [string] 
    $criteriaValue,
    [Parameter(Mandatory = $false)]
    [Int]
    $ResultSetSize = 0
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Filter = "Name -like '$criteriaValue'"
        Properties = "*"
    }

    if($ResultSetSize -gt 0) {
        $Arg["ResultSetSize"] = $ResultSetSize;
    } 

    $properties = @(
        'distinguishedName',
        'name',
        'objectClass',
        'objectGUID',
        'samAccountName', 
        @{l='sid'; e = {$_.sid.value}},
        'userPrincipleName',
        'dnsHostName',
        'enabled',
        'description'
    )

    Get-AdComputer @Arg | Microsoft.PowerShell.Utility\Select-Object -Property $properties
}

###############################################################################
# Script execution starts here.
###############################################################################

if (-not($env:pester)) {
    $module = Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue
    if ($module) {
        return main
    }
    
    return @()
}

}
## [END] Get-SMEADComputer ##
function Get-SMEADDomain {
<#

.SYNOPSIS
Gets domain info.

.DESCRIPTION
Gets domain info.

.ROLE
Administrators

#>

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Get-ADDomain
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main
}
## [END] Get-SMEADDomain ##
function Get-SMEADGroup {
<#

.SYNOPSIS
Gets group objects.

.DESCRIPTION
Gets group objects.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)] 
    [string] 
    $criteriaValue,
    [Parameter(Mandatory = $false)]
    [Int]
    $ResultSetSize = 0
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Filter = "Name -like '$criteriaValue'"
        Properties = "*"
    }

    if($ResultSetSize -gt 0) {
        $Arg["ResultSetSize"] = $ResultSetSize;
    } 

    $properties = @(
        'distinguishedName',
        'name',
        'objectClass',
        'objectGUID',
        'samAccountName', 
        @{l='sid'; e = {$_.sid.value}},
        'groupCategory',
        'groupScope',
        'description'
    )

    Get-ADGroup @Arg | Microsoft.PowerShell.Utility\Select-Object -Property $properties
}

###############################################################################
# Script execution starts here.
###############################################################################

if (-not($env:pester)) {
    $module = Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue
    if ($module) {
        return main
    }
    
    return @()
}


}
## [END] Get-SMEADGroup ##
function Get-SMEADGroupItem {
<#

.SYNOPSIS
Gets group object by strict search.

.DESCRIPTION
Gets group object by strict search.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)] 
    [string] 
    $criteriaValue,
    [Parameter(Mandatory = $false)]
    [Int]
    $ResultSetSize = 0
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

$Arg = @{
    Filter = "Name -eq '$criteriaValue'"
    Properties = "*"
}

if($ResultSetSize -gt 0) {
    $Arg["ResultSetSize"] = $ResultSetSize;
} 

$properties = @(
    'distinguishedName',
    'name',
    'objectClass',
    'objectGUID',
    'samAccountName', 
    @{l='sid'; e = {$_.sid.value}},
    'groupCategory',
    'groupScope',
    'description'
)

Get-ADGroup @Arg | Microsoft.PowerShell.Utility\Select-Object -Property $properties

}
## [END] Get-SMEADGroupItem ##
function Get-SMEADGroupMembershipForUser {
<#

.SYNOPSIS
Gets AD group membership.

.DESCRIPTION
Gets AD group membership.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Get-ADPrincipalGroupMembership -identity $SamAccountName | Microsoft.PowerShell.Utility\Select-Object Name, SamAccountName, 
    @{l='ADDomainServiceFolder';
    e={$_.DistinguishedName.split(',')[2].split('=')[1] +
    '-' + $_.DistinguishedName.split(',')[1].split('=')[1] + 
    '-' + $_.DistinguishedName.split(',')[0].split('=')[1]}}

    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main
}
## [END] Get-SMEADGroupMembershipForUser ##
function Get-SMEADGroupProperties {
<#

.SYNOPSIS
Gets all AD group properties.

.DESCRIPTION
Gets all AD group properties.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Get-ADGroup -identity $SamAccountName -Properties * | 
    Microsoft.PowerShell.Utility\Select-Object *
    
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main
}
## [END] Get-SMEADGroupProperties ##
function Get-SMEADMembersInGroup {
<#

.SYNOPSIS
Gets members in a group.

.DESCRIPTION
Gets members in a group.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Get-ADGroupMember -identity $SamAccountName
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main
}
## [END] Get-SMEADMembersInGroup ##
function Get-SMEADOUItem {
<#

.SYNOPSIS
Gets user object by strict search.

.DESCRIPTION
Gets user object by strict search.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)] 
    [string] 
    $criteriaValue,
    [Parameter(Mandatory = $false)]
    [Int]
    $ResultSetSize = 0
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

$Arg = @{
    Filter = "Name -eq '$criteriaValue'"
    Properties = "*"
}

if($ResultSetSize -gt 0) {
    $Arg["ResultSetSize"] = $ResultSetSize;
} 

$properties = @(
    'name',
    'objectClass',
    'objectGUID',
    'samAccountName', 
    @{l='sid'; e = {$_.sid.value}},
    'userPrincipalName',
    'enabled',
    'description',
    'distinguishedName'
)

Get-ADOrganizationalUnit @Arg | Microsoft.PowerShell.Utility\Select-Object -Property $properties

}
## [END] Get-SMEADOUItem ##
function Get-SMEADObject {
<#

.SYNOPSIS
Gets objects from one level.

.DESCRIPTION
Gets objects from one level.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)] 
    [string] 
    $key,
    [Parameter(Mandatory = $false)] 
    [string] 
    $path,
    [Parameter(Mandatory = $false)]
    [Int]
    $ResultSetSize = 0,
    [Parameter(Mandatory = $false)]
    [string] 
    $filter
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        SearchScope = "OneLevel"
        Filter = "*"
    }
    if ($key -eq 'container') {
        $Arg["Filter"] = "ObjectClass -eq 'container' -or ObjectClass -eq 'organizationalUnit'"
    } elseif ($key -eq 'non-container') {
        $Arg.Remove("Filter");
        $Arg["Filter"] = "ObjectClass -ne 'container'"
    } elseif ($key -eq 'all') {
        $Arg["Filter"] = "*"
    }

    if ($path -ne [string]::empty) {
        $Arg["SearchBase"] = $path
    }

    if ($filter -ne [string]::empty) {
        $Arg["Filter"] = "Name -like '$filter'";
        $Arg["SearchScope"] = "Subtree";
        $Arg.Remove("SearchBase");
    }

    if($ResultSetSize -and $ResultSetSize -gt 0) {
        $Arg["ResultSetSize"] = $ResultSetSize;
    }

    $Arg["properties"] = @(
        'name',
        'distinguishedName',
        'objectClass',
        'objectGUID',
        'description',
        'samAccountName'
    )

    Get-ADObject @Arg
}

return main
}
## [END] Get-SMEADObject ##
function Get-SMEADUser {
<#

.SYNOPSIS
Gets user objects.

.DESCRIPTION
Gets user objects.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)] 
    [string] 
    $criteriaValue,
    [Parameter(Mandatory = $false)]
    [Int]
    $ResultSetSize = 0
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Filter = "Name -like '$criteriaValue'"
        Properties = "*"
    }

    if($ResultSetSize -gt 0) {
        $Arg["ResultSetSize"] = $ResultSetSize;
    } 

    $properties = @(
        'name',
        'objectClass',
        'objectGUID',
        'samAccountName', 
        @{l='sid'; e = {$_.sid.value}},
        'surname',
        'userPrincipalName',
        'enabled',
        'givenName',
        'description',
        'distinguishedName'
    )

    Get-ADUser @Arg | Microsoft.PowerShell.Utility\Select-Object -Property $properties
}

###############################################################################
# Script execution starts here.
###############################################################################

if (-not($env:pester)) {
    $module = Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue
    if ($module) {
        return main
    }
    
    return @()
}

}
## [END] Get-SMEADUser ##
function Get-SMEADUserItem {
<#

.SYNOPSIS
Gets user object by strict search.

.DESCRIPTION
Gets user object by strict search.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)] 
    [string] 
    $criteriaValue,
    [Parameter(Mandatory = $false)]
    [Int]
    $ResultSetSize = 0
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

$Arg = @{
    Filter = "Name -eq '$criteriaValue'"
    Properties = "*"
}

if($ResultSetSize -gt 0) {
    $Arg["ResultSetSize"] = $ResultSetSize;
} 

$properties = @(
    'name',
    'objectClass',
    'objectGUID',
    'samAccountName', 
    @{l='sid'; e = {$_.sid.value}},
    'surname',
    'userPrincipalName',
    'enabled',
    'givenName',
    'description',
    'distinguishedName'
)

Get-ADUser @Arg | Microsoft.PowerShell.Utility\Select-Object -Property $properties

}
## [END] Get-SMEADUserItem ##
function Get-SMEADUserProperties {
<#

.SYNOPSIS
Gets all AD user properties.

.DESCRIPTION
Gets all AD user properties.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Get-ADUser -identity $SamAccountName -Properties * | 
    Microsoft.PowerShell.Utility\Select-Object *
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main
}
## [END] Get-SMEADUserProperties ##
function Get-SMESingleSignon {
<#

.SYNOPSIS
Gets Single sign-on status.

.DESCRIPTION
Gets Single sign-on status.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Get-ADComputer -identity $SamAccountName -Properties * | 
    Microsoft.PowerShell.Utility\Select-Object PrincipalsAllowedToDelegateToAccount
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main
}
## [END] Get-SMESingleSignon ##
function New-SMEADGroup {
<#

.SYNOPSIS
Create a new AD Group.

.DESCRIPTION
Create a new AD Group.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Name,
    [Parameter(Mandatory = $true)]
    [String]
    $GroupScope,
    [Parameter(Mandatory = $false)]
    [String]
    $SamAccountName,
    [Parameter(Mandatory = $false)]
    [String]
    $Description,
    [Parameter(Mandatory = $false)]
    [String]
    $Path
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Name = $Name
    }

    if ($SamAccountName) {
        $Arg["SamAccountName"] = $SamAccountName;
    }
    if ($Description) {
        $Arg["Description"] = $Description;
    }
    if ($GroupScope) {
        $Arg["GroupScope"] = $GroupScope;
    }
    if ($Path) {
        $Arg["Path"] = $Path;
    }

    New-AdGroup @Arg
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
    
}

return main

}
## [END] New-SMEADGroup ##
function New-SMEADOU {
<#

.SYNOPSIS
Create a new AD Organizational Unit.

.DESCRIPTION
Create a new AD Organizational Unit.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Name,
    [Parameter(Mandatory = $true)]
    [Bool]
    $ProtectedFromAccidentalDeletion,
    [Parameter(Mandatory = $false)]
    [String]
    $Description,
    [Parameter(Mandatory = $false)]
    [String]
    $Path
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Name = $Name
    }
    $Arg["ProtectedFromAccidentalDeletion"] = $ProtectedFromAccidentalDeletion;
    if ($Description) {
        $Arg["Description"] = $Description;
    }
    if ($Path) {
        $Arg["Path"] = $Path;
    }
    
    New-ADOrganizationalUnit @Arg
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
    
}

return main

}
## [END] New-SMEADOU ##
function New-SMEADUser {
<#

.SYNOPSIS
Create a new AD User.

.DESCRIPTION
Create a new AD User.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $false)]
    [String]
    $GivenName,
    [Parameter(Mandatory = $false)]
    [String]
    $Surname,
    [Parameter(Mandatory = $false)]
    [String]
    $SamAccountName,  
    [Parameter(Mandatory = $false)]
    [String]
    $AccountPassword,  
    [Parameter(Mandatory = $true)]
    [String]
    $Name,
    [Parameter(Mandatory = $false)]
    [String]
    $Path
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main(
    [String]$name,
    [String]$givenName,
    [String]$surname,
    [String]$samAccountName,
    [String]$accountPassword,
    [String]$path
    ) {
    $Arg = @{
        Name = $name
    }

    if ($GivenName) {
        $Arg["GivenName"] = $givenName;
    }
    if ($Surname) {
        $Arg["Surname"] = $surname;
    }
    if ($SamAccountName) {
        $Arg["SamAccountName"] = $samAccountName;
    }
    # refactor - send secured string
    if ($accountPassword) {
        $Arg["AccountPassword"] = (ConvertTo-SecureString -AsPlainText $AccountPassword -Force);
    }
    if ($Path) {
        $Arg["Path"] = $Path;
    }

    New-AdUser @Arg
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

###############################################################################
# Script execution starts here.
###############################################################################

if (-not($env:pester)) {
    $module = Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue
    if ($module) {
        return main `
        $Name `
        $GivenName `
        $Surname `
        $SamAccountName `
        $AccountPassword `
        $Path
    }
    
    return @()
}
}
## [END] New-SMEADUser ##
function Remove-SMEADComputer {
<#

.SYNOPSIS
Remove an AD Computer.

.DESCRIPTION
Remove an AD Computer.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Identity = $SamAccountName
    }

    Remove-ADComputer @Arg -Confirm:$false
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main

}
## [END] Remove-SMEADComputer ##
function Remove-SMEADGroup {
<#

.SYNOPSIS
Remove an AD Group.

.DESCRIPTION
Remove an AD Group.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $GroupName
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Remove-ADGroup $GroupName -Confirm:$false
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
    
}

return main

}
## [END] Remove-SMEADGroup ##
function Remove-SMEADGroupWithUsers {
<#

.SYNOPSIS
Removes a member from one or more Active Directory groups.

.DESCRIPTION
Removes a member from one or more Active Directory groups.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountNameGroup,
    [Parameter(Mandatory = $true)]
    [String[]]
    $SamAccountNameUsers
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Identity = $SamAccountNameGroup
        Member = $SamAccountNameUsers
    }

    Remove-ADGroupMember @Arg -Confirm:$false
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main
}
## [END] Remove-SMEADGroupWithUsers ##
function Remove-SMEADOU {
<#

.SYNOPSIS
Remove an AD Organizational Unit.

.DESCRIPTION
Remove an AD Organizational Unit.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $DistinguishedName
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Identity = $DistinguishedName
    }

    Remove-ADOrganizationalUnit @Arg -Recursive -Confirm:$false
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main

}
## [END] Remove-SMEADOU ##
function Remove-SMEADUser {
<#

.SYNOPSIS
Remove an AD User.

.DESCRIPTION
Remove an AD User.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Identity = $SamAccountName
    }

    Remove-ADUser @Arg -Confirm:$false
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main

}
## [END] Remove-SMEADUser ##
function Remove-SMEADUserFromGroups {
<#

.SYNOPSIS
Removes a member from one or more Active Directory groups.

.DESCRIPTION
Removes a member from one or more Active Directory groups.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountNameUser,
    [Parameter(Mandatory = $true)]
    [String[]]
    $SamAccountNameGroups
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $Arg = @{
        Identity = $SamAccountNameUser
        MemberOf = $SamAccountNameGroups
    }

    Remove-ADPrincipalGroupMembership @Arg -Confirm:$false
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main
}
## [END] Remove-SMEADUserFromGroups ##
function Remove-SMESingleSignon {
<#

.SYNOPSIS
Removes Single sign-on.

.DESCRIPTION
Removes Single sign-on.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $samAccountNameNode
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $nodeObject = Get-ADComputer -Identity $samAccountNameNode
    Set-ADComputer -Identity $nodeObject -PrincipalsAllowedToDelegateToAccount $null
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main
}
## [END] Remove-SMESingleSignon ##
function Set-SMEADAccidentalDeleteProtection {
<#

.SYNOPSIS
Prevents an AD object from accidental deletion.

.DESCRIPTION
Prevents an AD object from accidental deletion.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName,
    [Parameter(Mandatory = $true)]
    [Bool]
    $isUser,
    [Parameter(Mandatory = $true)]
    [Bool]
    $Protect
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    if ($isUser){
        Get-ADUser -Identity $SamAccountName | Set-ADObject -protectedFromAccidentalDeletion $Protect
    } else {
        Get-ADGroup -Identity $SamAccountName | Set-ADObject -protectedFromAccidentalDeletion $Protect
    }
    
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

###############################################################################
# Script execution starts here.
###############################################################################

if (-not($env:pester)) {
    $module = Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue
    if ($module) {
        return main
    }
    
    return @()
}
}
## [END] Set-SMEADAccidentalDeleteProtection ##
function Set-SMEADAccountPassword {
<#

.SYNOPSIS
Sets AD account password.

.DESCRIPTION
Sets AD account password.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName,
    [Parameter(Mandatory = $true)]
    [String]
    $password
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Set-ADAccountPassword -Identity $SamAccountName -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force)
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main
}
## [END] Set-SMEADAccountPassword ##
function Set-SMEADUserPasswordAtLogon {
	<#

.SYNOPSIS
Sets AD user password at next logon.

.DESCRIPTION
Sets AD user password at next logon.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $SamAccountName
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    Set-ADUser -Identity $SamAccountName -ChangePasswordAtLogon $true
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

return main
}
## [END] Set-SMEADUserPasswordAtLogon ##
function Set-SMESingleSignon {
<#

.SYNOPSIS
Adds Single sign-on when deployed as a Service on Windows Server.

.DESCRIPTION
Adds Single sign-on when deployed as a Service on Windows Server.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $samAccountNameNode,
    [Parameter(Mandatory = $false)]
    [String]
    $samAccountNameGateway
)

Set-StrictMode -Version 5.0
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function main() {
    $nodeObject = Get-ADComputer -Identity $samAccountNameNode
    $gatewayObject = Get-ADComputer -Identity $samAccountNameGateway
    Set-ADComputer -Identity $nodeObject -PrincipalsAllowedToDelegateToAccount $gatewayObject
    if ($error) {
        $code = $error[0].Exception.HResult
        @{ status = "error"; code = $code; message = $error }
    } else {
        @{ status = "ok"; }
    }
}

###############################################################################
# Script execution starts here.
###############################################################################

if (-not($env:pester)) {
    $module = Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue
    if ($module) {
        return main
    }
    
    return @()
}
}
## [END] Set-SMESingleSignon ##
function Get-CimWin32LogicalDisk {
<#

.SYNOPSIS
Gets Win32_LogicalDisk object.

.DESCRIPTION
Gets Win32_LogicalDisk object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_LogicalDisk

}
## [END] Get-CimWin32LogicalDisk ##
function Get-CimWin32NetworkAdapter {
<#

.SYNOPSIS
Gets Win32_NetworkAdapter object.

.DESCRIPTION
Gets Win32_NetworkAdapter object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_NetworkAdapter

}
## [END] Get-CimWin32NetworkAdapter ##
function Get-CimWin32PhysicalMemory {
<#

.SYNOPSIS
Gets Win32_PhysicalMemory object.

.DESCRIPTION
Gets Win32_PhysicalMemory object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_PhysicalMemory

}
## [END] Get-CimWin32PhysicalMemory ##
function Get-CimWin32Processor {
<#

.SYNOPSIS
Gets Win32_Processor object.

.DESCRIPTION
Gets Win32_Processor object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_Processor

}
## [END] Get-CimWin32Processor ##
function Get-ClusterInventory {
<#

.SYNOPSIS
Retrieves the inventory data for a cluster.

.DESCRIPTION
Retrieves the inventory data for a cluster.

.ROLE
Readers

#>

import-module CimCmdlets -ErrorAction SilentlyContinue

# JEA code requires to pre-import the module (this is slow on failover cluster environment.)
import-module FailoverClusters -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Get the name of this computer.

.DESCRIPTION
Get the best available name for this computer.  The FQDN is preferred, but when not avaialble
the NetBIOS name will be used instead.

#>

function getComputerName() {
    $computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object Name, DNSHostName

    if ($computerSystem) {
        $computerName = $computerSystem.DNSHostName

        if ($null -eq $computerName) {
            $computerName = $computerSystem.Name
        }

        return $computerName
    }

    return $null
}

<#

.SYNOPSIS
Are the cluster PowerShell cmdlets installed on this server?

.DESCRIPTION
Are the cluster PowerShell cmdlets installed on this server?

#>

function getIsClusterCmdletAvailable() {
    $cmdlet = Get-Command "Get-Cluster" -ErrorAction SilentlyContinue

    return !!$cmdlet
}

<#

.SYNOPSIS
Get the MSCluster Cluster CIM instance from this server.

.DESCRIPTION
Get the MSCluster Cluster CIM instance from this server.

#>
function getClusterCimInstance() {
    $namespace = Get-CimInstance -Namespace root/MSCluster -ClassName __NAMESPACE -ErrorAction SilentlyContinue

    if ($namespace) {
        return Get-CimInstance -Namespace root/mscluster MSCluster_Cluster -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object fqdn, S2DEnabled
    }

    return $null
}


<#

.SYNOPSIS
Determines if the current cluster supports Failover Clusters Time Series Database.

.DESCRIPTION
Use the existance of the path value of cmdlet Get-StorageHealthSetting to determine if TSDB 
is supported or not.

#>
function getClusterPerformanceHistoryPath() {
    return $null -ne (Get-StorageSubSystem clus* | Get-StorageHealthSetting -Name "System.PerformanceHistory.Path")
}

<#

.SYNOPSIS
Get some basic information about the cluster from the cluster.

.DESCRIPTION
Get the needed cluster properties from the cluster.

#>
function getClusterInfo() {
    $returnValues = @{}

    $returnValues.Fqdn = $null
    $returnValues.isS2DEnabled = $false
    $returnValues.isTsdbEnabled = $false

    $cluster = getClusterCimInstance
    if ($cluster) {
        $returnValues.Fqdn = $cluster.fqdn
        $isS2dEnabled = !!(Get-Member -InputObject $cluster -Name "S2DEnabled") -and ($cluster.S2DEnabled -eq 1)
        $returnValues.isS2DEnabled = $isS2dEnabled

        if ($isS2DEnabled) {
            $returnValues.isTsdbEnabled = getClusterPerformanceHistoryPath
        } else {
            $returnValues.isTsdbEnabled = $false
        }
    }

    return $returnValues
}

<#

.SYNOPSIS
Are the cluster PowerShell Health cmdlets installed on this server?

.DESCRIPTION
Are the cluster PowerShell Health cmdlets installed on this server?

s#>
function getisClusterHealthCmdletAvailable() {
    $cmdlet = Get-Command -Name "Get-HealthFault" -ErrorAction SilentlyContinue

    return !!$cmdlet
}
<#

.SYNOPSIS
Are the Britannica (sddc management resources) available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) available on the cluster?

#>
function getIsBritannicaEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_Cluster -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Are the Britannica (sddc management resources) virtual machine available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) virtual machine available on the cluster?

#>
function getIsBritannicaVirtualMachineEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_VirtualMachine -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Are the Britannica (sddc management resources) virtual switch available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) virtual switch available on the cluster?

#>
function getIsBritannicaVirtualSwitchEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_VirtualSwitch -ErrorAction SilentlyContinue)
}

###########################################################################
# main()
###########################################################################

$clusterInfo = getClusterInfo

$result = New-Object PSObject

$result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $clusterInfo.Fqdn
$result | Add-Member -MemberType NoteProperty -Name 'IsS2DEnabled' -Value $clusterInfo.isS2DEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsTsdbEnabled' -Value $clusterInfo.isTsdbEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsClusterHealthCmdletAvailable' -Value (getIsClusterHealthCmdletAvailable)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaEnabled' -Value (getIsBritannicaEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaVirtualMachineEnabled' -Value (getIsBritannicaVirtualMachineEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaVirtualSwitchEnabled' -Value (getIsBritannicaVirtualSwitchEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsClusterCmdletAvailable' -Value (getIsClusterCmdletAvailable)
$result | Add-Member -MemberType NoteProperty -Name 'CurrentClusterNode' -Value (getComputerName)

$result

}
## [END] Get-ClusterInventory ##
function Get-ClusterNodes {
<#

.SYNOPSIS
Retrieves the inventory data for cluster nodes in a particular cluster.

.DESCRIPTION
Retrieves the inventory data for cluster nodes in a particular cluster.

.ROLE
Readers

#>

import-module CimCmdlets

# JEA code requires to pre-import the module (this is slow on failover cluster environment.)
import-module FailoverClusters -ErrorAction SilentlyContinue

###############################################################################
# Constants
###############################################################################

Set-Variable -Name LogName -Option Constant -Value "Microsoft-ServerManagementExperience" -ErrorAction SilentlyContinue
Set-Variable -Name LogSource -Option Constant -Value "SMEScripts" -ErrorAction SilentlyContinue
Set-Variable -Name ScriptName -Option Constant -Value $MyInvocation.ScriptName -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Are the cluster PowerShell cmdlets installed?

.DESCRIPTION
Use the Get-Command cmdlet to quickly test if the cluster PowerShell cmdlets
are installed on this server.

#>

function getClusterPowerShellSupport() {
    $cmdletInfo = Get-Command 'Get-ClusterNode' -ErrorAction SilentlyContinue

    return $cmdletInfo -and $cmdletInfo.Name -eq "Get-ClusterNode"
}

<#

.SYNOPSIS
Get the cluster nodes using the cluster CIM provider.

.DESCRIPTION
When the cluster PowerShell cmdlets are not available fallback to using
the cluster CIM provider to get the needed information.

#>

function getClusterNodeCimInstances() {
    # Change the WMI property NodeDrainStatus to DrainStatus to match the PS cmdlet output.
    return Get-CimInstance -Namespace root/mscluster MSCluster_Node -ErrorAction SilentlyContinue | `
        Microsoft.PowerShell.Utility\Select-Object @{Name="DrainStatus"; Expression={$_.NodeDrainStatus}}, DynamicWeight, Name, NodeWeight, FaultDomain, State
}

<#

.SYNOPSIS
Get the cluster nodes using the cluster PowerShell cmdlets.

.DESCRIPTION
When the cluster PowerShell cmdlets are available use this preferred function.

#>

function getClusterNodePsInstances() {
    return Get-ClusterNode -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object DrainStatus, DynamicWeight, Name, NodeWeight, FaultDomain, State
}

<#

.SYNOPSIS
Use DNS services to get the FQDN of the cluster NetBIOS name.

.DESCRIPTION
Use DNS services to get the FQDN of the cluster NetBIOS name.

.Notes
It is encouraged that the caller add their approprate -ErrorAction when
calling this function.

#>

function getClusterNodeFqdn([string]$clusterNodeName) {
    return ([System.Net.Dns]::GetHostEntry($clusterNodeName)).HostName
}

<#

.SYNOPSIS
Writes message to event log as warning.

.DESCRIPTION
Writes message to event log as warning.

#>

function writeToEventLog([string]$message) {
    Microsoft.PowerShell.Management\New-EventLog -LogName $LogName -Source $LogSource -ErrorAction SilentlyContinue
    Microsoft.PowerShell.Management\Write-EventLog -LogName $LogName -Source $LogSource -EventId 0 -Category 0 -EntryType Warning `
        -Message $message  -ErrorAction SilentlyContinue
}

<#

.SYNOPSIS
Get the cluster nodes.

.DESCRIPTION
When the cluster PowerShell cmdlets are available get the information about the cluster nodes
using PowerShell.  When the cmdlets are not available use the Cluster CIM provider.

#>

function getClusterNodes() {
    $isClusterCmdletAvailable = getClusterPowerShellSupport

    if ($isClusterCmdletAvailable) {
        $clusterNodes = getClusterNodePsInstances
    } else {
        $clusterNodes = getClusterNodeCimInstances
    }

    $clusterNodeMap = @{}

    foreach ($clusterNode in $clusterNodes) {
        $clusterNodeName = $clusterNode.Name.ToLower()
        try 
        {
            $clusterNodeFqdn = getClusterNodeFqdn $clusterNodeName -ErrorAction SilentlyContinue
        }
        catch 
        {
            $clusterNodeFqdn = $clusterNodeName
            writeToEventLog "[$ScriptName]: The fqdn for node '$clusterNodeName' could not be obtained. Defaulting to machine name '$clusterNodeName'"
        }

        $clusterNodeResult = New-Object PSObject

        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'FullyQualifiedDomainName' -Value $clusterNodeFqdn
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'Name' -Value $clusterNodeName
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'DynamicWeight' -Value $clusterNode.DynamicWeight
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'NodeWeight' -Value $clusterNode.NodeWeight
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'FaultDomain' -Value $clusterNode.FaultDomain
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'State' -Value $clusterNode.State
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'DrainStatus' -Value $clusterNode.DrainStatus

        $clusterNodeMap.Add($clusterNodeName, $clusterNodeResult)
    }

    return $clusterNodeMap
}

###########################################################################
# main()
###########################################################################

getClusterNodes

}
## [END] Get-ClusterNodes ##
function Get-ServerInventory {
<#

.SYNOPSIS
Retrieves the inventory data for a server.

.DESCRIPTION
Retrieves the inventory data for a server.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0

Import-Module CimCmdlets

<#

.SYNOPSIS
Converts an arbitrary version string into just 'Major.Minor'

.DESCRIPTION
To make OS version comparisons we only want to compare the major and 
minor version.  Build number and/os CSD are not interesting.

#>

function convertOsVersion([string]$osVersion) {
    [Ref]$parsedVersion = $null
    if (![Version]::TryParse($osVersion, $parsedVersion)) {
        return $null
    }

    $version = [Version]$parsedVersion.Value
    return New-Object Version -ArgumentList $version.Major, $version.Minor
}

<#

.SYNOPSIS
Determines if CredSSP is enabled for the current server or client.

.DESCRIPTION
Check the registry value for the CredSSP enabled state.

#>

function isCredSSPEnabled() {
    Set-Variable credSSPServicePath -Option Constant -Value "WSMan:\localhost\Service\Auth\CredSSP"
    Set-Variable credSSPClientPath -Option Constant -Value "WSMan:\localhost\Client\Auth\CredSSP"

    $credSSPServerEnabled = $false;
    $credSSPClientEnabled = $false;

    $credSSPServerService = Get-Item $credSSPServicePath -ErrorAction SilentlyContinue
    if ($credSSPServerService) {
        $credSSPServerEnabled = [System.Convert]::ToBoolean($credSSPServerService.Value)
    }

    $credSSPClientService = Get-Item $credSSPClientPath -ErrorAction SilentlyContinue
    if ($credSSPClientService) {
        $credSSPClientEnabled = [System.Convert]::ToBoolean($credSSPClientService.Value)
    }

    return ($credSSPServerEnabled -or $credSSPClientEnabled)
}

<#

.SYNOPSIS
Determines if the Hyper-V role is installed for the current server or client.

.DESCRIPTION
The Hyper-V role is installed when the VMMS service is available.  This is much
faster then checking Get-WindowsFeature and works on Windows Client SKUs.

#>

function isHyperVRoleInstalled() {
    $vmmsService = Get-Service -Name "VMMS" -ErrorAction SilentlyContinue

    return $vmmsService -and $vmmsService.Name -eq "VMMS"
}

<#

.SYNOPSIS
Determines if the Hyper-V PowerShell support module is installed for the current server or client.

.DESCRIPTION
The Hyper-V PowerShell support module is installed when the modules cmdlets are available.  This is much
faster then checking Get-WindowsFeature and works on Windows Client SKUs.

#>
function isHyperVPowerShellSupportInstalled() {
    # quicker way to find the module existence. it doesn't load the module.
    return !!(Get-Module -ListAvailable Hyper-V -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Determines if Windows Management Framework (WMF) 5.0, or higher, is installed for the current server or client.

.DESCRIPTION
Windows Admin Center requires WMF 5 so check the registey for WMF version on Windows versions that are less than
Windows Server 2016.

#>
function isWMF5Installed([string] $operatingSystemVersion) {
    Set-Variable Server2016 -Option Constant -Value (New-Object Version '10.0')   # And Windows 10 client SKUs
    Set-Variable Server2012 -Option Constant -Value (New-Object Version '6.2')

    $version = convertOsVersion $operatingSystemVersion
    if (-not $version) {
        # Since the OS version string is not properly formatted we cannot know the true installed state.
        return $false
    }

    if ($version -ge $Server2016) {
        # It's okay to assume that 2016 and up comes with WMF 5 or higher installed
        return $true
    }
    else {
        if ($version -ge $Server2012) {
            # Windows 2012/2012R2 are supported as long as WMF 5 or higher is installed
            $registryKey = 'HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine'
            $registryKeyValue = Get-ItemProperty -Path $registryKey -Name PowerShellVersion -ErrorAction SilentlyContinue

            if ($registryKeyValue -and ($registryKeyValue.PowerShellVersion.Length -ne 0)) {
                $installedWmfVersion = [Version]$registryKeyValue.PowerShellVersion

                if ($installedWmfVersion -ge [Version]'5.0') {
                    return $true
                }
            }
        }
    }

    return $false
}

<#

.SYNOPSIS
Determines if the current usser is a system administrator of the current server or client.

.DESCRIPTION
Determines if the current usser is a system administrator of the current server or client.

#>
function isUserAnAdministrator() {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

<#

.SYNOPSIS
Get some basic information about the Failover Cluster that is running on this server.

.DESCRIPTION
Create a basic inventory of the Failover Cluster that may be running in this server.

#>
function getClusterInformation() {
    $returnValues = @{}

    $returnValues.IsS2dEnabled = $false
    $returnValues.IsCluster = $false
    $returnValues.ClusterFqdn = $null

    $namespace = Get-CimInstance -Namespace root/MSCluster -ClassName __NAMESPACE -ErrorAction SilentlyContinue
    if ($namespace) {
        $cluster = Get-CimInstance -Namespace root/MSCluster -ClassName MSCluster_Cluster -ErrorAction SilentlyContinue
        if ($cluster) {
            $returnValues.IsCluster = $true
            $returnValues.ClusterFqdn = $cluster.Fqdn
            $returnValues.IsS2dEnabled = !!(Get-Member -InputObject $cluster -Name "S2DEnabled") -and ($cluster.S2DEnabled -gt 0)
        }
    }

    return $returnValues
}

<#

.SYNOPSIS
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the passed in computer name.

.DESCRIPTION
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the passed in computer name.

#>
function getComputerFqdnAndAddress($computerName) {
    $hostEntry = [System.Net.Dns]::GetHostEntry($computerName)
    $addressList = @()
    foreach ($item in $hostEntry.AddressList) {
        $address = New-Object PSObject
        $address | Add-Member -MemberType NoteProperty -Name 'IpAddress' -Value $item.ToString()
        $address | Add-Member -MemberType NoteProperty -Name 'AddressFamily' -Value $item.AddressFamily.ToString()
        $addressList += $address
    }

    $result = New-Object PSObject
    $result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $hostEntry.HostName
    $result | Add-Member -MemberType NoteProperty -Name 'AddressList' -Value $addressList
    return $result
}

<#

.SYNOPSIS
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the current server or client.

.DESCRIPTION
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the current server or client.

#>
function getHostFqdnAndAddress($computerSystem) {
    $computerName = $computerSystem.DNSHostName
    if (!$computerName) {
        $computerName = $computerSystem.Name
    }

    return getComputerFqdnAndAddress $computerName
}

<#

.SYNOPSIS
Are the needed management CIM interfaces available on the current server or client.

.DESCRIPTION
Check for the presence of the required server management CIM interfaces.

#>
function getManagementToolsSupportInformation() {
    $returnValues = @{}

    $returnValues.ManagementToolsAvailable = $false
    $returnValues.ServerManagerAvailable = $false

    $namespaces = Get-CimInstance -Namespace root/microsoft/windows -ClassName __NAMESPACE -ErrorAction SilentlyContinue

    if ($namespaces) {
        $returnValues.ManagementToolsAvailable = !!($namespaces | Where-Object { $_.Name -ieq "ManagementTools" })
        $returnValues.ServerManagerAvailable = !!($namespaces | Where-Object { $_.Name -ieq "ServerManager" })
    }

    return $returnValues
}

<#

.SYNOPSIS
Check the remote app enabled or not.

.DESCRIPTION
Check the remote app enabled or not.

#>
function isRemoteAppEnabled() {
    Set-Variable key -Option Constant -Value "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\TSAppAllowList"

    $registryKeyValue = Get-ItemProperty -Path $key -Name fDisabledAllowList -ErrorAction SilentlyContinue

    if (-not $registryKeyValue) {
        return $false
    }
    return $registryKeyValue.fDisabledAllowList -eq 1
}

<#

.SYNOPSIS
Check the remote app enabled or not.

.DESCRIPTION
Check the remote app enabled or not.

#>

<#
c
.SYNOPSIS
Get the Win32_OperatingSystem information

.DESCRIPTION
Get the Win32_OperatingSystem instance and filter the results to just the required properties.
This filtering will make the response payload much smaller.

#>
function getOperatingSystemInfo() {
    return Get-CimInstance Win32_OperatingSystem | Microsoft.PowerShell.Utility\Select-Object csName, Caption, OperatingSystemSKU, Version, ProductType
}

<#

.SYNOPSIS
Get the Win32_ComputerSystem information

.DESCRIPTION
Get the Win32_ComputerSystem instance and filter the results to just the required properties.
This filtering will make the response payload much smaller.

#>
function getComputerSystemInfo() {
    return Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | `
        Microsoft.PowerShell.Utility\Select-Object TotalPhysicalMemory, DomainRole, Manufacturer, Model, NumberOfLogicalProcessors, Domain, Workgroup, DNSHostName, Name, PartOfDomain
}

###########################################################################
# main()
###########################################################################

$operatingSystem = getOperatingSystemInfo
$computerSystem = getComputerSystemInfo
$isAdministrator = isUserAnAdministrator
$fqdnAndAddress = getHostFqdnAndAddress $computerSystem
$hostname = hostname
$netbios = $env:ComputerName
$managementToolsInformation = getManagementToolsSupportInformation
$isWmfInstalled = isWMF5Installed $operatingSystem.Version
$clusterInformation = getClusterInformation -ErrorAction SilentlyContinue
$isHyperVPowershellInstalled = isHyperVPowerShellSupportInstalled
$isHyperVRoleInstalled = isHyperVRoleInstalled
$isCredSSPEnabled = isCredSSPEnabled
$isRemoteAppEnabled = isRemoteAppEnabled

$result = New-Object PSObject
$result | Add-Member -MemberType NoteProperty -Name 'IsAdministrator' -Value $isAdministrator
$result | Add-Member -MemberType NoteProperty -Name 'OperatingSystem' -Value $operatingSystem
$result | Add-Member -MemberType NoteProperty -Name 'ComputerSystem' -Value $computerSystem
$result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $fqdnAndAddress.Fqdn
$result | Add-Member -MemberType NoteProperty -Name 'AddressList' -Value $fqdnAndAddress.AddressList
$result | Add-Member -MemberType NoteProperty -Name 'Hostname' -Value $hostname
$result | Add-Member -MemberType NoteProperty -Name 'NetBios' -Value $netbios
$result | Add-Member -MemberType NoteProperty -Name 'IsManagementToolsAvailable' -Value $managementToolsInformation.ManagementToolsAvailable
$result | Add-Member -MemberType NoteProperty -Name 'IsServerManagerAvailable' -Value $managementToolsInformation.ServerManagerAvailable
$result | Add-Member -MemberType NoteProperty -Name 'IsWmfInstalled' -Value $isWmfInstalled
$result | Add-Member -MemberType NoteProperty -Name 'IsCluster' -Value $clusterInformation.IsCluster
$result | Add-Member -MemberType NoteProperty -Name 'ClusterFqdn' -Value $clusterInformation.ClusterFqdn
$result | Add-Member -MemberType NoteProperty -Name 'IsS2dEnabled' -Value $clusterInformation.IsS2dEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsHyperVRoleInstalled' -Value $isHyperVRoleInstalled
$result | Add-Member -MemberType NoteProperty -Name 'IsHyperVPowershellInstalled' -Value $isHyperVPowershellInstalled
$result | Add-Member -MemberType NoteProperty -Name 'IsCredSSPEnabled' -Value $isCredSSPEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsRemoteAppEnabled' -Value $isRemoteAppEnabled

$result

}
## [END] Get-ServerInventory ##
function Install-MMAgent {
<#

.SYNOPSIS
Download and install Microsoft Monitoring Agent for Windows.

.DESCRIPTION
Download and install Microsoft Monitoring Agent for Windows.

.PARAMETER workspaceId
The log analytics workspace id a target node has to connect to.

.PARAMETER workspacePrimaryKey
The primary key of log analytics workspace.

.PARAMETER taskName
The task name.

.ROLE
Readers

#>

param(
    [Parameter(Mandatory = $true)]
    [String]
    $workspaceId,
    [Parameter(Mandatory = $true)]
    [String]
    $workspacePrimaryKey,
    [Parameter(Mandatory = $true)]
    [String]
    $taskName
)

$Script = @'
$mmaExe = Join-Path -Path $env:temp -ChildPath 'MMASetup-AMD64.exe'
if (Test-Path $mmaExe) {
    Remove-Item $mmaExe
}

Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?LinkId=828603 -OutFile $mmaExe

$extractFolder = Join-Path -Path $env:temp -ChildPath 'SmeMMAInstaller'
if (Test-Path $extractFolder) {
    Remove-Item $extractFolder -Force -Recurse
}

&$mmaExe /c /t:$extractFolder
$setupExe = Join-Path -Path $extractFolder -ChildPath 'setup.exe'
for ($i=1; $i -le 10; $i++) {
    if(-Not(Test-Path $setupExe)) {
        sleep -s 6
    }
}

&$setupExe /qn NOAPM=1 ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=0 OPINSIGHTS_WORKSPACE_ID=$workspaceId OPINSIGHTS_WORKSPACE_KEY=$workspacePrimaryKey AcceptEndUserLicenseAgreement=1
'@

$Script = '$workspaceId = ' + "'$workspaceId';" + $Script
$Script = '$workspacePrimaryKey =' + "'$workspacePrimaryKey';" + $Script

$ScriptFile = Join-Path -Path $env:LocalAppData -ChildPath "$taskName.ps1"
$ResultFile = Join-Path -Path $env:temp -ChildPath "$taskName.log"
if (Test-Path $ResultFile) {
    Remove-Item $ResultFile
}

$Script | Out-File $ScriptFile
if (-Not(Test-Path $ScriptFile)) {
    $message = "Failed to create file:" + $ScriptFile
    Write-Error $message
    return #If failed to create script file, no need continue just return here
}

#Create a scheduled task
$User = [Security.Principal.WindowsIdentity]::GetCurrent()
$Role = (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$arg = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -c $ScriptFile >> $ResultFile 2>&1"
if(!$Role)
{
  Write-Warning "To perform some operations you must run an elevated Windows PowerShell console."
}

$Scheduler = New-Object -ComObject Schedule.Service

#Try to connect to schedule service 3 time since it may fail the first time
for ($i=1; $i -le 3; $i++)
{
  Try
  {
    $Scheduler.Connect()
    Break
  }
  Catch
  {
    if($i -ge 3)
    {
      Write-EventLog -LogName Application -Source "SME Register $taskName" -EntryType Error -EventID 1 -Message "Can't connect to Schedule service"
      Write-Error "Can't connect to Schedule service" -ErrorAction Stop
    }
    else
    {
      Start-Sleep -s 1
    }
  }
}

$RootFolder = $Scheduler.GetFolder("\")
#Delete existing task
if($RootFolder.GetTasks(0) | Where-Object {$_.Name -eq $TaskName})
{
  Write-Debug("Deleting existing task" + $TaskName)
  $RootFolder.DeleteTask($TaskName,0)
}

$Task = $Scheduler.NewTask(0)
$RegistrationInfo = $Task.RegistrationInfo
$RegistrationInfo.Description = $TaskName
$RegistrationInfo.Author = $User.Name

$Triggers = $Task.Triggers
$Trigger = $Triggers.Create(7) #TASK_TRIGGER_REGISTRATION: Starts the task when the task is registered.
$Trigger.Enabled = $true

$Settings = $Task.Settings
$Settings.Enabled = $True
$Settings.StartWhenAvailable = $True
$Settings.Hidden = $False
$Settings.ExecutionTimeLimit  = "PT20M" # 20 minutes

$Action = $Task.Actions.Create(0)
$Action.Path = "powershell"
$Action.Arguments = $arg

#Tasks will be run with the highest privileges
$Task.Principal.RunLevel = 1

#Start the task to run in Local System account. 6: TASK_CREATE_OR_UPDATE
$RootFolder.RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $Null, 1) | Out-Null
#Wait for running task finished
$RootFolder.GetTask($TaskName).Run(0) | Out-Null
while($Scheduler.GetRunningTasks(0) | Where-Object {$_.Name -eq $TaskName})
{
  Start-Sleep -s 1
}

#Clean up
$RootFolder.DeleteTask($TaskName,0)
Remove-Item $ScriptFile

if (Test-Path $ResultFile)
{
    Get-Content -Path $ResultFile | Out-String -Stream
    Remove-Item $ResultFile
}

}
## [END] Install-MMAgent ##

# SIG # Begin signature block
# MIIdkgYJKoZIhvcNAQcCoIIdgzCCHX8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDZ+gd2R8qbRaSD9JRdZtmYc0
# mXSgghhuMIIE3jCCA8agAwIBAgITMwAAAPY4DZqG0FykOwAAAAAA9jANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgwODIzMjAyMDAy
# WhcNMTkxMTIzMjAyMDAyWjCBzjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJp
# Y28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkJCRUMtMzBDQS0yREJFMSUwIwYD
# VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEA0Giw6GfheCWtNC7tfKP+uA/fAd/t2GAzfSxnZtbK
# jZlLfEirdj2fJjXZqfaklmMzqwzbOgT63aAizd54b/AHQiOxVD2OSzk0mBW0llgV
# 5LlzxIpf+6RQW2PsAJpLR/Rh0dGW8KY1G7lNzLtYPQ8kTpOp28s2ggf/0ua11lYq
# OBCUy1Tn8l/9nmFEKADOYvcenz9mnEoLEjmLnlYy0rhzoarShF+bwhEjATx8fOT3
# 3old4rl1QgSzCNKrqdg6a/oZbD/fCXHKw+xl+7zLokPNAN/4L9b5PjYPdTcNXdHF
# Usg/5in9dX9SLRiGQCPddr/Xs1Io7TXZh64AergQLW2dtQIDAQABo4IBCTCCAQUw
# HQYDVR0OBBYEFKkpT6AZxNOTNl2kSsN+VDjJX5x8MB8GA1UdIwQYMBaAFCM0+NlS
# RnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly9jcmwubWlj
# cm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY3Jvc29mdFRpbWVTdGFtcFBD
# QS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsGAQUFBzAChjxodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcnQw
# EwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQEFBQADggEBABgpbYMcaVAf
# zA+6Vq9i/qYS0+HfjogCavAVLAA0UUecwe0VdKANoQZgJy3F3URqGMZHsQCke0xl
# 0KtABBMa67PJiLaTchTuncfC44GYi4/gWCxH+pfCHJsPEeGYuESQFbFx8Ay0hyQb
# DjOZAq39VfCtvDizdOd/bapuWGi2GXuiEi+SfeBy3iqkZ/MXX5SNPCnaysjGl/Ju
# CNhAh2xskZvFIrWc8fte4bI72QR7ArOp7dWxrUs747997FoJPlcy91xTiesoxvlf
# G9HIE4HpZyXq9N9kHDKu0ed6j9zao2DEs5xiV8XBTFfcGjgOFlzC87//ycnOnTaQ
# fix0yv3V9yIwggX/MIID56ADAgECAhMzAAABA14lHJkfox64AAAAAAEDMA0GCSqG
# SIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# KDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwHhcNMTgw
# NzEyMjAwODQ4WhcNMTkwNzI2MjAwODQ4WjB0MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNyb3NvZnQgQ29ycG9yYXRpb24w
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDRlHY25oarNv5p+UZ8i4hQ
# y5Bwf7BVqSQdfjnnBZ8PrHuXss5zCvvUmyRcFrU53Rt+M2wR/Dsm85iqXVNrqsPs
# E7jS789Xf8xly69NLjKxVitONAeJ/mkhvT5E+94SnYW/fHaGfXKxdpth5opkTEbO
# ttU6jHeTd2chnLZaBl5HhvU80QnKDT3NsumhUHjRhIjiATwi/K+WCMxdmcDt66Va
# mJL1yEBOanOv3uN0etNfRpe84mcod5mswQ4xFo8ADwH+S15UD8rEZT8K46NG2/Ys
# AzoZvmgFFpzmfzS/p4eNZTkmyWPU78XdvSX+/Sj0NIZ5rCrVXzCRO+QUauuxygQj
# AgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEEAYI3TAgBBggrBgEFBQcDAzAd
# BgNVHQ4EFgQUR77Ay+GmP/1l1jjyA123r3f3QP8wUAYDVR0RBEkwR6RFMEMxKTAn
# BgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMRYwFAYDVQQF
# Ew0yMzAwMTIrNDM3OTY1MB8GA1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKV
# MFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUH
# AQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0T
# AQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAn/XJUw0/DSbsokTYDdGfY5YGSz8e
# XMUzo6TDbK8fwAG662XsnjMQD6esW9S9kGEX5zHnwya0rPUn00iThoj+EjWRZCLR
# ay07qCwVlCnSN5bmNf8MzsgGFhaeJLHiOfluDnjYDBu2KWAndjQkm925l3XLATut
# ghIWIoCJFYS7mFAgsBcmhkmvzn1FFUM0ls+BXBgs1JPyZ6vic8g9o838Mh5gHOmw
# GzD7LLsHLpaEk0UoVFzNlv2g24HYtjDKQ7HzSMCyRhxdXnYqWJ/U7vL0+khMtWGL
# sIxB6aq4nZD0/2pCD7k+6Q7slPyNgLt44yOneFuybR/5WcF9ttE5yXnggxxgCto9
# sNHtNr9FB+kbNm7lPTsFA6fUpyUSj+Z2oxOzRVpDMYLa2ISuubAfdfX2HX1RETcn
# 6LU1hHH3V6qu+olxyZjSnlpkdr6Mw30VapHxFPTy2TUxuNty+rR1yIibar+YRcdm
# stf/zpKQdeTr5obSyBvbJ8BblW9Jb1hdaSreU0v46Mp79mwV+QMZDxGFqk+av6pX
# 3WDG9XEg9FGomsrp0es0Rz11+iLsVT9qGTlrEOlaP470I3gwsvKmOMs1jaqYWSRA
# uDpnpAdfoP7YO0kT+wzh7Qttg1DO8H8+4NkI6IwhSkHC3uuOW+4Dwx1ubuZUNWZn
# cnwa6lL2IsRyP64wggYHMIID76ADAgECAgphFmg0AAAAAAAcMA0GCSqGSIb3DQEB
# BQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJk/IsZAEZFgltaWNy
# b3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMxMzAzMDlaMHcxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJ+h
# bLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn0UytdDAgEesH1VSVFUmUG0KS
# rphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0Zxws/HvniB3q506jocEjU8qN
# +kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4nrIZPVVIM5AMs+2qQkDBuh/NZ
# MJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YRJylmqJfk0waBSqL5hKcRRxQJ
# gp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54QTF3zJvfO4OToWECtR0Nsfz3
# m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8GA1UdEwEB/wQFMAMBAf8wHQYD
# VR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsGA1UdDwQEAwIBhjAQBgkrBgEE
# AYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJgQFYnl+UlE/wq4QpTlVnkpKFj
# pGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jv
# c29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL21pY3Jvc29mdHJvb3Rj
# ZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0Um9vdENlcnQuY3J0MBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBBQUAA4ICAQAQl4rDXANENt3p
# tK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1iuFcCy04gE1CZ3XpA4le7r1ia
# HOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+rkuTnjWrVgMHmlPIGL4UD6ZEq
# JCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGctxVEO6mJcPxaYiyA/4gcaMvnM
# MUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/FNSteo7/rvH0LQnvUU3Ih7jDK
# u3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbonXCUbKw5TNT2eb+qGHpiKe+i
# myk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0NbhOxXEjEiZ2CzxSjHFaRkMU
# vLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPpK+m79EjMLNTYMoBMJipIJF9a
# 6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2JoXZhtG6hE6a/qkfwEm/9ijJs
# sv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0eFQF1EEuUKyUsKV4q7OglnUa
# 2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng9wFlb4kLfchpyOZu6qeXzjEp
# /w7FW1zYTRuh2Povnj8uVRZryROj/TCCB3owggVioAMCAQICCmEOkNIAAAAAAAMw
# DQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eSAyMDExMB4XDTExMDcwODIwNTkwOVoXDTI2MDcwODIxMDkwOVowfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAKvw+nIQHC6t2G6qghBNNLrytlghn0IbKmvpWlCquAY4GgRJun/D
# DB7dN2vGEtgL8DjCmQawyDnVARQxQtOJDXlkh36UYCRsr55JnOloXtLfm1OyCizD
# r9mpK656Ca/XllnKYBoF6WZ26DJSJhIv56sIUM+zRLdd2MQuA3WraPPLbfM6XKEW
# 9Ea64DhkrG5kNXimoGMPLdNAk/jj3gcN1Vx5pUkp5w2+oBN3vpQ97/vjK1oQH01W
# KKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd6IlPhBryoS9Z5JA7La4zWMW3Pv4y
# 07MDPbGyr5I4ftKdgCz1TlaRITUlwzluZH9TupwPrRkjhMv0ugOGjfdf8NBSv4yU
# h7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOnqWbsYR9q4ShJnV+I4iVd0yFLPlLE
# tVc/JAPw0XpbL9Uj43BdD1FGd7P4AOG8rAKCX9vAFbO9G9RVS+c5oQ/pI0m8GLhE
# fEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkwp6uO3+xbn6/83bBm4sGXgXvt1u1L
# 50kppxMopqd9Z4DmimJ4X7IvhNdXnFy/dygo8e1twyiPLI9AN0/B4YVEicQJTMXU
# pUMvdJX3bvh4IFgsE11glZo+TzOE2rCIF96eTvSWsLxGoGyY0uDWiIwLAgMBAAGj
# ggHtMIIB6TAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUSG5k5VAF04KqFzc3
# IrVtqMp1ApUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUci06AjGQQ7kUBU7h6qfHMdEj
# iTQwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
# aS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNybDBe
# BggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNydDCB
# nwYDVR0gBIGXMIGUMIGRBgkrBgEEAYI3LgMwgYMwPwYIKwYBBQUHAgEWM2h0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvZG9jcy9wcmltYXJ5Y3BzLmh0bTBA
# BggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBwAG8AbABpAGMAeQBfAHMAdABh
# AHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAZ/KGpZjgVHkaLtPY
# dGcimwuWEeFjkplCln3SeQyQwWVfLiw++MNy0W2D/r4/6ArKO79HqaPzadtjvyI1
# pZddZYSQfYtGUFXYDJJ80hpLHPM8QotS0LD9a+M+By4pm+Y9G6XUtR13lDni6WTJ
# RD14eiPzE32mkHSDjfTLJgJGKsKKELukqQUMm+1o+mgulaAqPyprWEljHwlpblqY
# luSD9MCP80Yr3vw70L01724lruWvJ+3Q3fMOr5kol5hNDj0L8giJ1h/DMhji8MUt
# zluetEk5CsYKwsatruWy2dsViFFFWDgycScaf7H0J/jeLDogaZiyWYlobm+nt3TD
# QAUGpgEqKD6CPxNNZgvAs0314Y9/HG8VfUWnduVAKmWjw11SYobDHWM2l4bf2vP4
# 8hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1HxS+YWG18NzGGwS+30HHDiju3mUv
# 7Jf2oVyW2ADWoUa9WfOXpQlLSBCZgB/QACnFsZulP0V3HjXG0qKin3p6IvpIlR+r
# +0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9azI2h15q/6/IvrC4DqaTuv/DDtBEyO
# 3991bWORPdGdVk5Pv4BXIqF4ETIheu9BCrE/+6jMpF3BoYibV3FWTkhFwELJm3Zb
# CoBIa/15n8G9bW1qyVJzEw16UM0xggSOMIIEigIBATCBlTB+MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29k
# ZSBTaWduaW5nIFBDQSAyMDExAhMzAAABA14lHJkfox64AAAAAAEDMAkGBSsOAwIa
# BQCggaIwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLziRODn4KoFPZhu3S/x2oDF
# XUQJMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBho
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEAUFA5IaWA
# nUdM4cgdmci2f2W/wlz6SFovj4XyP+jwZJITOkYj5xUYAgBZRm1UIXgqWx2zVF6g
# Ohfdn5E81uY82Mz17YznjL+hAFrU1NT4iUbU1eUCUQG0j8Oqrw9MZ1wv8NDcM/l1
# gfMuXK+ZNlMFLd9rO2uvtVBPwm1IT3qyjbOIg96ekot9tTbP8qEC5QMW3ot9Nqd7
# ofh9uQF6Na3qf6Mqp5Vk1Pz0k8Tzf01Xa9eD3Cw2NaH9L0bwQdBiAXx2snI6MUYo
# qOPED+9DY2yWaFCAyCFpcVE285cUgs7IZeAjwTSxcRihuP9q82y9V4WiIARfaoGe
# R0Du5aCQGE3IW6GCAigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0ECEzMAAAD2OA2ahtBcpDsAAAAAAPYwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE5MDYxMTExMDcyOFowIwYJKoZIhvcNAQkEMRYEFLZhZYwAMXTToLXBxoCZR3+J
# XxG3MA0GCSqGSIb3DQEBBQUABIIBAENotPTXZWYxWO5rRovFmdJq9UMDcRpN7R21
# 4NG7ctR+nuCMDmuvK1UpIG6h0TGKIpwVqk2/zBa9c1WDNXjoyDfWd2MtvfuLLSLm
# P38v6V1y9KQ2WopacEn6bIVi6BLg0cR57TDDhUEpFyFhebTI1OwBzuiswrb6BCcc
# y3AXT7WXBxCJg/L6DLnfBplUagvRRXaBVXdV1+E38OBFZDepdTcPuQWOCI/h9116
# kZWIQLHARt2V8A1VVczXM2QvLY0trM+OaOkOcYOK1r4lpWdv7VO9uDmv3AVTrjGE
# /XjvzkWi18KUOrUyxvpM3FNrYQYAd5IiFZD3dg9pBBK6R06pv+g=
# SIG # End signature block
