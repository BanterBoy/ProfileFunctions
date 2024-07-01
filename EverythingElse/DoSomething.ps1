<#
.SYNOPSIS
    A script that does something.
.DESCRIPTION
    This script does something. The something that it does is entered as a string by the user.
.NOTES
    This is an example of a script.
.LINK
    - [something.com](http://something.com)
.EXAMPLE
    This is an example that will do the thing you want to do at the time you want to do it.
    .\DoSomething.ps1 -Whattodo "Do something" -WhenToDoIt (Get-Date).addHours(1)
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
[OutputType([object], ParameterSetName = 'Default')]
[OutputType([object])]
Param
(
    [Parameter(ParameterSetName = 'Default',
        Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = 'The something that you want to do.')]
    [string]$WhatToDo,
    [Parameter(ParameterSetName = 'Default',
        Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = 'The something that you want to do with the something.')]
    [datetime]$WhenToDoIt
)
Start-process $WhatToDo -ArgumentList $WhenToDoIt

