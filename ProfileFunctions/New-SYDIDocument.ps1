function New-SYDIDocument {

    <#
        .SYNOPSIS
            New-SYDIDocument creates basic documentation for a Windows system, which you can use as a starting point.
        .DESCRIPTION
            New-SYDIDocument creates basic documentation for a Windows system, which you can use as a starting point.

            The documentation is created in Microsoft Word Format using SYDI-Server written by NetworkLore (https://networklore.com/sydi-server/). SYDI-Server is a vbscript which collects information from Windows computers by using WMI (Windows Management Instrumentation), this can be done against any remote computer which you can reach using WMI.
            
            The information is then written to either a Word document giving you a document you can use as is.
        .EXAMPLE
            New-SYDIDocument -ComputerName 'ComputerOne' -Credential $Credential -Template 'C:\Documents\ServerDocTemplate.dotx' -Output 'C:\Documents\'

            This example will create a new document for ComputerOne using the template C:\Documents\ServerDocTemplate.dotx and save it to C:\Documents\.
        .EXAMPLE
            $Creds = (Get-Credential)
            'ComputerOne','ComputerTwo','ComputerThree' |
                ForEach-Object -Process {
                    New-SYDIDocument -FontSize 10 -OutputPath C:\Temp\ -ComputerName $_ -Credential $Creds
                }

            This example will create a new document for ComputerOne, ComputerTwo and ComputerThree using the template C:\Documents\ServerDocTemplate.dotx and save it to C:\Temp\
        .EXAMPLE
            New-SYDIDocument -OutputPath C:\GitRepos\ -FontSize 12

            This example will create a document for the current computer, with a font size of 12 and save it to the C:\GitRepos\ folder.
        .INPUTS
            ComputerName:   The name of the computer to create the document for.
            Credential:     The credential to use to connect to the computer.
            Template:       The template to use to create the document.
            OutputPath:     The path to save the document to.
        .OUTPUTS
            WordDocument:   A Microsoft Office Word document containing the information collected from the computer is returned.
        .NOTES
            Author:     Luke Leigh
            LinkedIn:   https://www.linkedin.com/in/lukeleigh/
            GitHub:     https://github.com/BanterBoy/
            GitHubGist: https://gist.github.com/BanterBoy
            Twitter:    https://twitter.com/luke_leighs
        .LINK
            https://networklore.com/sydi-server/ - NetworkLore
        .FUNCTIONALITY
            Creates a new Word Document utilizing the SYDI-Server vbscript and PowerShell.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        HelpUri = 'https://github.com/BanterBoy/New-SYDIDocument',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param (
        # Enter computer name or pipe input. Leaving the parameter blank will create a new document the local computer name.
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Default',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Enter computer name or pipe input. Leaving the parameter blank will create a new document the local computer name.')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("cn")] 
        [string[]]
        $ComputerName = $env:COMPUTERNAME,
        # Enter your credendtials or pipe input. Leaving the parameter blank will exclude the use of credentials.
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Default',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Enter your credendtials or pipe input. Leaving the parameter blank will exclude the use of credentials.')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        [Alias("cred")]
        $Credential,
        # Enter the required font size or pipe input. Leaving this parameter blank will use the default font size of 10.
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Default',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Enter the required font size or pipe input. Leaving this parameter blank will use the default font size of 10.')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("fs")] 
        [int]
        $FontSize = 10,
        # Enter the file output path or pipe input. Leaving this parameter blank will use the default output path of the current working directory.
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Default',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Enter the file output path or pipe input. Leaving this parameter blank will use the default output path of the current users temp directory.')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("op")] 
        [string]
        $OutputPath = $env:TEMP,
        # Enter full file path for the Word Template you wish to use or pipe input. Leaving this parameter blank will use the default template.
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Default',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Enter full file path for the Word Template you wish to use or pipe input. Leaving this parameter blank will use the default template.')]
        [Alias("tp")] 
        [string]
        $Template
    )
    
    begin {
        $SYDIPath = "$PSScriptRoot\Sydi-Server.vbs"
        $Filename = $OutputPath + $ComputerName + ".docx"

    }
    
    process {
        if ($pscmdlet.ShouldProcess("$ComputerName", "Extracting SYDI information and documenting...")) {
            if ($Credential -eq $null) {
                if ($Template -eq "") {
                    cscript.exe $SYDIPath -wabefghipPqrsSu -racdklp -ew -f"$FontSize" -d -o"$FileName" -t"."
                }
                else {
                    cscript.exe $SYDIPath -wabefghipPqrsSu -racdklp -ew -f"$FontSize" -d -T"$Template" -o"$FileName" -t"."
                }
            }
            else {
                $UserName = $Credential.UserName
                $Password = $Credential.GetNetworkCredential().Password
                if ($Template -eq "") {
                    cscript.exe $SYDIPath -wabefghipPqrsSu -racdklp -ew -f"$FontSize" -d -o"$FileName" -t"$ComputerName" -u"$Username" -p"$Password"
                }
                else {
                    cscript.exe $SYDIPath -wabefghipPqrsSu -racdklp -ew -f"$FontSize" -d -T"$Template" -o"$FileName" -t"$ComputerName" -u"$Username" -p"$Password" 
                }
            }
        }
    }
    
    end {
    }
}
