function Test-BdayDayOfWeek {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $FilePath
    )    
    begin {
        $Users = Get-Content -Path $FilePath | ConvertFrom-Csv -Delimiter ','
    }
    
    process {
        try {
            foreach ($User in $Users) {
                $DayofWeek = (Get-Date -Date "$($User.DOB)").DayOfWeek
                $properties = [Ordered]@{
                    Forename = $User.Forename
                    Surname  = $User.Surname
                    Day      = ($User.DOB).Split('/')[0]
                    Month    = ($User.DOB).Split('/')[1]
                    Year     = ($User.DOB).Split('/')[2]
                    Weekday  = $DayofWeek
                }
                $obj = New-Object -TypeName PSObject -Property $properties
                Write-Output $obj
            }
        }
        catch {
            Write-Error -Message "$_"
        } 
        
    }
    end {
        
    }
}


# $Filename = "D:\GitRepos\Carpetright\Tools\InProgress\DOBs.csv"
# $Data = Test-BdayDayOfWeek -FilePath $Filename
# $Data | Get-Member
# $Data | Sort-Object -Property Surname, Forename | Format-Table -AutoSize
