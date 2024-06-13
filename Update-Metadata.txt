# Load TagLibSharp library from the extracted location
Add-Type -Path "C:\TagLibSharp\TagLibSharp.dll"

function Update-Metadata {
    param (
        [string]$baseDir
    )

    $directories = Get-ChildItem -Path $baseDir -Directory

    foreach ($directory in $directories) {
        $season = $directory.Name
        $files = Get-ChildItem -Path $directory.FullName -Filter *.mp3

        foreach ($file in $files) {
            # Extract episode details from file name
            if ($file.Name -match "^S(\d+)E(\d+)(.*?)\.mp3$") {
                $seasonNumber = $matches[1]
                $episodeNumber = $matches[2]
                $episodeTitle = $matches[3] -replace "[-,_]", " " -replace "^\s+", ""

                # Update metadata using TagLib
                $fileTag = [TagLib.File]::Create($file.FullName)
                $fileTag.Tag.Title = $episodeTitle
                $fileTag.Tag.Album = "I'm Sorry I Haven't a Clue - Season $seasonNumber"
                $fileTag.Tag.Track = [int]$episodeNumber
                $fileTag.Tag.Year = 1972 + [int]$seasonNumber # Adjust year as necessary
                $fileTag.Save()

                Write-Output "Updated: $($file.FullName)"
            }
        }
    }
}

# Specify the base directory containing the seasons folders
$baseDirectory = "\\DEATHSTAR.DOMAIN.LEIGH-SERVICES.COM\PUBLIC\PODCASTS\I'M SORRY I HAVEN'T A CLUE"
Update-Metadata -baseDir $baseDirectory


