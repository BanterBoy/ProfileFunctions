function Generate-Meme {
    [CmdletBinding()]

    param (
        # might want to break this into validate sets specific to the meme so input parameters are specifically named and can have multiple counts. This will do for a POC
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet([GenerateMemeValidator])]
		[string]$Meme,

        [Parameter(Mandatory = $false)]
        [string]$BatmanText = "",

        [Parameter(Mandatory = $false)]
        [string]$RobinText = "",

        [Parameter(Mandatory = $false)]
        [string]$OutputDir = "C:\temp\memes",

        [Parameter(Mandatory = $false)]
        [string]$Font = "Microsoft Sans Serif",

        [Parameter(Mandatory = $false)]
        [int]$FontSize = 16
	)

    begin {
        Add-Type -AssemblyName System.Drawing

        $memeEngine = [GenerateMemeEngine]::new($Meme)

        # validate the meme
        if ($null -eq $memeEngine.Meme) {
            Write-Host -ForegroundColor Red "Meme not found."
            return
        }

        # ensure the output directory exists
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -ItemType Directory -Path $OutputDir | Out-Null
        }
    }

    process {
        try {
            $created = $memeEngine.GenerateImage($OutputDir, $BatmanText, $RobinText, $Font, $FontSize)

            if (-not [string]::IsNullOrEmpty($created)) {
                Write-Host "Meme created at $created"

                return
            }

            # if we get here, the image wasn't created
            Write-Host -ForegroundColor Red "Failed to create meme."            
        }
        catch {
            Write-Host -ForegroundColor Red "Failed to create meme: $_"
        }
    }
}

class GenerateMemeEngine {
    [PSCustomObject] $Meme = $null
    hidden [PSCustomObject] $Memes = @{
        "Batman-Slapping-Robin" = @{
            # probably want more of an ordered array of coordinate sets here rather than these strongly named keys
            "BatmanTextTopLeft" = @(230, 10);
            "BatmanTextBottomRight" = @(395, 80);
            "RobinTextTopLeft" = @(20, 10);
            "RobinTextBottomRight" = @(230, 80);
            # might be better to use a data uri for the image to keep the function self-contained?
            "Image" = "https://imgflip.com/s/meme/Batman-Slapping-Robin.jpg";
        }
    }

    GenerateMemeEngine() {
        # Default constructor for validator class
    }

    GenerateMemeEngine([string] $meme) {
        $this.Meme = $this.Memes[$meme]
    }

    [string] GenerateImage([string] $outputDir, [string] $batmanText, [string] $robinText, [string] $fontFamily, [int] $fontSize) {
        $imageFile = Join-Path -Path $outputDir -ChildPath "meme_$([System.DateTime]::Now.ToString("yyyyMMdd_HHmmss")).png"

        # Download the image
        $client = New-Object System.Net.WebClient
        $imageStream = $client.OpenRead($this.Meme["Image"])
        $image = [System.Drawing.Image]::FromStream($imageStream)
        $graphics = [System.Drawing.Graphics]::FromImage($image)
    
        # Define fonts and brushes
        $font = New-Object System.Drawing.Font($fontFamily, $fontSize, [System.Drawing.FontStyle]::Regular)
        $brush = New-Object Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0, 0, 0))
    
        # Calculate positions for text
        $rect1 = $this.GetTextRectangle($this.Meme["BatmanTextTopLeft"], $this.Meme["BatmanTextBottomRight"])
        $rect2 = $this.GetTextRectangle($this.Meme["RobinTextTopLeft"], $this.Meme["RobinTextBottomRight"])
    
        $format = [System.Drawing.StringFormat]::GenericDefault
        $format.Alignment = [System.Drawing.StringAlignment]::Near
        $format.LineAlignment = [System.Drawing.StringAlignment]::Near
    
        # Draw text
        $graphics.DrawString($batmanText, $font, $brush, $rect1, $format)
        $graphics.DrawString($robinText, $font, $brush, $rect2, $format)
    
        # Save the image
        $image.Save($imageFile, [System.Drawing.Imaging.ImageFormat]::Png)
    
        # Cleanup
        $graphics.Dispose()
        $image.Dispose()
        $client.Dispose()

        return $imageFile
    }

    hidden [System.Drawing.RectangleF] GetTextRectangle([int[]] $topLeft, [int[]] $bottomRight) {
        return [System.Drawing.RectangleF]::FromLTRB($topLeft[0], $topLeft[1], $bottomRight[0], $bottomRight[1])
    }

    [String[]] MemeKeys() {
        return $this.Memes.Keys
    }
}

class GenerateMemeValidator : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return [GenerateMemeEngine]::new().MemeKeys()
    }
}