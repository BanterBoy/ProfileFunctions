function Disable-CredSspClientRole {
<#

.SYNOPSIS
Disables CredSSP on this client/gateway.

.DESCRIPTION
Disables CredSSP on this client/gateway.

.ROLE
Administrators

.Notes
The feature(s) that use this script are still in development and should be considered as being "In Preview".
Therefore, those feature(s) and/or this script may change at any time.

#>

Set-StrictMode -Version 5.0
Import-Module  Microsoft.WSMan.Management -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Setup all necessary global variables, constants, etc.

.DESCRIPTION
Setup all necessary global variables, constants, etc.

#>

function setupScriptEnv() {
    Set-Variable -Name WsManApplication -Option ReadOnly -Scope Script -Value "wsman"
    Set-Variable -Name CredSSPClientAuthPath -Option ReadOnly -Scope Script -Value "localhost\Client\Auth\CredSSP"
    Set-Variable -Name CredentialsDelegationPolicyPath -Option ReadOnly -Scope Script -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation"
    Set-Variable -Name AllowFreshCredentialsPath -Option ReadOnly -Scope Script -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials"
    Set-Variable -Name AllowFreshCredentialsPropertyName -Option ReadOnly -Scope Script -Value "AllowFreshCredentials"
}

<#

.SYNOPSIS
Clean up all added global variables, constants, etc.

.DESCRIPTION
Clean up all added global variables, constants, etc.

#>

function cleanupScriptEnv() {
    Remove-Variable -Name WsManApplication -Scope Script -Force
    Remove-Variable -Name CredSSPClientAuthPath -Scope Script -Force
    Remove-Variable -Name CredentialsDelegationPolicyPath -Scope Script -Force
    Remove-Variable -Name AllowFreshCredentialsPath -Scope Script -Force
    Remove-Variable -Name AllowFreshCredentialsPropertyName -Scope Script -Force
}

<#

.SYNOPSIS
Is CredSSP client role enabled on this server.

.DESCRIPTION
When the CredSSP client role is enabled on this server then return $true.

#>

function getCredSSPClientEnabled() {
    $path = "{0}:\{1}" -f $WsManApplication, $CredSSPClientAuthPath

    $credSSPClientEnabled = $false;

    $credSSPClientService = Get-Item $path -ErrorAction SilentlyContinue
    if ($credSSPClientService) {
        $credSSPClientEnabled = [System.Convert]::ToBoolean($credSSPClientService.Value)
    }

    return $credSSPClientEnabled
}

<#

.SYNOPSIS
Disable CredSSP

.DESCRIPTION
Attempt to disable the CredSSP Client role and return any error that occurs

#>

function disableCredSSP() {
    $err = $null

    # Catching the result so that we can discard it. Otherwise it get concatinated with $err and we don't want that!
    $result = Disable-WSManCredSSP -Role Client -ErrorAction SilentlyContinue -ErrorVariable +err

    return $err
}

<#

.SYNOPSIS
Main function.

.DESCRIPTION
Main function.

#>

function main() {
    setupScriptEnv
    $results = $null

    # If the client role is disabled then we can stop.
    if (-not (getCredSSPClientEnabled)) {
        $results = $true
    } else {
        $err = disableCredSSP

        if ($err) {
            # If there is an error and the client role is not enabled return success.
            if (-not (getCredSSPClientEnabled)) {
                $results = $true
            }

            Write-Error @($err)[0]
            $results = $false
        }
    }

    cleanupScriptEnv

    return $results
}

###############################################################################
# SCcript execution starts here...
###############################################################################
$results = $null

if (-not ($env:pester)) {
    $results = main
}


return $results
    
}
## [END] Disable-CredSspClientRole ##
function Disable-CredSspManagedServer {
<#

.SYNOPSIS
Disables CredSSP on this server.

.DESCRIPTION
Disables CredSSP on this server.

.ROLE
Administrators

.Notes
The feature(s) that use this script are still in development and should be considered as being "In Preview".
Therefore, those feature(s) and/or this script may change at any time.

#>

Set-StrictMode -Version 5.0
Import-Module  Microsoft.WSMan.Management -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Is CredSSP client role enabled on this server.

.DESCRIPTION
When the CredSSP client role is enabled on this server then return $true.

#>

function getCredSSPClientEnabled() {
    Set-Variable credSSPClientPath -Option Constant -Value "WSMan:\localhost\Client\Auth\CredSSP" -ErrorAction SilentlyContinue

    $credSSPClientEnabled = $false;

    $credSSPClientService = Get-Item $credSSPClientPath -ErrorAction SilentlyContinue
    if ($credSSPClientService) {
        $credSSPClientEnabled = [System.Convert]::ToBoolean($credSSPClientService.Value)
    }

    return $credSSPClientEnabled
}

<#

.SYNOPSIS
Disable CredSSP

.DESCRIPTION
Attempt to disable the CredSSP Client role and return any error that occurs

#>

function disableCredSSPClientRole() {
    $err = $null

    # Catching the result so that we can discard it. Otherwise it get concatinated with $err and we don't want that!
    $result = Disable-WSManCredSSP -Role Client -ErrorAction SilentlyContinue -ErrorVariable +err

    return $err
}

<#

.SYNOPSIS
Disable the CredSSP client role on this server.

.DESCRIPTION
Disable the CredSSP client role on this server.

#>

function disableCredSSPClient() {
    # If disabled then we can stop.
    if (-not (getCredSSPClientEnabled)) {
        return $null
    }

    $err = disableCredSSPClientRole

    # If there is an error and it is not enabled, then success
    if ($err) {
        if (-not (getCredSSPClientEnabled)) {
            return $null
        }

        return $err
    }

    return $null
}

<#

.SYNOPSIS
Is CredSSP server role enabled on this server.

.DESCRIPTION
When the CredSSP server role is enabled on this server then return $true.

#>

function getCredSSPServerEnabled() {
    Set-Variable credSSPServicePath -Option Constant -Value "WSMan:\localhost\Service\Auth\CredSSP" -ErrorAction SilentlyContinue

    $credSSPServerEnabled = $false;

    $credSSPServerService = Get-Item $credSSPServicePath -ErrorAction SilentlyContinue
    if ($credSSPServerService) {
        $credSSPServerEnabled = [System.Convert]::ToBoolean($credSSPServerService.Value)
    }

    return $credSSPServerEnabled
}

<#

.SYNOPSIS
Disable CredSSP

.DESCRIPTION
Attempt to disable the CredSSP Server role and return any error that occurs

#>

function disableCredSSPServerRole() {
    $err = $null

    # Catching the result so that we can discard it. Otherwise it get concatinated with $err and we don't want that!
    $result = Disable-WSManCredSSP -Role Server -ErrorAction SilentlyContinue -ErrorVariable +err

    return $err
}

function disableCredSSPServer() {
    # If not enabled then we can leave
    if (-not (getCredSSPServerEnabled)) {
        return $null
    }

    $err = disableCredSSPServerRole

    # If there is an error, but the requested functionality completed don't fail the operation.
    if ($err) {
        if (-not (getCredSSPServerEnabled)) {
            return $null
        }

        return $err
    }
    
    return $null
}

<#

.SYNOPSIS
Main function.

.DESCRIPTION
Main function.

#>

function main() {
    $err = disableCredSSPServer
    if ($err) {
        throw $err
    }

    $err = disableCredSSPClient
    if ($err) {
        throw $err
    }

    return $true
}

###############################################################################
# Script execution starts here...
###############################################################################

if (-not ($env:pester)) {
    return main
}

}
## [END] Disable-CredSspManagedServer ##
function Enable-CredSSPClientRole {
<#

.SYNOPSIS
Enables CredSSP on this computer as client role to the other computer.

.DESCRIPTION
Enables CredSSP on this computer as client role to the other computer.

.ROLE
Administrators

.PARAMETER serverNames
The names of the server to which this gateway can forward credentials.

.LINK
https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2018-0886

.LINK
https://aka.ms/CredSSP-Updates

#>

param (
    [Parameter(Mandatory=$True)]
    [string[]]$serverNames
)

Set-StrictMode -Version 5.0
Import-Module  Microsoft.WSMan.Management -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Setup all necessary global variables, constants, etc.

.DESCRIPTION
Setup all necessary global variables, constants, etc.

#>

function setupScriptEnv() {
    Set-Variable -Name WsManApplication -Option ReadOnly -Scope Script -Value "wsman"
    Set-Variable -Name CredSSPClientAuthPath -Option ReadOnly -Scope Script -Value "localhost\Client\Auth\CredSSP"
    Set-Variable -Name CredentialsDelegationPolicyPath -Option ReadOnly -Scope Script -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation"
    Set-Variable -Name AllowFreshCredentialsPath -Option ReadOnly -Scope Script -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials"
    Set-Variable -Name AllowFreshCredentialsPropertyName -Option ReadOnly -Scope Script -Value "AllowFreshCredentials"
    Set-Variable -Name TypeAlreadyExistsHResult -Option ReadOnly -Scope Script -Value -2146233088
    Set-Variable -Name NativeCode -Option ReadOnly -Scope Script -Value @"
    using Microsoft.Win32;
    using System;
    using System.Collections.Generic;
    using System.Globalization;
    using System.Linq;
    using System.Runtime.InteropServices;
    using System.Text;
    using System.Threading;
    
    namespace SME
    {
        public static class LocalGroupPolicy
        {
            [Guid("EA502722-A23D-11d1-A7D3-0000F87571E3")]
            [ComImport]
            [ClassInterface(ClassInterfaceType.None)]
            public class GPClass
            {
            }
    
            [ComImport, Guid("EA502723-A23D-11d1-A7D3-0000F87571E3"),
            InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
            public interface IGroupPolicyObject
            {
                void New(
                    [MarshalAs(UnmanagedType.LPWStr)] string pszDomainName,
                    [MarshalAs(UnmanagedType.LPWStr)] string pszDisplayName,
                    uint dwFlags);
    
                void OpenDSGPO(
                    [MarshalAs(UnmanagedType.LPWStr)] string pszPath,
                    uint dwFlags);
    
                void OpenLocalMachineGPO(uint dwFlags);
    
                void OpenRemoteMachineGPO(
                    [MarshalAs(UnmanagedType.LPWStr)] string pszComputerName,
                    uint dwFlags);
    
                void Save(
                    [MarshalAs(UnmanagedType.Bool)] bool bMachine,
                    [MarshalAs(UnmanagedType.Bool)] bool bAdd,
                    [MarshalAs(UnmanagedType.LPStruct)] Guid pGuidExtension,
                    [MarshalAs(UnmanagedType.LPStruct)] Guid pGuid);
    
                void Delete();
    
                void GetName(
                    [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName,
                    int cchMaxLength);
    
                void GetDisplayName(
                    [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName,
                    int cchMaxLength);
    
                void SetDisplayName(
                    [MarshalAs(UnmanagedType.LPWStr)] string pszName);
    
                void GetPath(
                    [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszPath,
                    int cchMaxPath);
    
                void GetDSPath(
                    uint dwSection,
                    [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszPath,
                    int cchMaxPath);
    
                void GetFileSysPath(
                    uint dwSection,
                    [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszPath,
                    int cchMaxPath);
    
                IntPtr GetRegistryKey(uint dwSection);
    
                uint GetOptions();
    
                void SetOptions(uint dwOptions, uint dwMask);
    
                void GetMachineName(
                    [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName,
                    int cchMaxLength);
    
                uint GetPropertySheetPages(out IntPtr hPages);
            }
    
            private const int GPO_OPEN_LOAD_REGISTRY = 1;
            private const int GPO_SECTION_MACHINE = 2;
            private const string ApplicationName = @"wsman";
            private const string AllowFreshCredentials = @"AllowFreshCredentials";
            private const string ConcatenateDefaultsAllowFresh = @"ConcatenateDefaults_AllowFresh";
            private const string PathCredentialsDelegationPath = @"SOFTWARE\Policies\Microsoft\Windows";
            private const string GPOpath = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy Objects";
            private const string Machine = @"Machine";
            private const string CredentialsDelegation = @"\CredentialsDelegation";
            private const string PoliciesPath = @"Software\Policies\Microsoft\Windows";
            private const string BackSlash = @"\";
    
            public static string EnableAllowFreshCredentialsPolicy(string[] serverNames)
            {
                if (Thread.CurrentThread.GetApartmentState() == ApartmentState.STA)
                {
                    return EnableAllowFreshCredentialsPolicyImpl(serverNames);
                }
                else
                {
                    string value = null;
    
                    var thread = new Thread(() =>
                    {
                        value = EnableAllowFreshCredentialsPolicyImpl(serverNames);
                    });
    
                    thread.SetApartmentState(ApartmentState.STA);
                    thread.Start();
                    thread.Join();
    
                    return value;
                }
            }
    
            public static string RemoveServersFromAllowFreshCredentialsPolicy(string[] serverNames)
            {
                if (Thread.CurrentThread.GetApartmentState() == ApartmentState.STA)
                {
                    return RemoveServersFromAllowFreshCredentialsPolicyImpl(serverNames);
                }
                else
                {
                    string value = null;
    
                    var thread = new Thread(() =>
                    {
                        value = RemoveServersFromAllowFreshCredentialsPolicyImpl(serverNames);
                    });
    
                    thread.SetApartmentState(ApartmentState.STA);
                    thread.Start();
                    thread.Join();
    
                    return value;
                }
            }
    
            private static string EnableAllowFreshCredentialsPolicyImpl(string[] serverNames)
            {
                IGroupPolicyObject gpo = (IGroupPolicyObject)new GPClass();
                gpo.OpenLocalMachineGPO(GPO_OPEN_LOAD_REGISTRY);
    
                var KeyHandle = gpo.GetRegistryKey(GPO_SECTION_MACHINE);
    
                try
                {
                    var rootKey = Registry.CurrentUser;
    
                    using (RegistryKey GPOKey = rootKey.OpenSubKey(GPOpath, true))
                    {
                        foreach (var keyName in GPOKey.GetSubKeyNames())
                        {
                            if (keyName.EndsWith(Machine, StringComparison.OrdinalIgnoreCase))
                            {
                                var key = GPOpath + BackSlash + keyName + BackSlash + PoliciesPath;
    
                                UpdateGpoRegistrySettingsAllowFreshCredentials(ApplicationName, serverNames, Registry.CurrentUser, key);
                            }
                        }
                    }
    
                    //saving gpo settings
                    gpo.Save(true, true, new Guid("35378EAC-683F-11D2-A89A-00C04FBBCFA2"), new Guid("7A9206BD-33AF-47af-B832-D4128730E990"));
                }
                catch (Exception ex)
                {
                    return ex.Message;
                }
                finally
                {
                    KeyHandle = IntPtr.Zero;
                }
    
                return null;
            }
    
            private static string RemoveServersFromAllowFreshCredentialsPolicyImpl(string[] serverNames)
            {
                IGroupPolicyObject gpo = (IGroupPolicyObject)new GPClass();
                gpo.OpenLocalMachineGPO(GPO_OPEN_LOAD_REGISTRY);
    
                var KeyHandle = gpo.GetRegistryKey(GPO_SECTION_MACHINE);
    
                try
                {
                    var rootKey = Registry.CurrentUser;
    
                    using (RegistryKey GPOKey = rootKey.OpenSubKey(GPOpath, true))
                    {
                        foreach (var keyName in GPOKey.GetSubKeyNames())
                        {
                            if (keyName.EndsWith(Machine, StringComparison.OrdinalIgnoreCase))
                            {
                                var key = GPOpath + BackSlash + keyName + BackSlash + PoliciesPath;
    
                                UpdateGpoRegistrySettingsRemoveServersFromFreshCredentials(ApplicationName, serverNames, Registry.CurrentUser, key);
                            }
                        }
                    }
    
                    //saving gpo settings
                    gpo.Save(true, true, new Guid("35378EAC-683F-11D2-A89A-00C04FBBCFA2"), new Guid("7A9206BD-33AF-47af-B832-D4128730E990"));
                }
                catch (Exception ex)
                {
                    return ex.Message;
                }
                finally
                {
                    KeyHandle = IntPtr.Zero;
                }
    
                return null;
            }
    
            private static void UpdateGpoRegistrySettingsAllowFreshCredentials(string applicationName, string[] serverNames, RegistryKey rootKey, string registryPath)
            {
                var registryPathCredentialsDelegation = registryPath + CredentialsDelegation;
                var credentialDelegationKey = rootKey.OpenSubKey(registryPathCredentialsDelegation, true);
    
                try
                {
                    if (credentialDelegationKey == null)
                    {
                        credentialDelegationKey = rootKey.CreateSubKey(registryPathCredentialsDelegation, RegistryKeyPermissionCheck.ReadWriteSubTree);
                    }
    
                    credentialDelegationKey.SetValue(AllowFreshCredentials, 1, RegistryValueKind.DWord);
                    credentialDelegationKey.SetValue(ConcatenateDefaultsAllowFresh, 1, RegistryValueKind.DWord);
                }
                finally
                {
                    credentialDelegationKey.Dispose();
                    credentialDelegationKey = null;
                }
    
                var allowFreshCredentialKey = rootKey.OpenSubKey(registryPathCredentialsDelegation + BackSlash + AllowFreshCredentials, true);
    
                try
                {

                    if (allowFreshCredentialKey == null)
                    {
                        allowFreshCredentialKey = rootKey.CreateSubKey(registryPathCredentialsDelegation + BackSlash + AllowFreshCredentials, RegistryKeyPermissionCheck.ReadWriteSubTree);
                    }

                    if (allowFreshCredentialKey != null)
                    {
                        var values = allowFreshCredentialKey.ValueCount;
                        var valuesToAdd = serverNames.ToDictionary(key => string.Format(CultureInfo.InvariantCulture, @"{0}/{1}", applicationName, key), value => value);
                        var valueNames = allowFreshCredentialKey.GetValueNames();
                        var existingValues = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    
                        foreach (var valueName in valueNames)
                        {
                            var value = allowFreshCredentialKey.GetValue(valueName).ToString();
    
                            if (!existingValues.ContainsKey(value))
                            {
                                existingValues.Add(value, value);
                            }
                        }
    
                        foreach (var key in valuesToAdd.Keys)
                        {
                            if (!existingValues.ContainsKey(key))
                            {
                                allowFreshCredentialKey.SetValue(Convert.ToString(values + 1, CultureInfo.InvariantCulture), key, RegistryValueKind.String);
                                values++;
                            }
                        }
                    }
                }
                finally
                {
                    allowFreshCredentialKey.Dispose();
                    allowFreshCredentialKey = null;
                }
            }
    
            private static void UpdateGpoRegistrySettingsRemoveServersFromFreshCredentials(string applicationName, string[] serverNames, RegistryKey rootKey, string registryPath)
            {
                var registryPathCredentialsDelegation = registryPath + CredentialsDelegation;
    
                using (var allowFreshCredentialKey = rootKey.OpenSubKey(registryPathCredentialsDelegation + BackSlash + AllowFreshCredentials, true))
                {
                    if (allowFreshCredentialKey != null)
                    {
                        var valuesToRemove = serverNames.ToDictionary(key => string.Format(CultureInfo.InvariantCulture, @"{0}/{1}", applicationName, key), value => value);
                        var valueNames = allowFreshCredentialKey.GetValueNames();
    
                        foreach (var valueName in valueNames)
                        {
                            var value = allowFreshCredentialKey.GetValue(valueName).ToString();
                            
                            if (valuesToRemove.ContainsKey(value))
                            {
                                allowFreshCredentialKey.DeleteValue(valueName);
                            }
                        }
                    }
                }
            }
        }
    }
"@  # Cannot have leading whitespace on this line!
}

<#

.SYNOPSIS
Clean up all added global variables, constants, etc.

.DESCRIPTION
Clean up all added global variables, constants, etc.

#>

function cleanupScriptEnv() {
    Remove-Variable -Name WsManApplication -Scope Script -Force
    Remove-Variable -Name CredSSPClientAuthPath -Scope Script -Force
    Remove-Variable -Name CredentialsDelegationPolicyPath -Scope Script -Force
    Remove-Variable -Name AllowFreshCredentialsPath -Scope Script -Force
    Remove-Variable -Name AllowFreshCredentialsPropertyName -Scope Script -Force
    Remove-Variable -Name TypeAlreadyExistsHResult -Scope Script -Force
    Remove-Variable -Name NativeCode -Scope Script -Force
}

<#

.SYNOPSIS
Enable CredSSP client role on this computer.

.DESCRIPTION
Enable the CredSSP client role on this computer.  This computer should be a 
Windows Admin Center gateway, desktop or service mode.

#>

function enableCredSSPClient() {
    $path = "{0}:\{1}" -f $WsManApplication, $CredSSPClientAuthPath

    Set-Item -Path $path True -Force -ErrorAction SilentlyContinue -ErrorVariable +err
}

<#

.SYNOPSIS
Get the CredentialsDelegation container from the registry.

.DESCRIPTION
Get the CredentialsDelegation container from the registry.  If the container
does not exist then a new one will be created.

#>

function getCredentialsDelegationItem() {
    $credentialDelegationItem = Get-Item  $CredentialsDelegationPolicyPath -ErrorAction SilentlyContinue
    if (-not ($credentialDelegationItem)) {
        $credentialDelegationItem = New-Item  $CredentialsDelegationPolicyPath
    }

    return $credentialDelegationItem
}

<#

.SYNOPSIS
Creates the CredentialsDelegation\AllowFreshCredentials container from the registry.

.DESCRIPTION
Create the CredentialsDelegation\AllowFreshCredentials container from the registry.  If the container
does not exist then a new one will be created.

#>

function createAllowFreshCredentialsItem() {
    $allowFreshCredentialsItem = Get-Item $AllowFreshCredentialsPath -ErrorAction SilentlyContinue
    if (-not ($allowFreshCredentialsItem)) {
        New-Item $AllowFreshCredentialsPath
    }
}

<#

.SYNOPSIS
Set the AllowFreshCredentials property value in the CredentialsDelegation container.

.DESCRIPTION
Set the AllowFreshCredentials property value in the CredentialsDelegation container.
If the value exists then it is not changed.

#>

function setAllowFreshCredentialsProperty($credentialDelegationItem) {
    $credentialDelegationItem | New-ItemProperty -Name $AllowFreshCredentialsPropertyName -Value 1 -Type DWord -Force
}

<#

.SYNOPSIS
Add the passed in server(s) to the AllowFreshCredentials key/container.

.DESCRIPTION
Add the passed in server(s) to the AllowFreshCredentials key/container. 
If a given server is already present then do not add it again.

#>

function addServersToAllowFreshCredentials([string[]]$serverNames) {
    $valuesAdded = 0

    foreach ($serverName in $serverNames) {
        $newValue = "{0}/{1}" -f $WsManApplication, $serverName

        # Check if any registry-value nodes values of registry-key node have certain value.
        $key = Get-ChildItem $CredentialsDelegationPolicyPath | ? PSChildName -eq $AllowFreshCredentialsPropertyName
        $hasValue = $false
        $valueNames = $key.GetValueNames()

        foreach ($valueName in $valueNames) {
            $value = $key.GetValue($valueName)

            if ($value -eq $newValue) {
                $hasValue = $true
                break
            }
        }

        if (-not ($hasValue)) {
            New-ItemProperty $AllowFreshCredentialsPath -Name ($valueNames.Length + 1) -Value $newValue -Force
            $valuesAdded++
        }
    }

    return $valuesAdded -gt 0
}

<#

.SYNOPSIS
Add the passed in server(s) to the delegation list in the registry.

.DESCRIPTION
Add the passed in server(s) to the delegation list in the registry.

#>

function addServersToDelegation([string[]] $serverNames) {
    # Default to true because not adding entries is not a failure
    $result = $true

    # Get the CredentialsDelegation key/container
    $credentialDelegationItem = getCredentialsDelegationItem

    # Test, and create if needed, the AllowFreshCredentials property value
    setAllowFreshCredentialsProperty $credentialDelegationItem

    # Create the AllowFreshCredentials key/container
    createAllowFreshCredentialsItem
    
    # Add the servers to the AllowFreshCredentials key/container, if not already present
    $updateGroupPolicy = addServersToAllowFreshCredentials $serverNames

    if ($updateGroupPolicy) {
        $result = setLocalGroupPolicy $serverNames
    }

    return $result
}

<#

.SYNOPSIS
Set the local group policy to match the settings that have already been made.

.DESCRIPTION
Local Group Policy must match the settings that were made by this script to
ensure that an older Local GP setting does not overwrite the thos settings.

#>

function setLocalGroupPolicy([string[]] $serverNames) {
    try {
        Add-Type -TypeDefinition $NativeCode
    } catch {
        if ($_.Exception.HResult -ne $TypeAlreadyExistsHResult) {
            Write-Error $_.Exception.Message

            return $false
        }
    }

    $errorMessage = [SME.LocalGroupPolicy]::EnableAllowFreshCredentialsPolicy($serverNames)

    if ($errorMessage) {
        Write-Error $errorMessage

        return $false
    }

    return $true
}

<#

.SYNOPSIS
Main function of this script.

.DESCRIPTION
Enable CredSSP client role and add the passed in servers to the list
of servers to which this client can delegate credentials.

#>
function main([string[]] $serverNames) {
    setupScriptEnv

    enableCredSSPClient
    $result = addServersToDelegation $serverNames

    cleanupScriptEnv

    return $result
}

###############################################################################
# Script execution starts here
###############################################################################

return main $serverNames

}
## [END] Enable-CredSSPClientRole ##
function Enable-CredSspManagedServer {
<#

.SYNOPSIS
Enables CredSSP on this server.

.DESCRIPTION
Enables CredSSP server role on this server.

.ROLE
Administrators

.LINK
https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2018-0886

.LINK
https://aka.ms/CredSSP-Updates


#>

Set-StrictMode -Version 5.0
Import-Module  Microsoft.WSMan.Management -ErrorAction SilentlyContinue

function setupScriptEnv() {
    Set-Variable CredSSPServicePath -Option ReadOnly -Scope Script -Value "WSMan:\localhost\Service\Auth\CredSSP"
}

function cleanupScriptEnv() {
    Remove-Variable CredSSPServicePath -Scope Script -Force
}

<#

.SYNOPSIS
Is CredSSP enabled on this server.

.DESCRIPTION
Enables CredSSP on this server for server role.

#>

function getCredSSPServerEnabled()
{
    $credSSPServerEnabled = $false;

    $credSSPServerService = Get-Item $CredSSPServicePath -ErrorAction SilentlyContinue
    if ($credSSPServerService) {
        $credSSPServerEnabled = [System.Convert]::ToBoolean($credSSPServerService.Value)
    }

    return $credSSPServerEnabled
}

<#

.SYNOPSIS
Enables CredSSP on this server.

.DESCRIPTION
Enables CredSSP on this server for server role.

#>

function enableCredSSP() {
    $err = $null

    # Catching the result so that we can discard it. Otherwise it get concatinated with $err and we don't want that!
    $result = Enable-WSManCredSSP -Role Server -Force -ErrorAction SilentlyContinue -ErrorVariable +err

    return $err
}

<#

.SYNOPSIS
Main function.

.DESCRIPTION
Main function.

#>

function main() {
    setupScriptEnv

    $retVal = $true
    
    # If server role is enabled then return success.
    if (-not (getCredSSPServerEnabled)) {
        # If not enabled try to enable
        $err = enableCredSSP
        if ($err) {
            # If there was an error, and server role is not enabled return error.
            if (-not (getCredSSPServerEnabled)) {
                $retVal = $false
                
                Write-Error $err
            }
        }
    }

    cleanupScriptEnv

    return $retVal
}

###############################################################################
# Script execution starts here...
###############################################################################

return main

}
## [END] Enable-CredSspManagedServer ##
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
function Get-CimWin32OperatingSystem {
<#

.SYNOPSIS
Gets Win32_OperatingSystem object.

.DESCRIPTION
Gets Win32_OperatingSystem object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_OperatingSystem

}
## [END] Get-CimWin32OperatingSystem ##
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
function Get-CredSspClientRole {
<#

.SYNOPSIS
Gets the CredSSP enabled state on this computer as client role to the other computer.

.DESCRIPTION
Gets the CredSSP enabled state on this computer as client role to the other computer.

.ROLE
Administrators

.PARAMETER serverNames
The names of the server to which this gateway can forward credentials.

.LINK
https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2018-0886

.LINK
https://aka.ms/CredSSP-Updates

#>

param (
    [Parameter(Mandatory=$True)]
    [string[]]$serverNames
)

Set-StrictMode -Version 5.0
Import-Module  Microsoft.WSMan.Management -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Setup all necessary global variables, constants, etc.

.DESCRIPTION
Setup all necessary global variables, constants, etc.

#>

function setupScriptEnv() {
    Set-Variable -Name WsManApplication -Option ReadOnly -Scope Script -Value "wsman"
    Set-Variable -Name CredSSPClientAuthPath -Option ReadOnly -Scope Script -Value "localhost\Client\Auth\CredSSP"
    Set-Variable -Name CredentialsDelegationPolicyPath -Option ReadOnly -Scope Script -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation"
    Set-Variable -Name AllowFreshCredentialsPath -Option ReadOnly -Scope Script -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials"
    Set-Variable -Name AllowFreshCredentialsPropertyName -Option ReadOnly -Scope Script -Value "AllowFreshCredentials"
}

<#

.SYNOPSIS
Clean up all added global variables, constants, etc.

.DESCRIPTION
Clean up all added global variables, constants, etc.

#>

function cleanupScriptEnv() {
    Remove-Variable -Name WsManApplication -Scope Script -Force
    Remove-Variable -Name CredSSPClientAuthPath -Scope Script -Force
    Remove-Variable -Name CredentialsDelegationPolicyPath -Scope Script -Force
    Remove-Variable -Name AllowFreshCredentialsPath -Scope Script -Force
    Remove-Variable -Name AllowFreshCredentialsPropertyName -Scope Script -Force
}

<#

.SYNOPSIS
Is CredSSP client role enabled on this server.

.DESCRIPTION
When the CredSSP client role is enabled on this server then return $true.

#>

function getCredSSPClientEnabled() {
    $path = "{0}:\{1}" -f $WsManApplication, $CredSSPClientAuthPath

    $credSSPClientEnabled = $false;

    $credSSPClientService = Get-Item $path -ErrorAction SilentlyContinue
    if ($credSSPClientService) {
        $credSSPClientEnabled = [System.Convert]::ToBoolean($credSSPClientService.Value)
    }

    return $credSSPClientEnabled
}

<#

.SYNOPSIS
Are the servers already configure to delegate fresh credentials?

.DESCRIPTION
Are the servers already configure to delegate fresh credentials?

#>

function getServersDelegated([string[]] $serverNames) {
    $valuesFound = 0

    foreach ($serverName in $serverNames) {
        $newValue = "{0}/{1}" -f $WsManApplication, $serverName

        # Check if any registry-value nodes values of registry-key node have certain value.
        $key = Get-ChildItem $CredentialsDelegationPolicyPath | ? PSChildName -eq $AllowFreshCredentialsPropertyName
        $valueNames = $key.GetValueNames()

        foreach ($valueName in $valueNames) {
            $value = $key.GetValue($valueName)

            if ($value -eq $newValue) {
                $valuesFound++
                break
            }
        }
    }

    return $valuesFound -eq $serverNames.Length
}

<#

.SYNOPSIS
Detemines if the required CredentialsDelegation containers are in the registry.

.DESCRIPTION
Get the CredentialsDelegation container from the registry.  If the container
does not exist then we can return false since CredSSP is not configured on this
client (gateway).

#>

function areCredentialsDelegationItemsPresent() {
    $credentialDelegationItem = Get-Item  $CredentialsDelegationPolicyPath -ErrorAction SilentlyContinue
    if ($credentialDelegationItem) {
        $key = Get-ChildItem $CredentialsDelegationPolicyPath | ? PSChildName -eq $AllowFreshCredentialsPropertyName

        if ($key) {
            $valueNames = $key.GetValueNames()
            if ($valueNames) {
                return $true
            }
        }
    }

    return $false
}

<#

.SYNOPSIS
Main function of this script.

.DESCRIPTION
Return true if the gateway is already configured as a CredSSP client, and all of the servers provided
have already been configured to allow fresh credential delegation.

#>

function main([string[]] $serverNames) {
    setupScriptEnv

    $serversDelegated = $false

    $clientEnabled = getCredSSPClientEnabled
    
    if (areCredentialsDelegationItemsPresent) {
        $serversDelegated = getServersDelegated $serverNames
    }

    cleanupScriptEnv

    return $clientEnabled -and $serversDelegated
}

###############################################################################
# Script execution starts here
###############################################################################

return main $serverNames

}
## [END] Get-CredSspClientRole ##
function Get-CredSspManagedServer {
<#

.SYNOPSIS
Gets the CredSSP server role on this server.

.DESCRIPTION
Gets the CredSSP server role on this server.

.ROLE
Administrators

.Notes
The feature(s) that use this script are still in development and should be considered as being "In Preview".
Therefore, those feature(s) and/or this script may change at any time.

#>

Set-StrictMode -Version 5.0
Import-Module  Microsoft.WSMan.Management -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Setup all necessary global variables, constants, etc.

.DESCRIPTION
Setup all necessary global variables, constants, etc.

#>

function setupScriptEnv() {
    Set-Variable -Name WsManApplication -Option ReadOnly -Scope Script -Value "wsman"
    Set-Variable -Name CredSSPServiceAuthPath -Option ReadOnly -Scope Script -Value "localhost\Service\Auth\CredSSP"
}

<#

.SYNOPSIS
Clean up all added global variables, constants, etc.

.DESCRIPTION
Clean up all added global variables, constants, etc.

#>

function cleanupScriptEnv() {
    Remove-Variable -Name WsManApplication -Scope Script -Force
    Remove-Variable -Name CredSSPServiceAuthPath -Scope Script -Force
}

<#

.SYNOPSIS
Is CredSSP server role enabled on this server.

.DESCRIPTION
When the CredSSP server role is enabled on this server then return $true.

#>

function getCredSSPServerEnabled() {
    $path = "{0}:\{1}" -f $WsManApplication, $CredSSPServiceAuthPath

    $credSSPServerEnabled = $false;

    $credSSPServerService = Get-Item $path -ErrorAction SilentlyContinue
    if ($credSSPServerService) {
        $credSSPServerEnabled = [System.Convert]::ToBoolean($credSSPServerService.Value)
    }

    return $credSSPServerEnabled
}

<#

.SYNOPSIS
Main function.

.DESCRIPTION
Main function.

#>

function main() {
    setupScriptEnv

    $result = getCredSSPServerEnabled

    cleanupScriptEnv

    return $result
}

###############################################################################
# Script execution starts here...
###############################################################################

if (-not ($env:pester)) {
    return main
}

}
## [END] Get-CredSspManagedServer ##
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
function Get-UserInCredSSPAdminGroup {
<#

.SYNOPSIS
Retrieves if the given user is in CredSSP Admin Group.

.DESCRIPTION
Checks for, and reports on, if the given user is part of CredSSP Admin Group. 
Also try to add the user to group if currently not a member.

.ROLE
Administrators

.PARAMETER userName
    The user name to check for membership in CredSSP Admins Group.
#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $userName
)

Set-StrictMode -Version 5.0
Import-Module Microsoft.PowerShell.LocalAccounts -ErrorAction SilentlyContinue

###########################################################################
# Constants
###########################################################################

Set-Variable -Name CredSSPAdminsGroupName -Option Constant -Value "Windows Admin Center CredSSP Admins" -ErrorAction SilentlyContinue
Set-Variable -Name LogName -Option Constant -Value "Microsoft-ServerManagementExperience" -ErrorAction SilentlyContinue
Set-Variable -Name LogSource -Option Constant -Value "SMEScripts" -ErrorAction SilentlyContinue
Set-Variable -Name ScriptName -Option Constant -Value $MyInvocation.ScriptName -ErrorAction SilentlyContinue

# $currentUser = "{0}\{1}" -f $env:UserDomain, $env:UserName

<#

.SYNOPSIS
Is the user a member of the local Group?

#>

function IsMemberOfGroup([string] $groupName, [string] $userName) {
    $members = @(Get-LocalGroupMember -Name $groupName -ErrorAction SilentlyContinue)

    if ($members.Length -gt 0) {
        return ($members | Where-Object {$_.Name -eq $userName}) -ne $null
    }

    return $false
}

<#

.SYNOPSIS
Try adding user to the group.

#>

function AddMemberToGroup([string] $groupName, [string] $userName) {
    Add-LocalGroupMember -Group $groupName -Member $userName -errorAction SilentlyContinue -ErrorVariable +err

    if ($err) {
        Microsoft.PowerShell.Management\Write-EventLog `
        -LogName $LogName `
        -Source $LogSource `
        -EventId 0 `
        -Category 0 `
        -EntryType Error `
        -Message "[$ScriptName]: Failed to add member to $groupName. Error: $err" `
        -ErrorAction SilentlyContinue
    }
}

<#

.SYNOPSIS
The main function of this script.

#>

function main([string]$userName) {
    $isMember = IsMemberOfGroup $CredSSPAdminsGroupName $userName

    if ($isMember) {
        $isMember = $true
        $isJoinAttemptMade = $false
    } else {
        # Try adding user to the local group.
        AddMemberToGroup  $CredSSPAdminsGroupName $userName

        $isMember = IsMemberOfGroup $CredSSPAdminsGroupName $userName
        $isJoinAttemptMade = $true
    }

    return @{ IsMember = $isMember; JoinAttempted = $isJoinAttemptMade }
}

###########################################################################
# Script execution starts here.
###########################################################################

if (-not ($env:pester)) {
    Microsoft.PowerShell.Management\New-EventLog -LogName $LogName -Source $LogSource -ErrorAction SilentlyContinue

    $module = Get-Module Microsoft.PowerShell.LocalAccounts -ErrorAction SilentlyContinue
    if ($module) {
        return main $userName
    }

    Microsoft.PowerShell.Management\Write-EventLog `
        -LogName $LogName `
        -Source $LogSource `
        -EventId 0 `
        -Category 0 `
        -EntryType Warning `
        -Message "[$ScriptName]: The required PowerShell module (LocalAccounts) was not found." `
        -ErrorAction SilentlyContinue
}
}
## [END] Get-UserInCredSSPAdminGroup ##
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
# MIIdjgYJKoZIhvcNAQcCoIIdfzCCHXsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUo+28Efby8kCHpoG2RARtkKWM
# WmagghhqMIIE2jCCA8KgAwIBAgITMwAAAQWOyikiHmo0WwAAAAABBTANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgwODIzMjAyMDI0
# WhcNMTkxMTIzMjAyMDI0WjCByjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAldBMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# LTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEm
# MCQGA1UECxMdVGhhbGVzIFRTUyBFU046M0JENC00QjgwLTY5QzMxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIHNlcnZpY2UwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCffZs9uGatv9jfpb3g0Q0muReKdfyO+ND1cMPAHg/+ltXc
# 1XcUSSvbtE2sQOpyzJ6lAdbDHTouZnya8uI0AYAipfNXEnp0eB1l5b5mnVvKumye
# nWxzU1YLanf9rzp4HKHxuhl8kP8VlcJd0x0zBxj1JAHHO8jVI35U3v08cVReLMw5
# QWdlWQz/Swutiuhde2k613yzR4I5M7gsm4S0xcuC+vB1SzjwqSoYXCnRfhXvz+wB
# FvXlUycvp+9dnjfQFuoJdy/9yppx9EGLW86fsLqnkEZO9kKACU22tZusBpioC3+w
# jd96i5SkflDjVjLxHbMKFIKD3XIgx1oxrBVO4Yl/AgMBAAGjggEJMIIBBTAdBgNV
# HQ4EFgQUS/krKiFv0JlX9HMQH8enXOKF3c0wHwYDVR0jBBgwFoAUIzT42VJGcArt
# QPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL2NybC5taWNyb3Nv
# ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNy
# bDBYBggrBgEFBQcBAQRMMEowSAYIKwYBBQUHMAKGPGh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNydDATBgNV
# HSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQUFAAOCAQEAcLcxL0JQzfHT3vPE
# OVH1qIuPJjuI+CmWyxzaqMn9K8XLFjBEguHUo818JoDzFujQTVYHFnB+Me4EQBj3
# eAKz4WIOndt6nEtyZq8w/k1iJCJfR+r36dRZjkbpBpyezdPAUAVwzrzuKYvsYlT8
# xb9EyItAsLIog5zxfixxaJFD9lWLytcMOV1if3T3M4ASsV/UcakF2RtaSyav9i8d
# Du9xMWM9OxQjzWNOUEtbuditPvUG7y3dLYBsTfG3EzlbKxd0fp5a/Kq4OhQosnbF
# 7mxNnsCc7QDMVYiM5bpv7AJsxMUC9/5upsjhATVvG1COGLlY07O+w7Yp8f+cP/7e
# 6Y30xDCCBf8wggPnoAMCAQICEzMAAAEDXiUcmR+jHrgAAAAAAQMwDQYJKoZIhvcN
# AQELBQAwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYG
# A1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTAeFw0xODA3MTIy
# MDA4NDhaFw0xOTA3MjYyMDA4NDhaMHQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xHjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANGUdjbmhqs2/mn5RnyLiFDLkHB/
# sFWpJB1+OecFnw+se5eyznMK+9SbJFwWtTndG34zbBH8OybzmKpdU2uqw+wTuNLv
# z1d/zGXLr00uMrFWK040B4n+aSG9PkT73hKdhb98doZ9crF2m2HmimRMRs621TqM
# d5N3ZyGctloGXkeG9TzRCcoNPc2y6aFQeNGEiOIBPCL8r5YIzF2ZwO3rpVqYkvXI
# QE5qc6/e43R6019Gl7ziZyh3mazBDjEWjwAPAf5LXlQPysRlPwrjo0bb9iwDOhm+
# aAUWnOZ/NL+nh41lOSbJY9Tvxd29Jf79KPQ0hnmsKtVfMJE75BRq67HKBCMCAwEA
# AaOCAX4wggF6MB8GA1UdJQQYMBYGCisGAQQBgjdMCAEGCCsGAQUFBwMDMB0GA1Ud
# DgQWBBRHvsDL4aY//WXWOPIDXbevd/dA/zBQBgNVHREESTBHpEUwQzEpMCcGA1UE
# CxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJpY28xFjAUBgNVBAUTDTIz
# MDAxMis0Mzc5NjUwHwYDVR0jBBgwFoAUSG5k5VAF04KqFzc3IrVtqMp1ApUwVAYD
# VR0fBE0wSzBJoEegRYZDaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljQ29kU2lnUENBMjAxMV8yMDExLTA3LTA4LmNybDBhBggrBgEFBQcBAQRV
# MFMwUQYIKwYBBQUHMAKGRWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y2VydHMvTWljQ29kU2lnUENBMjAxMV8yMDExLTA3LTA4LmNydDAMBgNVHRMBAf8E
# AjAAMA0GCSqGSIb3DQEBCwUAA4ICAQCf9clTDT8NJuyiRNgN0Z9jlgZLPx5cxTOj
# pMNsrx/AAbrrZeyeMxAPp6xb1L2QYRfnMefDJrSs9SfTSJOGiP4SNZFkItFrLTuo
# LBWUKdI3luY1/wzOyAYWFp4kseI5+W4OeNgMG7YpYCd2NCSb3bmXdcsBO62CEhYi
# gIkVhLuYUCCwFyaGSa/OfUUVQzSWz4FcGCzUk/Jnq+JzyD2jzfwyHmAc6bAbMPss
# uwculoSTRShUXM2W/aDbgdi2MMpDsfNIwLJGHF1edipYn9Tu8vT6SEy1YYuwjEHp
# qridkPT/akIPuT7pDuyU/I2Au3jjI6d4W7JtH/lZwX220TnJeeCDHGAK2j2w0e02
# v0UH6Rs2buU9OwUDp9SnJRKP5najE7NFWkMxgtrYhK65sB919fYdfVERNyfotTWE
# cfdXqq76iXHJmNKeWmR2vozDfRVqkfEU9PLZNTG423L6tHXIiJtqv5hFx2ay1//O
# kpB15OvmhtLIG9snwFuVb0lvWF1pKt5TS/joynv2bBX5AxkPEYWqT5q/qlfdYMb1
# cSD0UaiayunR6zRHPXX6IuxVP2oZOWsQ6Vo/jvQjeDCy8qY4yzWNqphZJEC4Omek
# B1+g/tg7SRP7DOHtC22DUM7wfz7g2QjojCFKQcLe645b7gPDHW5u5lQ1ZmdyfBrq
# UvYixHI/rjCCBgcwggPvoAMCAQICCmEWaDQAAAAAABwwDQYJKoZIhvcNAQEFBQAw
# XzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jvc29m
# dDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# MB4XDTA3MDQwMzEyNTMwOVoXDTIxMDQwMzEzMDMwOVowdzELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgUENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAn6Fssd/b
# SJIqfGsuGeG94uPFmVEjUK3O3RhOJA/u0afRTK10MCAR6wfVVJUVSZQbQpKumFww
# JtoAa+h7veyJBw/3DgSY8InMH8szJIed8vRnHCz8e+eIHernTqOhwSNTyo36Rc8J
# 0F6v0LBCBKL5pmyTZ9co3EZTsIbQ5ShGLieshk9VUgzkAyz7apCQMG6H81kwnfp+
# 1pez6CGXfvjSE/MIt1NtUrRFkJ9IAEpHZhEnKWaol+TTBoFKovmEpxFHFAmCn4Tt
# VXj+AZodUAiFABAwRu233iNGu8QtVJ+vHnhBMXfMm987g5OhYQK1HQ2x/PebsgHO
# IktU//kFw8IgCwIDAQABo4IBqzCCAacwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4E
# FgQUIzT42VJGcArtQPt2+7MrsMM1sw8wCwYDVR0PBAQDAgGGMBAGCSsGAQQBgjcV
# AQQDAgEAMIGYBgNVHSMEgZAwgY2AFA6sgmBAVieX5SUT/CrhClOVWeSkoWOkYTBf
# MRMwEQYKCZImiZPyLGQBGRYDY29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0
# MS0wKwYDVQQDEyRNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHmC
# EHmtFqFKoKWtTHNY9AcTLmUwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC5t
# aWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvbWljcm9zb2Z0cm9vdGNlcnQu
# Y3JsMFQGCCsGAQUFBwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraS9jZXJ0cy9NaWNyb3NvZnRSb290Q2VydC5jcnQwEwYDVR0l
# BAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQEFBQADggIBABCXisNcA0Q23em0rXfb
# znlRTQGxLnRxW20ME6vOvnuPuC7UEqKMbWK4VwLLTiATUJndekDiV7uvWJoc4R0B
# hqy7ePKL0Ow7Ae7ivo8KBciNSOLwUxXdT6uS5OeNatWAweaU8gYvhQPpkSokInD7
# 9vzkeJkuDfcH4nC8GE6djmsKcpW4oTmcZy3FUQ7qYlw/FpiLID/iBxoy+cwxSnYx
# PStyC8jqcD3/hQoT38IKYY7w17gX606Lf8U1K16jv+u8fQtCe9RTciHuMMq7eGVc
# WwEXChQO0toUmPU8uWZYsy0v5/mFhsxRVuidcJRsrDlM1PZ5v6oYemIp76KbKTQG
# dxpiyT0ebR+C8AvHLLvPQ7Pl+ex9teOkqHQ1uE7FcSMSJnYLPFKMcVpGQxS8s7Ow
# TWfIn0L/gHkhgJ4VMGboQhJeGsieIiHQQ+kr6bv0SMws1NgygEwmKkgkX1rqVu+m
# 3pmdyjpvvYEndAYR7nYhv5uCwSdUtrFqPYmhdmG0bqETpr+qR/ASb/2KMmyy/t9R
# yIwjyWa9nR2HEmQCPS2vWY+45CHltbDKY7R4VAXUQS5QrJSwpXirs6CWdRrZkocT
# dSIvMqgIbqBbjCW/oO+EyiHW6x5PyZruSeD3AWVviQt9yGnI5m7qp5fOMSn/DsVb
# XNhNG6HY+i+ePy5VFmvJE6P9MIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCBI4wggSKAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAEDXiUcmR+jHrgAAAAAAQMwCQYFKw4DAhoFAKCB
# ojAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUsJkzPUUwv3fgcA4PQdHOK3PpEZIw
# QgYKKwYBBAGCNwIBDDE0MDKgFIASAE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbTANBgkqhkiG9w0BAQEFAASCAQCjM3wxHGf8/fpi
# bxhCNseYIsK9xSByAk+pTJ6Eps4uWwbJ4h6PqErBz0X4OIy8UChCnTvRU6sfDjvR
# vP9XbOgiRPgr62WJcuBJ4Ur1ghtu1V2VUUVaL5iihXcU+XGQY8sMs4ELbbZI65Rj
# BXGZVZUrPNySfQbfVJaZ3uIC+pAoLeI78MSWE6uTsAaBBgJpk574JSjgUH+AVA3F
# +rIrcQb+KZpV/WvToq1joAkXQJqqRMg4DSK5ND1asfklahci6037PBY0resMJ/Yt
# vBQaR+8+Bm3C/Y4pIxl2F0RlEHHHpttqPUKS5wK09h5tOjZgP+8eymAOqrx+OxJ/
# 5xtP6BLloYICKDCCAiQGCSqGSIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQQITMwAAAQWOyikiHmo0WwAAAAABBTAJBgUrDgMCGgUA
# oF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTkw
# NDEwMTc0MDM2WjAjBgkqhkiG9w0BCQQxFgQUR74LvuxSe7ntnXnxTZvdQWZ+N28w
# DQYJKoZIhvcNAQEFBQAEggEAF4G1nYWz9GEEKu4fCjVEInLd27LvzJFKVjSDvhsK
# fxOMF0HGGmiS3J39rfeRQJ48n/Fx3RvxypqcGsiZC4eH+Ae0OHanfmrOkBb7yRk+
# mL4N/5N092aV+uaGfDFusYE9aDh5uBi4i/i3z+/qcJz/lYvhCXJw9dio8w4SAf89
# dYbJSIv6DUE9KZOG7DZagn4ftBQsgdI+TBvuwgJjayI44EbTMNOR9uXobqwBO0J6
# qbC/g23KGzYT9wuOiC4umC4onPt6jrDIKEYzrkNTgQNARzUHIkX0KglXkj4V+1Ph
# tC86LUvcTPdAc1J9669avEDsqyUfUzak5vU1Nn6GTaGMyQ==
# SIG # End signature block
