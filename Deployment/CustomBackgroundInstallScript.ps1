# Call the function and store the returned values in an array
$returnedValues = Initialize-TeamsLocalUploadFolder -IncludeNewTeams $true

# Access the returned values from the array
$teamsLocalUploadFolderExists = $returnedValues[0]
$NewTeamsLocalUploadFolderExists = $returnedValues[1]

# Now you can use the variables in your script
if ($teamsLocalUploadFolderExists) {
    Write-Output "Teams local upload folder exists."
}
else {
    Write-Output "Teams local upload folder does not exist."
}

if ($NewTeamsLocalUploadFolderExists) {
    Write-Output "New Teams local upload folder exists."
}
else {
    Write-Output "New Teams local upload folder does not exist."
}


