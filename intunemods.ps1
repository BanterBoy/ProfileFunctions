$var01 = "microsoft.graph.intune"
Function Get-MyModule {
    Param([string]$name)
    if (-not(Get-Module -name $var01)) {
        if (Get-Module -ListAvailable |
            Where-Object { $_.name -eq $var01 }) {
            Import-Module -Name $var01
            $true
        } #end if module available then import
        else
        { Install-Module -Name $var01 -force }
    }
    else
    { $true } #module already loaded
} #end function get-MyModule
get-mymodule -name $var01

$var02 = "WindowsAutopilotIntune"
Function Get-MyModule {
    Param([string]$name)
    if (-not(Get-Module -name $var02)) {
        if (Get-Module -ListAvailable |
            Where-Object { $_.name -eq $var02 }) {
            Import-Module -Name $var02
            $true
        } #end if module available then import
        else
        { Install-Module -Name $var02 -force }
    }
    else
    { $true } #module already loaded
} #end function get-MyModule
get-mymodule -name $var02