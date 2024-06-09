function Export-OUsToImage {

    <#

    .SYNOPSIS
    Outputs image of Active Directory OU structure.

    .DESCRIPTION
    Exports OU structure from the domain of user running script into an image file.
    Utilizies Windows Forms TreeView control to generate tree structure and save to image.

    .PARAMETER Path
    Specifies output image filename. Format auto-detected based on extension. 
    If extension not recognized will default to PNG format.
    Supported formats include:
    .BMP
    .GIF
    .JPG
    .PNG
    .TIFF

    .INPUTS
    None.

    .OUTPUTS
    OUs displayed to console, image generated saved to disk.

    .NOTES
    Version:        1.0
    Author:         Malcolm McCaffery
    Creation Date:  15/10/2018
    Purpose/Change: Initial script development

    .EXAMPLE
        Export-OUsToImage -Path C:\support\OUStructure.jpg
    #> 

    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateScript( {
                if ( -Not ($_.DirectoryName | Test-Path) ) {
                    throw "File or folder does not exist"
                }
                return $true
            })]
        [System.IO.FileInfo]$Path)

    Add-Type -AssemblyName 'System.Windows.Forms'
    Add-Type -AssemblyName 'System.Drawing'
    Add-Type -AssemblyName 'System.DirectoryServices'

    # Folder icono, this code generated with following code
    #$image = [System.Drawing.Image]::FromFile("C:\support\scripts\AD\folder.png")
    #$ms = New-Object System.IO.MemoryStream
    #$image.Save($ms,$image.RawFormat)
    #$arr = $ms.ToArray()
    #$result = "$FolderImage = @(```r`n"
    #$c = 0
    #ForEach ($a in $arr)
    #{
    #    $c++
    #    $result+=("0x{0:x}," -f $a )
    #    if ($c -gt 20)
    #    {
    #        $c =0
    #        $result+="```r`n"
    #    }
    #
    #}
    #$result += ")"

    [Byte[]]$folderImageBytes = @(`
            0x89, 0x50, 0x4e, 0x47, 0xd, 0xa, 0x1a, 0xa, 0x0, 0x0, 0x0, 0xd, 0x49, 0x48, 0x44, 0x52, 0x0, 0x0, 0x0, 0x30, 0x0, `
            0x0, 0x0, 0x30, 0x8, 0x6, 0x0, 0x0, 0x0, 0x57, 0x2, 0xf9, 0x87, 0x0, 0x0, 0x0, 0x4, 0x67, 0x41, 0x4d, 0x41, 0x0, `
            0x0, 0xb1, 0x8f, 0xb, 0xfc, 0x61, 0x5, 0x0, 0x0, 0x0, 0x9, 0x70, 0x48, 0x59, 0x73, 0x0, 0x0, 0xe, 0xc2, 0x0, 0x0, `
            0xe, 0xc2, 0x1, 0x15, 0x28, 0x4a, 0x80, 0x0, 0x0, 0x1, 0x61, 0x49, 0x44, 0x41, 0x54, 0x68, 0x43, 0xed, 0x92, 0xb1, 0x4a, `
            0x3, 0x41, 0x14, 0x45, 0xa7, 0xd0, 0x3f, 0x10, 0x9b, 0xa8, 0x85, 0xb8, 0xc9, 0x6a, 0xeb, 0x37, 0xf8, 0x5d, 0xfe, 0x89, 0x6, `
            0xd4, 0x42, 0x8c, 0x9d, 0x76, 0x82, 0x5d, 0x36, 0xbb, 0xe0, 0x4f, 0x8, 0x96, 0x11, 0x8d, 0xfd, 0x7b, 0x4e, 0xc2, 0xad, 0xe4, `
            0xde, 0x18, 0x1b, 0xf7, 0x15, 0x73, 0xe0, 0x74, 0xb9, 0xc3, 0x99, 0x9d, 0xa4, 0x42, 0xa1, 0x50, 0x28, 0x14, 0x7e, 0x62, 0x17, `
            0x69, 0xdf, 0xc6, 0x69, 0x92, 0x5d, 0xf8, 0x38, 0xf9, 0x26, 0xe6, 0xdf, 0x9e, 0x63, 0xde, 0x2f, 0x76, 0x95, 0xf6, 0x72, 0xcc, `
            0x9c, 0x45, 0xfe, 0x66, 0x88, 0x4b, 0xd8, 0x65, 0xba, 0x63, 0x71, 0x9b, 0xda, 0xfb, 0x25, 0xf2, 0x5, 0xbe, 0x58, 0xd8, 0x5f, `
            0xec, 0xf5, 0x12, 0xab, 0x88, 0x9b, 0x6d, 0xf7, 0xa7, 0x81, 0xfb, 0x6c, 0xe8, 0xde, 0xd5, 0xbd, 0x6a, 0xb3, 0xa1, 0xd9, 0xf3, `
            0xc1, 0x9b, 0x3d, 0xee, 0x9e, 0x21, 0x71, 0x3d, 0x7e, 0xbd, 0xe5, 0xde, 0x54, 0xf4, 0xb0, 0x3e, 0xb5, 0x69, 0x65, 0xfe, 0xb0, `
            0x73, 0x8a, 0x4c, 0xcd, 0xea, 0xcb, 0x93, 0x3, 0x22, 0x98, 0x5f, 0xe2, 0x15, 0x99, 0x9a, 0x8, 0x7f, 0x1b, 0xa5, 0x35, 0x43, `
            0x43, 0xa6, 0x86, 0xd, 0x23, 0x89, 0x4c, 0xd, 0x1b, 0x45, 0x12, 0x99, 0x1a, 0x36, 0x8a, 0x24, 0x32, 0x35, 0x6c, 0x14, 0x49, `
            0x64, 0x6a, 0xd8, 0x28, 0x92, 0xc8, 0xd4, 0xb0, 0x51, 0x24, 0x91, 0xa9, 0x61, 0xa3, 0x48, 0x22, 0x53, 0xc3, 0x46, 0x91, 0x44, `
            0xa6, 0x86, 0x8d, 0x22, 0x89, 0x4c, 0xd, 0x1b, 0x45, 0x12, 0x99, 0x1a, 0x36, 0x8a, 0x24, 0x32, 0x35, 0x6c, 0x14, 0x49, 0x64, `
            0x6a, 0xd8, 0x28, 0x92, 0xc8, 0xd4, 0xb0, 0x51, 0x24, 0x91, 0xa9, 0x61, 0xa3, 0x48, 0x22, 0x53, 0xc3, 0x46, 0x91, 0x44, 0xa6, `
            0x86, 0x8d, 0x22, 0x89, 0x4c, 0xd, 0x1b, 0x45, 0x12, 0x99, 0x1a, 0x36, 0x8a, 0x24, 0x32, 0x35, 0x6c, 0x14, 0x49, 0x64, 0x6a, `
            0xac, 0xab, 0x17, 0x6c, 0x18, 0xc1, 0xdc, 0xf6, 0x89, 0x4c, 0x8d, 0xb5, 0xa3, 0x7b, 0x36, 0x8e, 0xa0, 0xb5, 0xf5, 0x4, 0x99, `
            0x1a, 0x6b, 0x8e, 0x2b, 0xeb, 0x46, 0x73, 0x76, 0x40, 0x9f, 0xe6, 0xa6, 0x77, 0xef, 0xaa, 0x43, 0x64, 0xae, 0xc7, 0xa6, 0xd5, `
            0x20, 0x3f, 0xd7, 0xed, 0xf2, 0xc9, 0xd8, 0x61, 0xff, 0x6a, 0x5b, 0x7f, 0x2c, 0xbf, 0xbc, 0xbd, 0x9c, 0x1c, 0x21, 0xaf, 0x50, `
            0x28, 0x14, 0xa, 0x5, 0x90, 0xd2, 0x37, 0x8f, 0x8a, 0x6e, 0xbd, 0x1e, 0x85, 0x16, 0xcf, 0x0, 0x0, 0x0, 0x0, 0x49, 0x45, `
            0x4e, 0x44, 0xae, 0x42, 0x60, 0x82)

    $ms = New-Object System.IO.MemoryStream($folderImageBytes, 0, $folderImageBytes.Length)
    $ms.Position = 0
    $folderImage = [System.Drawing.Image]::FromStream($ms, $true)
    $ms.Close()

    # todo: calculate dynamically depending on OU structure
    $IMAGE_WIDTH = 800

    # easy way $OUs = Get-ADOrganizationalUnit -Filter *
    # but needs RSAT installed, so using System.DirectoryServices Instead
    $rootDE = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().GetDirectoryEntry()
    $searcher = New-Object System.DirectoryServices.DirectorySearcher($rootDE)
    $searcher.Filter = "(objectCategory=organizationalUnit)";

    $OUs = @()
    foreach ($result in $searcher.FindAll()) {
        $OUs += $result.Properties.distinguishedname
    }

    $treeView = New-Object System.Windows.Forms.TreeView
    $imageList = New-Object System.Windows.Forms.ImageList
    $imageList.Images.Add($folderImage)
    $treeView.ImageList = $imageList
    $treeView.Top = 0
    $treeView.Left = 0

    ForEach ($ou in $OUs) {

        $domain = $OU.Substring($OU.IndexOf("DC=") + 3).Replace(",DC=", ".")
        $SplitDN = $OU.Substring(0, $OU.IndexOf(",DC=")).`
            Replace(",OU=", "\").`
            Replace(",CN=", "\").`
            Replace("OU=", "").`
            Replace("CN=", "").Split("\")

        $ReversedDN = New-Object System.Text.StringBuilder
        [void]$reversedDn.Append($domain)
        For ($i = $SplitDN.Count - 1; $i -ge 0; $i--) {
            [void]$ReversedDn.Append("\$($SplitDN[$i])")
        }

        $currentNode = $null
    
        Write-Host $ReversedDN.ToString()

        ForEach ($item in $ReversedDN.ToString().Split("\")) { 
            if ($null -eq $currentNode) {
                $currentNode = $treeView.Nodes[$item]
                if ($null -eq $currentNode) {
                    $currentNode = $treeView.Nodes.Add($item)
                    $currentNode.Name = $item
                }
    
            }
            else {
                if ($null -eq $currentNode.Nodes[$item]) {
                    $currentNode = $currentNode.Nodes.Add($item)
                    $currentNode.Name = $item 
                }
                else {
                    $currentNode = $currentNode.Nodes[$item]
                }
            }
        }
    }

    [void]$treeView.ExpandAll()

    $treeView.Width = $IMAGE_WIDTH
    $treeView.Height = ($treeView.GetNodeCount($true) + 1) * ($treeView.ItemHeight)

    $bmp = New-Object System.Drawing.Bitmap($treeView.Width, $treeView.Height)
    [void]$treeView.DrawToBitmap($bmp, (New-Object System.Drawing.Rectangle(0, 0, $bmp.Width, $bmp.Height)))
    [void]$bmp.Save($Path.FullName)

    Write-Host "Image saved to $Path"
}