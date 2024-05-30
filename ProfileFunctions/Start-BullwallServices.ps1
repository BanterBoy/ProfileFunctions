# List of Ransomcare services to start
# Ransomcare Admin Service
# Ransomcare Accumulative Sensors Service
# Ransomcare Database Service
# Ransomcare Hub Service
# Ransomcare ML Service
# Ransomcare Share Service
# Ransomcare Sharepoint Service
# Ransomcare Validation Service

# Create function to start the Ransomcare services in order, but wait for each service to start before starting the next service
# Start-RansomcareServices

function Start-RansomcareServices {
    $services = @(
        "Ransomcare Admin Service",
        "Ransomcare Accumulative Sensors Service",
        "Ransomcare Database Service",
        "Ransomcare Hub Service",
        "Ransomcare ML Service",
        "Ransomcare Share Service",
        "Ransomcare Sharepoint Service",
        "Ransomcare Validation Service"
    )

    foreach ($service in $services) {
        try {
            Start-Service -Name $service -ErrorAction Stop
            do {
                Start-Sleep -Milliseconds 500
                $status = (Get-Service -Name $service).Status
            } until ($status -eq "Running")
            Write-Output "$service - started successfully."
        }
        catch {
            Write-Output "Failed to start $service - $($_.Exception.Message)"
        }
    }
}
