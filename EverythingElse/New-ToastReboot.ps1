# Checking if ToastReboot:// protocol handler is present
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null
$ProtocolHandler = Get-Item 'HKCR:\ToastReboot' -ErrorAction SilentlyContinue
if (!$ProtocolHandler) {
    # create handler for reboot
    New-item 'HKCR:\ToastReboot' -Force
    Set-ItemProperty 'HKCR:\ToastReboot' -Name '(DEFAULT)' -Value 'url:ToastReboot' -Force
    Set-ItemProperty 'HKCR:\ToastReboot' -Name 'URL Protocol' -Value '' -Force
    New-ItemProperty -Path 'HKCR:\ToastReboot' -PropertyType dword -Name 'EditFlags' -Value 2162688
    New-Item 'HKCR:\ToastReboot\Shell\Open\command' -Force
    Set-ItemProperty 'HKCR:\ToastReboot\Shell\Open\command' -Name '(DEFAULT)' -Value 'C:\Windows\System32\shutdown.exe -r -t 00' -Force
}

Install-RequiredModules -PublicModules BurntToast
Install-RequiredModules -PublicModules RunAsUser
invoke-ascurrentuser -scriptblock {

    $heroimage = New-BTImage -Source 'C:\GitRepos\ProfileFunctions\LukeLeigh_Profile_300x300.jpg' -HeroImage
    $Text1 = New-BTText -Content  "System Update"
    $Text2 = New-BTText -Content "Updates have been installed on your computer at $(Get-Date). Please select if you'd like to restart now, or snooze this message."
    $Button = New-BTButton -Content "Later" -Snooze -Id 'SnoozeTime'
    $Button2 = New-BTButton -Content "Restart" -Arguments "ToastReboot:" -ActivationType Protocol
    $5Min = New-BTSelectionBoxItem -Id 5 -Content '5 minutes'
    $10Min = New-BTSelectionBoxItem -Id 10 -Content '10 minutes'
    $1Hour = New-BTSelectionBoxItem -Id 60 -Content '1 hour'
    $4Hour = New-BTSelectionBoxItem -Id 240 -Content '4 hours'
    $1Day = New-BTSelectionBoxItem -Id 1440 -Content '1 day'
    $Items = $5Min, $10Min, $1Hour, $4Hour, $1Day
    $SelectionBox = New-BTInput -Id 'SnoozeTime' -DefaultSelectionBoxItemId 10 -Items $Items
    $action = New-BTAction -Buttons $Button, $Button2 -inputs $SelectionBox
    $Binding = New-BTBinding -Children $text1, $text2 -HeroImage $heroimage
    $Visual = New-BTVisual -BindingGeneric $Binding
    $Content = New-BTContent -Visual $Visual -Actions $action
    Submit-BTNotification -Content $Content

}

function Remove-ToastReboot {
    # Create a new PowerShell drive mapped to the HKEY_CLASSES_ROOT registry hive
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null
    # Check if the custom protocol handler is present
    $ProtocolHandler = Get-Item 'HKCR:\ToastReboot' -ErrorAction SilentlyContinue
    if ($ProtocolHandler) {
        Write-Output "Removing custom protocol handler."
        Remove-Item 'HKCR:\ToastReboot' -Recurse -Force
    }
    else {
        Write-Output "The custom protocol handler is not present."
    }
}