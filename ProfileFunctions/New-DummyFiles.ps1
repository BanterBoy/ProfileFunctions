function New-DummyFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$baseDirectory,
        [Parameter(Mandatory = $true)]
        [int]$numFiles,
        [Parameter(Mandatory = $false)]
        [string[]]$fileTypes = @("txt", "log", "csv", "xml", "json", "png", "properties")
    )

    # Create the base directory if it doesn't exist
    if (-Not (Test-Path $baseDirectory)) {
        New-Item -Path $baseDirectory -ItemType Directory | Out-Null
    }

    try {
        # Create files
        for ($i = 0; $i -lt $numFiles; $i++) {
            # Select a random file type from the specified types
            $fileType = Get-Random -InputObject $fileTypes

            # Create the file
            $filePath = Join-Path -Path $baseDirectory -ChildPath ("file{0}.{1}" -f $i, $fileType)

            switch ($fileType) {
                'txt' {
                    $txtContent = @(
                        "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                        "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                        "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                        "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
                        "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
                        # Add more text here...
                    ) -join "`n"
                    $txtContent | Set-Content -Path $filePath | Out-Null
                }
                'log' {
                    $logContent = @(
                        "2021-01-01 12:00:00 INFO: Application started",
                        "2021-01-01 12:01:00 ERROR: An error occurred",
                        "2021-01-01 12:02:00 INFO: Application stopped"
                        # Add more log entries here...
                    ) -join "`n"
                    $logContent | Set-Content -Path $filePath | Out-Null
                }
                'csv' {
                    $csvContent = @(
                        "Name,Age,City,Occupation",
                        "John,30,New York,Engineer",
                        "Jane,25,Los Angeles,Doctor"
                        # Add more people here...
                    ) -join "`n"
                    $csvContent | Set-Content -Path $filePath | Out-Null
                }
                'xml' {
                    $xmlContent = New-Object System.Xml.XmlDocument
                
                    $people = $xmlContent.CreateElement("people")
                    $xmlContent.AppendChild($people) | Out-Null
                
                    $person1 = $xmlContent.CreateElement("person")
                    $name1 = $xmlContent.CreateElement("name")
                    $name1.InnerText = "John Doe"
                    $age1 = $xmlContent.CreateElement("age")
                    $age1.InnerText = "30"
                    $person1.AppendChild($name1) | Out-Null
                    $person1.AppendChild($age1) | Out-Null
                
                    $person2 = $xmlContent.CreateElement("person")
                    $name2 = $xmlContent.CreateElement("name")
                    $name2.InnerText = "Jane Doe"
                    $age2 = $xmlContent.CreateElement("age")
                    $age2.InnerText = "25"
                    $person2.AppendChild($name2) | Out-Null
                    $person2.AppendChild($age2) | Out-Null
                
                    $people.AppendChild($person1) | Out-Null
                    $people.AppendChild($person2) | Out-Null
                
                    $xmlContent.Save($filePath) | Out-Null
                }
                'json' {
                    $jsonObject = @(
                        @{ Name = 'John'; Age = 30; City = 'New York'; Occupation = 'Engineer' },
                        @{ Name = 'Jane'; Age = 25; City = 'Los Angeles'; Occupation = 'Doctor' },
                        @{ Name = 'Alice'; Age = 35; City = 'Chicago'; Occupation = 'Teacher' },
                        @{ Name = 'Bob'; Age = 40; City = 'Houston'; Occupation = 'Lawyer' },
                        @{ Name = 'Charlie'; Age = 45; City = 'Philadelphia'; Occupation = 'Architect' },
                        @{ Name = 'David'; Age = 50; City = 'Phoenix'; Occupation = 'Chef' },
                        @{ Name = 'Eve'; Age = 55; City = 'San Antonio'; Occupation = 'Photographer' },
                        @{ Name = 'Frank'; Age = 60; City = 'San Diego'; Occupation = 'Pilot' },
                        @{ Name = 'Grace'; Age = 65; City = 'Dallas'; Occupation = 'Nurse' },
                        @{ Name = 'Helen'; Age = 70; City = 'San Jose'; Occupation = 'Scientist' }
                    ) | ConvertTo-Json
                    $jsonObject | Set-Content -Path $filePath | Out-Null
                }
                'png' {
                    Add-Type -AssemblyName System.Drawing
                    $bitmap = New-Object System.Drawing.Bitmap(100, 100)
                    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
                    $graphics.Clear([System.Drawing.Color]::White)
                    $graphics.FillEllipse([System.Drawing.Brushes]::SkyBlue, 10, 10, 80, 80)
                    $bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png) | Out-Null
                    $graphics.Dispose()
                    $bitmap.Dispose()
                }
                'properties' {
                    $propertiesContent = @(
                        "Name=John",
                        "Age=30",
                        "City=New York",
                        "Occupation=Engineer",
                        "",
                        "Name=Jane",
                        "Age=25",
                        "City=Los Angeles",
                        "Occupation=Doctor"
                        # Add more people here...
                    ) -join "`n"
                    $propertiesContent | Set-Content -Path $filePath | Out-Null
                }
            }
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}
