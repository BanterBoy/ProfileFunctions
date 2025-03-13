<#
    .SYNOPSIS
        Connects to the Microsoft Intune Graph API using stored credentials.
    
    .DESCRIPTION
        The Connect-AzureIntune function retrieves the Intune automation secret from a secure store and uses it to authenticate and connect to the Microsoft Intune Graph API.
        This function is useful for automating tasks that require access to Intune resources.
    
    .PARAMETER None
        This function does not take any parameters.
    
    .EXAMPLE
        Connect-AzureIntune
    
        This example connects to the Microsoft Intune Graph API using the stored credentials.
    
    .NOTES
        Author: John Doe
        Date:   01/01/2022
        Version: 1.0
        Requires: Microsoft.Graph.Intune module and SecretManagement module
    
    .REMARKS
        Ensure that the Microsoft.Graph.Intune module is installed and that you have the necessary permissions to access Intune resources.
        The secret must be stored using the SecretManagement module with the name "IntuneAutomationSecret".
#>

function Connect-AzureIntune {
    $intunecred = Get-Secret -Name IntuneAutomationSecret -AsPlainText
    Connect-MSIntuneGraph -ClientID "503f5e11-3d5f-4a1c-9991-563cf1d2157b" -TenantID "3ab8c573-cfde-4a33-b33a-6bd96f601c18" -ClientSecret $intunecred.ClientSecret
}
