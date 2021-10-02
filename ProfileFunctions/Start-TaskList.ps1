function Start-TaskList {
    $PSDefaultParameterValues['Write-Progress:Activity'] = ' 🤔 Processing task list...'
    Write-Progress -Status 'Begining task automation. 👆' -PercentComplete 3
    Start-Sleep -Seconds 2
    10..45 | ForEach-Object {
        Write-Progress -Status 'Doing the stuff 👉' -PercentComplete $_
        Start-Sleep -Seconds 5
    }
    Start-Sleep -Seconds 4

    46..79 | ForEach-Object {
        Write-Progress -Status 'Doing other important stuff 👍' -PercentComplete $_
        Start-Sleep -Seconds 5
    }
    Start-Sleep -Seconds 8

    Write-Progress -Status '🤷‍♂️ Still doing all of the important task list stuff' -PercentComplete 85
    Start-Sleep -Seconds 14

    Write-Progress -Status 'Nearly there.........its a big list! 😢' -PercentComplete 97
    Start-Sleep -Seconds 2

    Write-Progress -Status 'Yep.....done all that stuff now. 😉' -Completed
    Write-Output "Task automation completed. 😎"
}

# Start-TaskList