function Restart-NinjaRMMService {
    try {
        Write-Output "Stopping Ninja Patcher process"
        Get-Process -Name NinjaRMMAgentPatcher | Stop-Process -Force
    }
    catch {
        Write-Output "Ninja process not found"
    }
    
    try {
        Write-Output "Stopping Ninja services"
        Get-Service -Name NinjaRMMAgent | Stop-Process -Force -PassThru
        Write-Output "Ninja services stopped"
        Start-Sleep -Seconds 5
        Start-Service -Name NinjaRMMAgent -PassThru
        Write-Output "Ninja services started"
    }
    catch {
        Write-Output "Ninja services not found"
    }
}
