<#
.SYNOPSIS
Checks the number of days until a person's birthday.

.DESCRIPTION
The Check-BirthdayCountdown function calculates the number of days until a person's birthday based on their date of birth (DOB) provided in a CSV file. It then checks if the birthday is within the next 14 days and outputs a message accordingly.

.PARAMETER CsvPath
The path to the CSV file containing the list of people and their DOBs.

.EXAMPLE
Check-BirthdayCountdown -CsvPath "C:\Path\To\Birthdays.csv"
Calculates the number of days until each person's birthday in the specified CSV file and outputs a message if the birthday is within the next 14 days.

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS
System.String. The function outputs a message indicating the number of days until each person's birthday if it is within the next 14 days.

.NOTES
This function requires PowerShell version 3.0 or above.

.LINK
https://github.com/your-repo/Check-BirthdayCountdown.ps1
#>
function Check-BirthdayCountdown {
    param (
        [string]$CsvPath
    )

    # Import the CSV file
    $birthdays = Import-Csv -Path $CsvPath

    # Get today's date
    $today = Get-Date

    foreach ($person in $birthdays) {
        # Extract the day and month from the DOB
        $dob = [datetime]::ParseExact($person.DOB, 'dd/MM/yyyy', $null)
        $dobDay = $dob.Day
        $dobMonth = $dob.Month

        # Create a new date for this year's birthday
        $birthdayThisYear = Get-Date -Year $today.Year -Month $dobMonth -Day $dobDay

        # Calculate the difference in days between today and the birthday
        $daysUntilBirthday = ($birthdayThisYear - $today).Days

        # Check if the birthday is within the next 14 days
        if ($daysUntilBirthday -le 14 -and $daysUntilBirthday -ge 0) {
            if ($daysUntilBirthday -eq 0) {
                Write-Output "Happy Birthday, $($person.Forename) $($person.Surname)!"
            }
            else {
                Write-Output "$($person.Forename) $($person.Surname)'s birthday is in $daysUntilBirthday days!"
            }
        }
    }
}
