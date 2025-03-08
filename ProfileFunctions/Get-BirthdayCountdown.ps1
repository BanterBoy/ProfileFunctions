<#
.SYNOPSIS
Checks the number of days until a person's birthday.

.DESCRIPTION
The Check-BirthdayCountdown function calculates the number of days until a person's birthday based on their date of birth (DOB) provided in a CSV file. It then checks if the birthday is within the next 14 days and outputs a message accordingly.

.PARAMETER CsvPath
The path to the CSV file containing the list of people and their DOBs.

.PARAMETER ShowAll
If specified, the function will output the number of days until or since each person's birthday, regardless of whether it is within the next 14 days.

.PARAMETER ShowNext
If specified, the function will output only the next upcoming birthday and the number of days until it occurs.

.EXAMPLE
Get-BirthdayCountdown -ShowNext
Calculates the number of days until each person's birthday in the specified CSV file and outputs only the next upcoming birthday.

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS
System.String. The function outputs a message indicating the number of days until the next upcoming birthday (when -ShowNext is used) or a message for each birthday within the next 14 days.

.NOTES
This function requires PowerShell version 3.0 or above.

.LINK
https://github.com/your-repo/Get-BirthdayCountdown.ps1
#>
function Get-BirthdayCountdown {
    param (
        [switch]$ShowAll,
        [switch]$ShowNext
    )

    # Import the CSV file
    $birthdays = Import-Csv -Path "$PSScriptRoot\DOBs.csv"

    # Get today's date
    $today = Get-Date

    $results = @()
    $nextBirthday = $null
    $minDaysUntilBirthday = [int]::MaxValue

    foreach ($person in $birthdays) {
        # Extract the day and month from the DOB
        $dob = [datetime]::ParseExact($person.DOB, 'dd/MM/yyyy', $null)
        $dobDay = $dob.Day
        $dobMonth = $dob.Month

        # Create a new date for this year's birthday
        $birthdayThisYear = Get-Date -Year $today.Year -Month $dobMonth -Day $dobDay

        # Calculate the difference in days between today and the birthday.
        $daysUntilBirthday = ($birthdayThisYear - $today).Days

        # Format the status with a leading sign:
        $status = if ($daysUntilBirthday -ge 0) { "+$daysUntilBirthday" } else { "$daysUntilBirthday" }

        if ($ShowAll) {
            $results += [pscustomobject]@{
                Forename          = $person.Forename
                Surname           = $person.Surname
                DOB               = $person.DOB
                Status            = $status
                DaysUntilBirthday = $daysUntilBirthday  # for sorting only
            }
        }
        elseif (-not $ShowNext) {
            # Output per-person if not using ShowNext.
            if ($daysUntilBirthday -le 14 -and $daysUntilBirthday -ge 0) {
                if ($daysUntilBirthday -eq 0) {
                    Write-Output "Happy Birthday, $($person.Forename) $($person.Surname)!"
                }
                else {
                    Write-Output "$($person.Forename) $($person.Surname)'s birthday is in +$daysUntilBirthday days!"
                }
            }
        }

        # Determine the next upcoming birthday (only considering future dates)
        if ($daysUntilBirthday -ge 0 -and $daysUntilBirthday -lt $minDaysUntilBirthday) {
            $minDaysUntilBirthday = $daysUntilBirthday
            $nextBirthday = [pscustomobject]@{
                Forename          = $person.Forename
                Surname           = $person.Surname
                DOB               = $person.DOB
                DaysUntilBirthday = if ($daysUntilBirthday -ge 0) { "+$daysUntilBirthday" } else { "$daysUntilBirthday" }
            }
        }
    }

    if ($ShowAll) {
        # Sort the results numerically by the DaysUntilBirthday field and return only the desired properties.
        return $results | Sort-Object -Property DaysUntilBirthday | Select-Object Forename, Surname, DOB, Status
    }

    if ($ShowNext -and $nextBirthday) {
        Write-Output "The next upcoming birthday is $($nextBirthday.Forename) $($nextBirthday.Surname)'s in $($nextBirthday.DaysUntilBirthday) days."
    }
}
