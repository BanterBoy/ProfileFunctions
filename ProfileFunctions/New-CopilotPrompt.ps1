<#
.SYNOPSIS
    Creates a PowerShell prompt format for Copilot.

.DESCRIPTION
    This function takes the prompt requirements (Goal, Context, Source, Expectations) as parameters and outputs the details as a psobject that can be copied and pasted into Copilot. It ensures compatibility with PowerShell 7.0 and later.

.PARAMETER Goal
    The goal of the prompt.

.PARAMETER Context
    The context in which the prompt is being used.

.PARAMETER Source
    The source of the prompt requirements.

.PARAMETER Expectations
    The expectations for the prompt output.

.PARAMETER CopyToClipboard
    Switch to copy the output to the clipboard in a list format.

.PARAMETER ExampleCode
    An example of the code you are currently using.

.EXAMPLE
    $goal = "Generate a PowerShell script to automate user account creation in Active Directory"
    $context = "The user is an IT Infrastructure Engineer who needs to streamline the process of creating user accounts for new employees"
    $source = "User's request and company policy documents"
    $expectations = "The script should create user accounts with specific attributes, set initial passwords, and add users to appropriate groups"
    $exampleCode = "New-ADUser -Name 'John Doe' -GivenName 'John' -Surname 'Doe' -SamAccountName 'jdoe' -UserPrincipalName 'jdoe@domain.com' -Path 'OU=Users,DC=domain,DC=com' -AccountPassword (ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force) -Enabled $true"

    New-CopilotPrompt -Goal $goal -Context $context -Source $source -Expectations $expectations -ExampleCode $exampleCode -CopyToClipboard
    
.EXAMPLE
    $goal = "Create a PowerShell function to generate a report of disk usage"
    $context = "The user is an IT Infrastructure Engineer who needs to monitor disk usage across multiple servers"
    $source = "User's request and server logs"
    $expectations = "The function should generate a report with disk usage details for each server"
    $exampleCode = "Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{Name='Used (GB)';Expression={[math]::round($_.Used/1GB,2)}}, @{Name='Free (GB)';Expression={[math]::round($_.Free/1GB,2)}}"

    New-CopilotPrompt -Goal $goal -Context $context -Source $source -Expectations $expectations -ExampleCode $exampleCode -CopyToClipboard
#>
function New-CopilotPrompt {
    param (
        [string]$Goal,
        [string]$Context,
        [string]$Source,
        [string]$Expectations,
        [string]$ExampleCode,
        [switch]$CopyToClipboard
    )

    $prompt = [pscustomobject]@{
        Goal         = $Goal
        Context      = $Context
        Source       = $Source
        Expectations = $Expectations
        ExampleCode  = $ExampleCode
    }

    if ($CopyToClipboard) {
        $listFormat = @"
Goal: $Goal
Context: $Context
Source: $Source
Expectations: $Expectations
Example Code: $ExampleCode
"@
        $listFormat | Set-Clipboard
    }

    return $prompt
}