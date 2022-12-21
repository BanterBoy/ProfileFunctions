function GraphAPIGetAuthCode {

    [CmdletBinding()]
    PARAM(
        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true)]
        [string]$ClientId,

        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true)]
        [string]$ClientSecret,

        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true)]
        [string]$RedirectUrl
    )

    BEGIN {
        $ResourceUrl = "https://graph.microsoft.com"
    }
    
    PROCESS {
        Function Get-AuthCode {
            Add-Type -AssemblyName System.Windows.Forms

            $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width = 440; Height = 640 }
            $web = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width = 420; Height = 600; Url = ($url -f ($Scope -join "%20")) }

            $DocComp = {
                $Global:uri = $web.Url.AbsoluteUri        
                if ($Global:uri -match "error=[^&]*|code=[^&]*") { $form.Close() }
            }
            $web.ScriptErrorsSuppressed = $true
            $web.Add_DocumentCompleted($DocComp)
            $form.Controls.Add($web)
            $form.Add_Shown({ $form.Activate() })
            $form.ShowDialog() | Out-Null

            $queryOutput = [System.Web.HttpUtility]::ParseQueryString($web.Url.Query)
            $output = @{}
            foreach ($key in $queryOutput.Keys) {
                $output["$key"] = $queryOutput[$key]
            }

            $output
        }
    }
    END {

    }
}