function Get-Happy {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter computer name or pipe input'
        )]
        [Alias('wn')]
        [datetime]$When
    )
    
    begin {
        $State = Get-HappyState
    }
    
    process {
        $State |
        Where-Object -FilterScript {
            ( $_.Unhappy -like '*miserable*' ) -or 
            ( $_.Unhappy -like '*unhappy*' ) -or 
            ( $_.Smile -like '*grimace*' )
        } | Set-HappyState -Happy:$true -Smile:Grin -When $When -Force
    }
    
    end {
        
    }
}
