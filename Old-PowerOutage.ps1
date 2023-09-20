# This function will be used to shut down the servers during a power outage. It will be called by the New-PowerOutage function.
# The server that should be shut down are specified in the $Server variable.
# This function should provide feedback on the status of the shutdown.
# The function will be run manually by a user from a remote computer.

# The function should report the status of the hosted virtual machines and the status of the physical server.
# Host Server = ABRIONSECTOR
# Virtual Machines = GEONOSIS, KAMINO

function New-PowerOutage {
    param(
        [string]$Server
    )

    $Server = "ABRIONSECTOR"
    $VirtualMachines = "GEONOSIS", "KAMINO"

    Write-Host "Shutting down $Server..."
    Write-Host "Shutting down virtual machines..."
    foreach ($VirtualMachine in $VirtualMachines) {
        Write-Host "Shutting down $VirtualMachine..."
        Stop-VM -Name $VirtualMachine -Force
    }
    Write-Host "Shutting down $Server..."
    Stop-Computer -ComputerName $Server -Force
    Write-Host "Power outage complete."
}


function New-PowerOutage {
    param(
        [string]$Server,
        [string[]]$VirtualMachines,
        [string]$Action = "Shutdown"
    )

    if ($Action -eq "Shutdown") {
        Write-Host "Shutting down virtual machines..."
        foreach ($VirtualMachine in $VirtualMachines) {
            Write-Host "Shutting down $VirtualMachine..."
            Stop-VM -Name $VirtualMachine -Force
        }
        Write-Host "Shutting down $Server..."
        Stop-Computer -ComputerName $Server -Force
        Write-Host "Power outage complete."
    }
    else {
        Write-Host "Monitoring virtual machines..."
        Get-VM -Name $VirtualMachines | Select-Object Name, State
    }
}

# I have three computers. 1 Hyper-V Server and 2 Virtual Machines.
# I need a user to be able to shutdown the Hyper-V Server and the Virtual Machines.
# I do not need to shut down the Virtual Machines individually.
# I have assigned permissions via group policy to allow the user to shutdown the Hyper-V Server remotely.
# When shutting down the hyper-v server, the virtual machines are also shut down.
# I need a function that the user can run that will shut down the hyper-v server and report back the state of the virtual machines so that the user can know if the virtual machines were shut down or not.
# Host Server = ABRIONSECTOR
# Virtual Machines = GEONOSIS, KAMINO
# The function should be simple to use. The user should be able to run the function and it should shut down the hyper-v server and report back the state of the virtual machines.
# The function should be able to be run from a remote computer.

function New-PowerOutage {
    param(
        [string]$Server,
        [switch]$Report
    )

    begin {
        $Server = "ABRIONSECTOR"
        $VirtualMachines = Get-VM -ComputerName $Server | Select-Object Name, State
    }

    process {
        if ($Report) {
            Write-Host "Monitoring virtual machines..."
            do {
                $VirtualMachineState = Get-VM -ComputerName $Server | Select-Object Name, State
                $VirtualMachineState | Where-Object { $_.State -eq "Running" }
                Start-Sleep -Seconds 5
            } until ($VirtualMachineState -eq "Stopped")
        }
        Stop-Computer -ComputerName $Server -Force
        do {
            $ServerState = Test-Connection -ComputerName $Server -Count 1 -Quiet
            Start-Sleep -Seconds 5
        } until ($ServerState -eq "Stopped")
        Write-Host "Power outage complete."
    }
}
