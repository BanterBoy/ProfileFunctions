function DisableADAccountsMenu {

    # Import the PSMenu module
    Import-Module PSMenu

    # Define the actions
    function Disable-KurtisMarsden {
        Disable-ADAccount -Identity kurtismarsden.admin
        Write-Output "Account kurtismarsden.admin has been disabled."
    }

    function Disable-KurtisMarsden {
        Disable-ADAccount -Identity jamiebeale.admin
        Write-Output "Account jamiebeale.admin has been disabled."
    }

    function Disable-LukeLeigh {
        Disable-ADAccount -Identity lukeleigh.admin
        Write-Output "Account lukeleigh.admin has been disabled."
    }

    # Create the menu items
    $menuItems = @(
        "Disable Kurtis Marsden Account",
        "Disable Jamie Beale Account",
        "Disable Luke Leigh Account",
        $(Get-MenuSeparator),
        "Exit"
    )

    # Display the menu
    $Menu = Show-Menu -MenuItems $menuItems -ReturnIndex -ItemFocusColor "Yellow"

    # Use the correct comparison operator and check the value of $Menu
    switch ($Menu) {
        0 { Disable-KurtisMarsden }
        1 { Disable-LukeLeigh }
        default { Write-Output "Nothing Selected" }
    }
}

# Call the function to display the menu
# DisableADAccountsMenu