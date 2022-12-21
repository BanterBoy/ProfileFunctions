function Get-KeepassSecret {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Query
    )

    Process {
        Open-KeepassVault

        Get-SecretInfo -Vault 'KeePassVault' -Name $Query
    }
}
function Get-KeepassPassword {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name,

        [Parameter(Mandatory = $false, HelpMessage = "If supplied the password will not be written to the clipboard")]
        [switch]$NoClipboard
    )

    Process {
        Open-KeepassVault

        $pswd = ConvertFrom-SecureString (Get-Secret -Name $Name -Vault 'KeePassVault').Password -AsPlainText

        Write-Host("$pswd")

        if (-Not $NoClipboard.IsPresent) {
            $pswd | Set-Clipboard

            Write-Host ""
            Write-Host("$pswd copied to clipboard")
        }
    }
}

function Get-KeepassUsernameAndPassword {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name,

        [Parameter(Mandatory = $false, HelpMessage = "If supplied the creds will not be written to the clipboard")]
        [switch]$NoClipboard
    )

    Process {
        Open-KeepassVault

        $secret = Get-Secret -Name $Name -Vault 'KeePassVault'

        $pswd = ConvertFrom-SecureString $secret.Password -AsPlainText
        
        Write-Host("Username: $($secret.Username)")
        Write-Host("Password: $pswd")

        if (-Not $NoClipboard.IsPresent) {
            $secret.Username | Set-Clipboard
            $pswd | Set-Clipboard -Append

            Write-Host ""
            Write-Host("$($secret.Username) copied to clipboard")
            Write-Host("$pswd copied to clipboard")
        }
    }
}
function Open-KeepassVault {
    [CmdletBinding()]
    Param()
    
    Process {
        Unlock-SecretVault -Name 'KeePassVault' -Password (ConvertTo-SecureString -String '******' -AsPlainText)
    }
}