function Import-PersonalModules {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "Utilities",
            "UserManagement",
            "Uncategorized",
            "Teams",
            "System",
            "Shell",
            "Security",
            "Replication",
            "RemoteConnections",
            "Network",
            "MediaManagement",
            "Logging",
            "GroupManagement",
            "FileOperations",
            "Exchange",
            "EnvironmentManagement",
            "Azure"
        )]
        [string]$Category
    )

    # Define the modules based on your provided list for the selected category
    $modules = @{
        "Utilities" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\Utilities\Utilities.psm1"
        )
        "UserManagement" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\UserManagement\UserManagement.psm1"
        )
        "Uncategorized" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\Uncategorized\Uncategorized.psm1"
        )
        "Teams" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\Teams\Teams.psm1"
        )
        "System" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\System\System.psm1"
        )
        "Shell" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\Shell\Shell.psm1"
        )
        "Security" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\Security\Security.psm1"
        )
        "Replication" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\Replication\Replication.psm1"
        )
        "RemoteConnections" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\RemoteConnections\RemoteConnections.psm1"
        )
        "Network" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\Network\Network.psm1"
        )
        "MediaManagement" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\MediaManagement\MediaManagement.psm1"
        )
        "Logging" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\Logging\Logging.psm1"
        )
        "GroupManagement" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\GroupManagement\GroupManagement.psm1"
        )
        "FileOperations" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\FileOperations\FileOperations.psm1"
        )
        "Exchange" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\Exchange\Exchange.psm1"
        )
        "EnvironmentManagement" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\EnvironmentManagement\EnvironmentManagement.psm1"
        )
        "Azure" = @(
            "C:\GitRepos\RDGScripts\UserAdminModule\Everything\Azure\Azure.psm1"
        )
    }

    # Ensure the category exists in the hash table
    if ($modules.ContainsKey($Category)) {
        $selectedModules = $modules[$Category]

        # Attempt to import each module
        foreach ($module in $selectedModules) {
            try {
                if (Test-Path $module) {
                    Write-Verbose "Importing module: $Category"
                    Import-Module -Name $module -Force -DisableNameChecking
                } else {
                    Write-Warning "Module not found: $module"
                }
            } catch {
                Write-Error "Failed to import module $module. Error: $_"
            }
        }
    } else {
        Write-Error "Invalid category specified. Please choose from: Utilities, UserManagement, Uncategorized, Teams, System, Shell, Security, Replication, RemoteConnections, Network, MediaManagement, Logging, GroupManagement, FileOperations, Exchange, EnvironmentManagement, Azure."
    }
}
