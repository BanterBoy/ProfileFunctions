function New-Greeting {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([string])]
    Param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter '
        )]
        [ValidateSet([GreetingsValidator])]
        [string]$Day
    )

    Begin {
        $greetings = [Greetings]::new()

        if ([String]::IsNullOrWhiteSpace($Day)) {
            $Day = $greetings.CurrentDay
        }
    }

    Process {
        Write-Output $($greetings.GetMessageForDay($Day))
    }
}
