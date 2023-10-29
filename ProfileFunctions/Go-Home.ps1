$global:prevLocation = $PWD
function Go-Home {
    $global:prevLocation = $PWD
    Set-Location C:\
}

function Go-Back {
    Set-Location $global:prevLocation
}