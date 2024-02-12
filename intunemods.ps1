# Name of the first module to be checked
$moduleName1 = "microsoft.graph.intune"

# Name of the second module to be checked
$moduleName2 = "WindowsAutopilotIntune"

# Function to check, import, or install a module
Function CheckAndImportModule {
    # Name of the module to be checked
    Param([string]$moduleName)

    # Check if the module is already imported
    if (-not(Get-Module -name $moduleName)) {
        # If not, check if the module is installed
        if (Get-Module -ListAvailable | Where-Object { $_.name -eq $moduleName }) {
            # If the module is installed, import it
            Import-Module -Name $moduleName
            $true
        }     
        else {
            # If the module is not installed, install it
            Install-Module -Name $moduleName -force
        }    
    }    
    else {
        # If the module is already imported, return true
        $true
    }    
}     

# Call the function for the first module
CheckAndImportModule -name $moduleName1

# Call the function for the second module
CheckAndImportModule -name $moduleName2
