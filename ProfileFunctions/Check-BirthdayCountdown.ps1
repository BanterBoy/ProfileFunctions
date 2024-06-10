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
