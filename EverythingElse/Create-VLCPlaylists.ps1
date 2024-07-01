function Create-VLCPlaylists {
    param (
        [string]$baseDir
    )

    $directories = Get-ChildItem -Path $baseDir -Directory

    foreach ($directory in $directories) {
        $season = $directory.Name
        $playlistPath = Join-Path -Path $directory.FullName -ChildPath "$season.m3u"

        # Get all MP3 files in the current season directory
        $mp3Files = Get-ChildItem -Path $directory.FullName -Filter *.mp3 | Sort-Object Name

        # Create the M3U playlist content
        $playlistContent = "#EXTM3U`r`n"
        foreach ($file in $mp3Files) {
            $relativePath = [System.IO.Path]::GetFileName($file.FullName)
            $playlistContent += "#EXTINF:-1," + [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + "`r`n"
            $playlistContent += "$relativePath`r`n"
        }

        # Save the playlist content to a .m3u file
        Set-Content -Path $playlistPath -Value $playlistContent -Encoding UTF8
        Write-Output "Created playlist: $playlistPath"
    }
}

# Specify the base directory containing the seasons folders
$baseDirectory = "\\DEATHSTAR.DOMAIN.LEIGH-SERVICES.COM\PUBLIC\PODCASTS\I'M SORRY I HAVEN'T A CLUE"
Create-VLCPlaylists -baseDir $baseDirectory
