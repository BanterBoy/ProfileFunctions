function Test-IsAdmin {
    <#
    .Synopsis
    Tests if the user is an administrator
    .Description
    Returns true if a user is an administrator, false if the user is not an administrator
    .Example
    Test-IsAdmin
    .Notes
    This function works by getting the current user's identity using the WindowsIdentity class, 
    creating a WindowsPrincipal object for the user, and then checking if the user is in the 
    'Administrator' role using the IsInRole method.
    #>
    
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal $identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }
    catch {
        Write-Error "Failed to check if user is an administrator: $_"
        return $false
    }
}