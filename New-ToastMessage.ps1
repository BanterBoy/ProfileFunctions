Function New-ToastMessage {
    [CmdletBinding()]
    param(
        $Text
    )

    # Import the BurntToast module
    Import-Module -Name BurntToast

    # Create buttons for the notification with different actions
    $Button1 = New-BTButton -Content 'Button1' -Arguments 'https://www.example.com'
    $Button2 = New-BTButton -Content 'Button2' -Arguments 'ms-settings:windowsupdate'

    # Create a button group
    $ButtonGroup = New-BTButtonGroup -Buttons $Button1, $Button2

    # Create a hashtable for the notification
    $Notification = @{
        Text   = $Text
        Button = $ButtonGroup
    }

    # Create the notification
    New-BurntToastNotification @Notification
}
