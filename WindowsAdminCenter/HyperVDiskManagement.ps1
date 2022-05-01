function Dismount-StorageVHD {
<#
.SYNOPSIS
Detaches the VHD.

.DESCRIPTION
Detaches the VHD.

.ROLE
Administrators

.PARAMETER location
    The disk location
#>
param (
    [parameter(Mandatory=$true)]
    [String]
    $location
)

Import-Module Storage

Dismount-DiskImage -ImagePath $location
}
## [END] Dismount-StorageVHD ##
function Edit-StorageVolume {
 <#

.SYNOPSIS
Update volume properties.

.DESCRIPTION
Update volume properties.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER diskNumber
    The disk number.

.PARAMETER partitionNumber
    The partition number.

.PARAMETER oldDriveLetter
    Volume old dirve letter.

.PARAMETER newVolumeName
    Volume new name.    

.PARAMETER newDriveLetter
    Volume new dirve letter.

.PARAMETER driveType
    Volume drive type.

#>

 param (
    [String]
    $diskNumber,
    [uint32]
    $partitionNumber,
    [char]
    $newDriveLetter,
    [int]
    $driveType,
    [char]
    $oldDriveLetter,
    [String]
    $newVolumeName
)

Import-Module Microsoft.PowerShell.Management
Import-Module Storage

if($oldDriveLetter -ne $newDriveLetter) {
    if($driveType -eq 5 -or $driveType -eq 2)
    {
        $drv = Get-WmiObject win32_volume -filter "DriveLetter = '$($oldDriveLetter):'"
        $drv.DriveLetter = "$($newDriveLetter):"
        $drv.Put() | out-null
    } 
    else
    {
        Set-Partition -DiskNumber $diskNumber -PartitionNumber $partitionNumber -NewDriveLetter $newDriveLetter
    }

    # In case of CD ROM, volume label update is not supported.
    if ($driveType -ne 5)
    {
        Set-Volume -DriveLetter $newDriveLetter -NewFileSystemLabel $newVolumeName
    }
} 
else 
{
    Set-Volume -DriveLetter $newDriveLetter -NewFileSystemLabel $newVolumeName
}
}
## [END] Edit-StorageVolume ##
function Format-StorageVolume {
<#

.SYNOPSIS
Formats a drive by drive letter.

.DESCRIPTION
Formats a drive by drive letter.

.ROLE
Administrators

.PARAMETER driveLetter
    The drive letter.

.PARAMETER allocationUnitSizeInBytes
    The allocation unit size.

.PARAMETER fileSystem
    The file system type.

.PARAMETER fileSystemLabel
    The file system label.    

.PARAMETER compress
    True to compress, false otherwise.

.PARAMETER quickFormat
    True to run a quick format.
#>
param (
    [Parameter(Mandatory = $true)]
    [String]
    $driveLetter,

    [UInt32]
    $allocationUnitSizeInBytes,

    [String]
    $fileSystem,

    [String]
    $newFileSystemLabel,

    [Boolean]
    $compress = $false,

    [Boolean]
    $quickFormat = $true
)

Import-Module Storage

#
# Prepare parameters for command Format-Volume
#
$FormatVolumecmdParams = @{
    DriveLetter = $driveLetter;
    Compress = $compress;
    Full = -not $quickFormat}

if($allocationUnitSizeInBytes -ne 0)
{
    $FormatVolumecmdParams.AllocationUnitSize = $allocationUnitSizeInBytes
}

if ($fileSystem)
{
    $FormatVolumecmdParams.FileSystem = $fileSystem
}

if ($newFileSystemLabel)
{
    $FormatVolumecmdParams.NewFileSystemLabel = $newFileSystemLabel
}

Format-Volume @FormatVolumecmdParams -confirm:$false

}
## [END] Format-StorageVolume ##
function Get-StorageDisk {
<#

.SYNOPSIS
Enumerates all of the local disks of the system.

.DESCRIPTION
Enumerates all of the local disks of the system.

.ROLE
Readers

#>
param (
    [Parameter(Mandatory = $false)]
    [String]
    $DiskId
)

Import-Module CimCmdlets
Import-Module Microsoft.PowerShell.Utility

<#
.Synopsis
    Name: Get-Disks
    Description: Gets all the local disks of the machine.

.Parameters
    $DiskId: The unique identifier of the disk desired (Optional - for cases where only one disk is desired).

.Returns
    The local disk(s).
#>
function Get-DisksInternal
{
    param (
        [Parameter(Mandatory = $false)]
        [String]
        $DiskId
    )

    Remove-Module Storage -ErrorAction Ignore; # Remove the Storage module to prevent it from automatically localizing

    $isDownlevel = [Environment]::OSVersion.Version.Major -lt 10;
    if ($isDownlevel)
    {
        $disks = Get-CimInstance -ClassName MSFT_Disk -Namespace Root\Microsoft\Windows\Storage | Where-Object { !$_.IsClustered };
    }
    else
    {
        $subsystem = Get-CimInstance -ClassName MSFT_StorageSubSystem -Namespace Root\Microsoft\Windows\Storage| Where-Object { $_.FriendlyName -like "Win*" };
        $disks = $subsystem | Get-CimAssociatedInstance -ResultClassName MSFT_Disk;
    }

    if ($DiskId)
    {
        $disks = $disks | Where-Object { $_.UniqueId -eq $DiskId };
    }


    $disks | %{
    $partitions = $_ | Get-CimAssociatedInstance -ResultClassName MSFT_Partition
    $volumes = $partitions | Get-CimAssociatedInstance -ResultClassName MSFT_Volume
    $volumeIds = @()
    $volumes | %{
        
        $volumeIds += $_.path 
    }
        
    $_ | Add-Member -NotePropertyName VolumeIds -NotePropertyValue $volumeIds

    }

    $disks = $disks | ForEach-Object {

       $disk = @{
            AllocatedSize = $_.AllocatedSize;
            BootFromDisk = $_.BootFromDisk;
            BusType = $_.BusType;
            FirmwareVersion = $_.FirmwareVersion;
            FriendlyName = $_.FriendlyName;
            HealthStatus = $_.HealthStatus;
            IsBoot = $_.IsBoot;
            IsClustered = $_.IsClustered;
            IsOffline = $_.IsOffline;
            IsReadOnly = $_.IsReadOnly;
            IsSystem = $_.IsSystem;
            LargestFreeExtent = $_.LargestFreeExtent;
            Location = $_.Location;
            LogicalSectorSize = $_.LogicalSectorSize;
            Model = $_.Model;
            NumberOfPartitions = $_.NumberOfPartitions;
            OfflineReason = $_.OfflineReason;
            OperationalStatus = $_.OperationalStatus;
            PartitionStyle = $_.PartitionStyle;
            Path = $_.Path;
            PhysicalSectorSize = $_.PhysicalSectorSize;
            ProvisioningType = $_.ProvisioningType;
            SerialNumber = $_.SerialNumber;
            Signature = $_.Signature;
            Size = $_.Size;
            UniqueId = $_.UniqueId;
            UniqueIdFormat = $_.UniqueIdFormat;
            volumeIds = $_.volumeIds;
            Number = $_.Number;
        }
        if (-not $isDownLevel)
        {
            $disk.IsHighlyAvailable = $_.IsHighlyAvailable;
            $disk.IsScaleOut = $_.IsScaleOut;
        }
        return $disk;
    }

    if ($isDownlevel)
    {
        $healthStatusMap = @{
            0 = 3;
            1 = 0;
            4 = 1;
            8 = 2;
        };

        $operationalStatusMap = @{
            0 = @(0);      # Unknown
            1 = @(53264);  # Online
            2 = @(53265);  # Not ready
            3 = @(53266);  # No media
            4 = @(53267);  # Offline
            5 = @(53268);  # Error
            6 = @(13);     # Lost communication
        };

        $disks = $disks | ForEach-Object {
            $_.HealthStatus = $healthStatusMap[[int32]$_.HealthStatus];
            $_.OperationalStatus = $operationalStatusMap[[int32]$_.OperationalStatus[0]];
            $_;
        };
    }

    return $disks;
}

if ($DiskId)
{
    Get-DisksInternal -DiskId $DiskId
}
else
{
    Get-DisksInternal
}

}
## [END] Get-StorageDisk ##
function Get-StorageFileShare {
<#

.SYNOPSIS
Enumerates all of the local file shares of the system.

.DESCRIPTION
Enumerates all of the local file shares of the system.

.ROLE
Readers

.PARAMETER FileShareId
    The file share ID.
#>
param (
    [Parameter(Mandatory = $false)]
    [String]
    $FileShareId
)

Import-Module CimCmdlets

<#
.Synopsis
    Name: Get-FileShares-Internal
    Description: Gets all the local file shares of the machine.

.Parameters
    $FileShareId: The unique identifier of the file share desired (Optional - for cases where only one file share is desired).

.Returns
    The local file share(s).
#>
function Get-FileSharesInternal
{
    param (
        [Parameter(Mandatory = $false)]
        [String]
        $FileShareId
    )

    Remove-Module Storage -ErrorAction Ignore; # Remove the Storage module to prevent it from automatically localizing

    $isDownlevel = [Environment]::OSVersion.Version.Major -lt 10;
    if ($isDownlevel)
    {
        # Map downlevel status to array of [health status, operational status, share state] uplevel equivalent
        $statusMap = @{
            "OK" =         @(0, 2, 1);
            "Error" =      @(2, 6, 2);
            "Degraded" =   @(1, 3, 2);
            "Unknown" =    @(5, 0, 0);
            "Pred Fail" =  @(1, 5, 2);
            "Starting" =   @(1, 8, 0);
            "Stopping" =   @(1, 9, 0);
            "Service" =    @(1, 11, 1);
            "Stressed" =   @(1, 4, 1);
            "NonRecover" = @(2, 7, 2);
            "No Contact" = @(2, 12, 2);
            "Lost Comm" =  @(2, 13, 2);
        };
        
        $shares = Get-CimInstance -ClassName Win32_Share |
            ForEach-Object {
                return @{
                    ContinuouslyAvailable = $false;
                    Description = $_.Description;
                    EncryptData = $false;
                    FileSharingProtocol = 3;
                    HealthStatus = $statusMap[$_.Status][0];
                    IsHidden = $_.Name.EndsWith("`$");
                    Name = $_.Name;
                    OperationalStatus = ,@($statusMap[$_.Status][1]);
                    ShareState = $statusMap[$_.Status][2];
                    UniqueId = "smb|" + (Get-CimInstance Win32_ComputerSystem).DNSHostName + "." + (Get-CimInstance Win32_ComputerSystem).Domain + "\" + $_.Name;
                    VolumePath = $_.Path;
                }
            }
    }
    else
    {        
        $shares = Get-CimInstance -ClassName MSFT_FileShare -Namespace Root\Microsoft\Windows/Storage |
            ForEach-Object {
                return @{
                    IsHidden = $_.Name.EndsWith("`$");
                    VolumePath = $_.VolumeRelativePath;
                    ContinuouslyAvailable = $_.ContinuouslyAvailable;
                    Description = $_.Description;
                    EncryptData = $_.EncryptData;
                    FileSharingProtocol = $_.FileSharingProtocol;
                    HealthStatus = $_.HealthStatus;
                    Name = $_.Name;
                    OperationalStatus = $_.OperationalStatus;
                    UniqueId = $_.UniqueId;
                    ShareState = $_.ShareState;
                }
            }
    }

    if ($FileShareId)
    {
        $shares = $shares | Where-Object { $_.UniqueId -eq $FileShareId };
    }

    return $shares;
}

if ($FileShareId)
{
    Get-FileSharesInternal -FileShareId $FileShareId;
}
else
{
    Get-FileSharesInternal;
}

}
## [END] Get-StorageFileShare ##
function Get-StorageQuota {

<#

.SYNOPSIS
Get all Quotas.

.DESCRIPTION
Get all Quotas.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

#> 
if (Get-Module -ListAvailable -Name FileServerResourceManager) {
    Import-Module FileServerResourceManager
    Get-FsrmQuota
} else {
    $False
}
}
## [END] Get-StorageQuota ##
function Get-StorageResizeDetails {

<#

.SYNOPSIS
Get disk and volume space details required for resizing volume.

.DESCRIPTION
Get disk and volume space details required for resizing volume.

.ROLE
Readers

.PARAMETER driveLetter
The drive letter

#> 
 param (
		[Parameter(Mandatory = $true)]
	    [String]
        $driveLetter
    )
Import-Module Storage

# Get volume details
$volume = get-Volume -DriveLetter $driveLetter

$volumeTotalSize = $volume.Size

# Get partition details by drive letter
$partition = get-Partition -DriveLetter $driveLetter

$partitionNumber =$partition.PartitionNumber
$diskNumber = $partition.DiskNumber

$disk = Get-Disk -Number $diskNumber

$totalSize = $disk.Size

$allocatedSize = $disk.AllocatedSize

# get unallocated space on the disk
$unAllocatedSize = $totalSize - $allocatedSize

$sizes = Get-PartitionSupportedSize -DiskNumber $diskNumber -PartitionNumber $partitionNumber

$resizeDetails=@{
  "volumeTotalSize" = $volumeTotalSize;
  "unallocatedSpaceSize" = $unAllocatedSize;
  "minSize" = $sizes.sizeMin;
  "maxSize" = $sizes.sizeMax;
 }

 return $resizeDetails
}
## [END] Get-StorageResizeDetails ##
function Get-StorageVolume {
<#

.SYNOPSIS
Enumerates all of the local volumes of the system.

.DESCRIPTION
Enumerates all of the local volumes of the system.

.ROLE
Readers

#> 

############################################################################################################################

# Global settings for the script.

############################################################################################################################

$ErrorActionPreference = "Stop"

Set-StrictMode -Version 5.0

Import-Module CimCmdlets
Import-Module Microsoft.PowerShell.Management
Import-Module Microsoft.PowerShell.Utility

############################################################################################################################

# Helper functions.

############################################################################################################################

<# 
.Synopsis
    Name: Get-VolumePathToPartition
    Description: Gets the list of partitions (that have volumes) in hashtable where key is volume path.

.Returns
    The list of partitions (that have volumes) in hashtable where key is volume path.
#>
function Get-VolumePathToPartition
{
    $volumePaths = @{}
    $partitions =  @(Get-CimInstance -ClassName MSFT_Partition -Namespace Root\Microsoft\Windows\Storage)
    foreach($partition in $partitions)
    {
        foreach($volumePath in @($partition.AccessPaths))
        {
            if($volumePath -and (-not $volumePaths.Contains($volumePath)))
            {
                $volumePaths.Add($volumePath, $partition)
            }
        }
    }
    
    $volumePaths
}

<# 
.Synopsis
    Name: Get-DiskIdToDisk
    Description: Gets the list of all the disks in hashtable where key is:
                 "Disk.Path" in case of WS2016 and above.
                 OR
                 "Disk.ObjectId" in case of WS2012 and WS2012R2.

.Returns
    The list of partitions (that have volumes) in hashtable where key is volume path.
#>
function Get-DiskIdToDisk
{    
    $diskIds = @{}

    $isDownlevel = [Environment]::OSVersion.Version.Major -lt 10;

    # In downlevel Operating systems. MSFT_Partition.DiskId is equal to MSFT_Disk.ObjectId
    # However, In WS2016 and above,   MSFT_Partition.DiskId is equal to MSFT_Disk.Path
    $disks = @(Get-CimInstance -ClassName MSFT_Disk -Namespace Root\Microsoft\Windows\Storage)
    foreach ($disk in $disks)
    {
        if($isDownlevel)
        {
            $diskId = $disk.ObjectId
        }
        else
        {
            $diskId = $disk.Path
        }

        if(-not $diskIds.Contains($diskId))
        {
            $diskIds.Add($diskId, $disk)
        }
    }

    return $diskIds
}

<# 
.Synopsis
    Name: Get-VolumeWs2016AndAboveOS
    Description: Gets the list of all applicable volumes from WS2012 and Ws2012R2 Operating Systems.
                 
.Returns
    The list of all applicable volumes
#>
function Get-VolumeDownlevelOS
{
    $volumes = @()
    
    $allVolumes = @(Get-WmiObject -Class MSFT_Volume -Namespace root/Microsoft/Windows/Storage)
    foreach($volume in $allVolumes)
    {
       $partition = $script:partitions.Get_Item($volume.Path)

       # Check if this volume is associated with a partition.
       if($partition)
       {
            # If this volume is associated with a partition, then get the disk to which this partition belongs.
            $disk = $script:disks.Get_Item($partition.DiskId)

            # If the disk is a clustered disk then simply ignore this volume.
            if($disk -and $disk.IsClustered) {continue}
       }
  
       $volumes += $volume
    }
    $allVolumes = $null
    $volumes
}

<# 
.Synopsis
    Name: Get-VolumeWs2016AndAboveOS
    Description: Gets the list of all applicable volumes from WS2016 and above Operating System.
                 
.Returns
    The list of all applicable volumes
#>
function Get-VolumeWs2016AndAboveOS
{
    $volumes = @()
    
    $applicableVolumePaths = @{}

    $subSystem = Get-CimInstance -ClassName MSFT_StorageSubSystem -Namespace root/Microsoft/Windows/Storage| Where-Object { $_.FriendlyName -like "Win*" }
    $allVolumes = @($subSystem | Get-CimAssociatedInstance -ResultClassName MSFT_Volume)
    
    foreach($volume in $allVolumes)
    {
        if(-not $applicableVolumePaths.Contains($volume.Path))
        {
            $applicableVolumePaths.Add($volume.Path, $null)
        }
    }

    $allVolumes = @(Get-WmiObject -Class MSFT_Volume -Namespace root/Microsoft/Windows/Storage)
    foreach($volume in $allVolumes)
    {
        if(-not $applicableVolumePaths.Contains($volume.Path)) { continue }

        $volumes += $volume
    }

    $allVolumes = $null
    $volumes
}

<# 
.Synopsis
    Name: Get-VolumesList
    Description: Gets the list of all applicable volumes w.r.t to the target Operating System.
                 
.Returns
    The list of all applicable volumes.
#>
function Get-VolumesList
{
    $isDownlevel = [Environment]::OSVersion.Version.Major -lt 10;

    if($isDownlevel)
    {
         return Get-VolumeDownlevelOS
    }

    Get-VolumeWs2016AndAboveOS
}

############################################################################################################################

# Helper Variables

############################################################################################################################

 $script:fixedDriveType = 3

 $script:disks = Get-DiskIdToDisk

 $script:partitions = Get-VolumePathToPartition

############################################################################################################################

# Main script.

############################################################################################################################


$resultantVolumes = @()

$volumes = Get-VolumesList

foreach($volume in $volumes)
{
    $partition = $script:partitions.Get_Item($volume.Path)

    if($partition -and $volume.DriveType -eq $script:fixedDriveType)
    {
        $volume | Add-Member -NotePropertyName IsSystem -NotePropertyValue $partition.IsSystem
        $volume | Add-Member -NotePropertyName IsBoot -NotePropertyValue $partition.IsBoot
        $volume | Add-Member -NotePropertyName IsActive -NotePropertyValue $partition.IsActive
        $volume | Add-Member -NotePropertyName PartitionNumber -NotePropertyValue $partition.PartitionNumber
        $volume | Add-Member -NotePropertyName DiskNumber -NotePropertyValue $partition.DiskNumber

    }
    else
    {
        # This volume is not associated with partition, as such it is representing devices like CD-ROM, Floppy drive etc.
        $volume | Add-Member -NotePropertyName IsSystem -NotePropertyValue $true
        $volume | Add-Member -NotePropertyName IsBoot -NotePropertyValue $true
        $volume | Add-Member -NotePropertyName IsActive -NotePropertyValue $true
        $volume | Add-Member -NotePropertyName PartitionNumber -NotePropertyValue -1
        $volume | Add-Member -NotePropertyName DiskNumber -NotePropertyValue -1
    }
       
    $resultantVolumes += $volume
}

 foreach($volume in $resultantVolumes) 
 {
    $sbName = [System.Text.StringBuilder]::new()
 
    # On the downlevel OS, the drive letter is showing charachter. The ASCII code for that char is 0.
    # So rather than checking null or empty, code is checking the ASCII code of the drive letter and updating 
    # the drive letter field to null explicitly to avoid discrepencies on UI.
    if ($volume.FileSystemLabel -and [byte]$volume.DriveLetter -ne 0 ) 
    { 
         $sbName.AppendFormat('{0} ({1}:)', $volume.FileSystemLabel, $volume.DriveLetter)| Out-Null
    } 
    elseif (!$volume.FileSystemLabel -and [byte]$volume.DriveLetter -ne 0 ) 
    { 
          $sbName.AppendFormat('({0}:)', $volume.DriveLetter) | Out-Null
    }
    elseif ($volume.FileSystemLabel -and [byte]$volume.DriveLetter -eq 0)
    {
         $sbName.Append($volume.FileSystemLabel) | Out-Null
    }
    else 
    {
         $sbName.Append('')| Out-Null
    }

    if ([byte]$volume.DriveLetter -eq 0)
    {
        $volume.DriveLetter = $null
    }

    $volume | Add-Member -Force -NotePropertyName "Name" -NotePropertyValue $sbName.ToString()
      
}

$isDownlevel = [Environment]::OSVersion.Version.Major -lt 10;
$resultantVolumes = $resultantVolumes | ForEach-Object {

$volume = @{
        Name = $_.Name;
        DriveLetter = $_.DriveLetter;
        HealthStatus = $_.HealthStatus;
        DriveType = $_.DriveType;
        FileSystem = $_.FileSystem;
        FileSystemLabel = $_.FileSystemLabel;
        Path = $_.Path;
        PartitionNumber = $_.PartitionNumber;
        DiskNumber = $_.DiskNumber;
        Size = $_.Size;
        SizeRemaining = $_.SizeRemaining;
        IsSystem = $_.IsSystem;
        IsBoot = $_.IsBoot;
        IsActive = $_.IsActive;
    }

if ($isDownlevel)
{
    $volume.FileSystemType = $_.FileSystem;
} 
else {

    $volume.FileSystemType = $_.FileSystemType;
    $volume.OperationalStatus = $_.OperationalStatus;
    $volume.HealthStatus = $_.HealthStatus;
    $volume.DriveType = $_.DriveType;
    $volume.DedupMode = $_.DedupMode;
    $volume.UniqueId = $_.UniqueId;
    $volume.AllocationUnitSize = $_.AllocationUnitSize;
  
   }

   return $volume;
}                                    

$resultantVolumes
$volumes = $null
$resultantVolumes = $null

}
## [END] Get-StorageVolume ##
function Initialize-StorageDisk {
<#

.SYNOPSIS
Initializes a disk

.DESCRIPTION
Initializes a disk

.ROLE
Administrators

.PARAMETER diskNumber
The disk number

.PARAMETER partitionStyle
The partition style

#> 
param (
    [Parameter(Mandatory = $true)]
    [String]
    $diskNumber,

    [Parameter(Mandatory = $true)]
    [String]
    $partitionStyle
)

Import-Module Storage

Initialize-Disk -Number $diskNumber -PartitionStyle $partitionStyle
}
## [END] Initialize-StorageDisk ##
function Install-StorageFSRM {

<#

.SYNOPSIS
Install File serve resource manager.

.DESCRIPTION
Install File serve resource manager.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

#> 
Import-Module ServerManager

Install-WindowsFeature -Name FS-Resource-Manager -IncludeManagementTools
}
## [END] Install-StorageFSRM ##
function Mount-StorageVHD {
<#

.SYNOPSIS
Attaches a VHD as disk.

.DESCRIPTION
Attaches a VHD as disk.

.ROLE
Administrators

.PARAMETER path
The VHD path

#> 
param (
    [Parameter(Mandatory = $true)]
    [String]
    $path
)

Import-Module Storage

Mount-DiskImage -ImagePath $path
}
## [END] Mount-StorageVHD ##
function New-StorageQuota {
<#

.SYNOPSIS
Creates a new Quota for volume.

.DESCRIPTION
Creates a new Quota for volume.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER disabledQuota
    Enable or disable quota.

.PARAMETER path
    Path of the quota.

.PARAMETER size
    The size of quota.

.PARAMETER softLimit
    Deny if usage exceeding quota limit.

#>

param
(
    # Enable or disable quota.
    [Boolean]
    $disabledQuota,

    # Path of the quota.
    [String]
    $path,

    # The size of quota.
    [String]
    $size,

    # Deny if usage exceeding quota limit.
    [Boolean]
    $softLimit
)

Import-Module FileServerResourceManager

$scriptArgs = @{
    Path = $path;
}

if ($size) {
    $scriptArgs.Size = $size
}
if ($disabledQuota) {
    $scriptArgs.Disabled = $true
}
if ($softLimit) {
    $scriptArgs.SoftLimit = $true
}

New-FsrmQuota @scriptArgs
}
## [END] New-StorageQuota ##
function New-StorageVHD {
<#

.SYNOPSIS
Creates a new VHD.

.DESCRIPTION
Creates a new VHD.

.ROLE
Administrators

.PARAMETER filePath
The path to the VHD that will be created.

.PARAMETER size
The size of the VHD.

.PARAMETER dynamic
True for a dynamic VHD, false otherwise.

.PARAMETER overwrite
True to overwrite an existing VHD.

#> 
param
(
	# Path to the resultant vhd/vhdx file name.
	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[String]
	$filepath,

    # The size of vhd/vhdx.
    [Parameter(Mandatory = $true)]
    [System.UInt64]
    $size,

    # Whether it is a dynamic vhd/vhdx.
    [Parameter(Mandatory = $true)]
    [Boolean]
    $dynamic,

    # Overwrite if already exists.
    [Boolean]
    $overwrite=$false
)

$NativeCode=@"

    namespace SME
    {
        using Microsoft.Win32.SafeHandles;
        using System;
        using System.ComponentModel;
        using System.IO;
        using System.Runtime.InteropServices;
        using System.Security;

        public static class VirtualDisk
        {
            const uint ERROR_SUCCESS = 0x0;

            const uint DEFAULT_SECTOR_SIZE = 0x200;

            const uint DEFAULT_BLOCK_SIZE = 0x200000;

            private static Guid VirtualStorageTypeVendorUnknown = new Guid("00000000-0000-0000-0000-000000000000");

            private static Guid VirtualStorageTypeVendorMicrosoft = new Guid("EC984AEC-A0F9-47e9-901F-71415A66345B");

            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
            public struct SecurityDescriptor
            {
                public byte revision;
                public byte size;
                public short control;
                public IntPtr owner;
                public IntPtr group;
                public IntPtr sacl;
                public IntPtr dacl;
            }

            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
            public struct CreateVirtualDiskParametersV1
            {
                public CreateVirtualDiskVersion Version;
                public Guid UniqueId;
                public ulong MaximumSize;
                public uint BlockSizeInBytes;
                public uint SectorSizeInBytes;
                public string ParentPath;
                public string SourcePath;
            }

            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
            public struct CreateVirtualDiskParametersV2
            {
                public CreateVirtualDiskVersion Version;
                public Guid UniqueId;
                public ulong MaximumSize;
                public uint BlockSizeInBytes;
                public uint SectorSizeInBytes;
                public uint PhysicalSectorSizeInBytes;
                public string ParentPath;
                public string SourcePath;
                public OpenVirtualDiskFlags OpenFlags;
                public VirtualStorageType ParentVirtualStorageType;
                public VirtualStorageType SourceVirtualStorageType;
                public Guid ResiliencyGuid;
            }

            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
            public struct VirtualStorageType
            {
                public VirtualStorageDeviceType DeviceId;
                public Guid VendorId;
            }

            public enum CreateVirtualDiskVersion : int
            {
                VersionUnspecified = 0x0,
                Version1 = 0x1,
                Version2 = 0x2
            }

            public enum VirtualStorageDeviceType : int
            {
                Unknown = 0x0,
                Iso = 0x1,
                Vhd = 0x2,
                Vhdx = 0x3
            }

            [Flags]
            public enum OpenVirtualDiskFlags
            {
                None = 0x0,
                NoParents = 0x1,
                BlankFile = 0x2,
                BootDrive = 0x4,
            }

            [Flags]
            public enum VirtualDiskAccessMask
            {
                None = 0x00000000,
                AttachReadOnly = 0x00010000,
                AttachReadWrite = 0x00020000,
                Detach = 0x00040000,
                GetInfo = 0x00080000,
                Create = 0x00100000,
                MetaOperations = 0x00200000,
                Read = 0x000D0000,
                All = 0x003F0000,
                Writable = 0x00320000
            }

            [Flags]
            public enum CreateVirtualDiskFlags
            {
                None = 0x0,
                FullPhysicalAllocation = 0x1
            }

            [DllImport("virtdisk.dll", CharSet = CharSet.Unicode, SetLastError = true)]
            public static extern uint CreateVirtualDisk(
                [In, Out] ref VirtualStorageType VirtualStorageType,
                [In]          string Path,
                [In]          VirtualDiskAccessMask VirtualDiskAccessMask,
                [In, Out] ref SecurityDescriptor SecurityDescriptor,
                [In]          CreateVirtualDiskFlags Flags,
                [In]          uint ProviderSpecificFlags,
                [In, Out] ref CreateVirtualDiskParametersV2 Parameters,
                [In]          IntPtr Overlapped,
                [Out]     out SafeFileHandle Handle);

            [DllImport("advapi32", SetLastError = true)]
            public static extern bool InitializeSecurityDescriptor(
                [Out]     out SecurityDescriptor pSecurityDescriptor,
                [In]          uint dwRevision);


            public static void Create(string path, ulong size, bool dynamic, bool overwrite)
            {
                if(string.IsNullOrWhiteSpace(path))
                {
                    throw new ArgumentNullException("path");
                }

                // Validate size.  It needs to be a multiple of 512...  
                if ((size % 512) != 0)
                {
                    throw (
                        new ArgumentOutOfRangeException(
                            "size",
                            size,
                            "The size of the virtual disk must be a multiple of 512."));
                }

                bool isVhd = false;

                VirtualStorageType virtualStorageType = new VirtualStorageType();
                virtualStorageType.VendorId = VirtualStorageTypeVendorMicrosoft;

                if (Path.GetExtension(path) == ".vhdx")
                {
                    virtualStorageType.DeviceId = VirtualStorageDeviceType.Vhdx;
                }
                else if (Path.GetExtension(path) == ".vhd")
                {
                    virtualStorageType.DeviceId = VirtualStorageDeviceType.Vhd;

                    isVhd = true;
                }
                else
                {
                    throw new ArgumentException("The path should have either of the following two extensions: .vhd or .vhdx");
                }

                if ((overwrite) && (System.IO.File.Exists(path)))
                {
                    System.IO.File.Delete(path);
                }

                CreateVirtualDiskParametersV2 createParams = new CreateVirtualDiskParametersV2();
                createParams.Version = CreateVirtualDiskVersion.Version2;
                createParams.UniqueId = Guid.NewGuid();
                createParams.MaximumSize = size;
                createParams.BlockSizeInBytes = 0;
                createParams.SectorSizeInBytes = DEFAULT_SECTOR_SIZE;
                createParams.PhysicalSectorSizeInBytes = 0;
                createParams.ParentPath = null;
                createParams.SourcePath = null;
                createParams.OpenFlags = OpenVirtualDiskFlags.None;
                createParams.ParentVirtualStorageType = new VirtualStorageType();
                createParams.SourceVirtualStorageType = new VirtualStorageType();

                if(isVhd && dynamic)
                {
                    createParams.BlockSizeInBytes = DEFAULT_BLOCK_SIZE;
                }

                CreateVirtualDiskFlags flags;

                if (dynamic)
                {
                    flags = CreateVirtualDiskFlags.None;
                }
                else
                {
                    flags = CreateVirtualDiskFlags.FullPhysicalAllocation;
                }

                SecurityDescriptor securityDescriptor;

                if (!InitializeSecurityDescriptor(out securityDescriptor, 1))
                {
                    throw (
                        new SecurityException(
                            "Unable to initialize the security descriptor for the virtual disk."
                    ));
                }

                SafeFileHandle vhdHandle = null;

                try
                {
                    uint returnCode = CreateVirtualDisk(
                        ref virtualStorageType,
                            path,
                            VirtualDiskAccessMask.None,
                        ref securityDescriptor,
                            flags,
                            0,
                        ref createParams,
                            IntPtr.Zero,
                        out vhdHandle);

                    if (ERROR_SUCCESS != returnCode)
                    {
                        throw (new Win32Exception((int)returnCode));
                    }
                }
                finally
                {
                    if (vhdHandle != null && !vhdHandle.IsClosed)
                    {
                        vhdHandle.Close();
                        vhdHandle.SetHandleAsInvalid();
                    }
                }
            }
        }
    }
"@

############################################################################################################################

# Global settings for the script.

############################################################################################################################

$ErrorActionPreference = "Stop"

Set-StrictMode -Version 3.0

Import-Module -Name Storage -Force -Global -WarningAction SilentlyContinue
Import-Module Microsoft.PowerShell.Utility

############################################################################################################################

# Main script.

############################################################################################################################

Add-Type -TypeDefinition $NativeCode
Remove-Variable NativeCode

# Resolve $abc and ..\ from the File path.
$filepath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ExecutionContext.InvokeCommand.ExpandString($filepath))

# Create the virtual disk drive.
try
{
    [SME.VirtualDisk]::Create($filepath, $size, $dynamic, $overwrite)
}
catch
{
    if($_.Exception.InnerException)
    {
        throw $_.Exception.InnerException
    }
    elseif($_.Exception)
    {
        throw $_.Exception
    }
    else
    {
        throw $_
    }
}

# Mount the virtual disk drive.
Mount-DiskImage -ImagePath $filepath 


}
## [END] New-StorageVHD ##
function New-StorageVolume {
<#

.SYNOPSIS
Creates a volume.

.DESCRIPTION
Creates a volume.

.ROLE
Administrators

.PARAMETER diskNumber
The disk number.

.PARAMETER driveLetter
The drive letter.

.PARAMETER sizeInBytes
The size in bytes.

.PARAMETER fileSystem
The file system.

.PARAMETER allocationUnitSizeInBytes
The allocation unit size.

.PARAMETER fileSystemLabel
The file system label.

.PARAMETER useMaxSize
True to use the maximum size.

#>
param (
    [parameter(Mandatory=$true)]
    [String]
    $diskNumber,
    [parameter(Mandatory=$true)]
    [Char]
    $driveLetter,
    [uint64]
    $sizeInBytes,
    [parameter(Mandatory=$true)]
    [string]
    $fileSystem,
    [parameter(Mandatory=$true)]
    [uint32]
    $allocationUnitSizeInBytes,
    [string]
    $fileSystemLabel,
    [boolean]
    $useMaxSize = $false
)

Import-Module Microsoft.PowerShell.Management
Import-Module Microsoft.PowerShell.Utility
Import-Module Storage

# This is a work around for getting rid of format dialog on the machine when format fails for reasons. Get rid of this code once we make changes on the UI to identify correct combinations.
$service = Get-WmiObject -Class Win32_Service -Filter "Name='ShellHWDetection'" -ErrorAction SilentlyContinue | out-null
if($service)
{
    $service.StopService();
}


if ($useMaxSize)
{
    $p = New-Partition -DiskNumber $diskNumber -DriveLetter $driveLetter -UseMaximumSize
}
else
{
    $p = New-Partition -DiskNumber $diskNumber -DriveLetter $driveLetter -Size $sizeInBytes
}

# Format only when partition is created
if ($p)
{
    try {
      Format-Volume -DriveLetter $driveLetter -FileSystem $fileSystem -NewFileSystemLabel "$fileSystemLabel" -AllocationUnitSize $allocationUnitSizeInBytes -confirm:$false
    } catch {
      Remove-Partition -DriveLetter $driveLetter -Confirm:$false
      throw
    }
}

if($service)
{
    $service.StartService();
}

$volume = Get-Volume -DriveLetter $driveLetter
if ($volume) {

  if ($volume.FileSystemLabel) {
      $volumeName = $volume.FileSystemLabel + " (" + $volume.DriveLetter + ":)"
  } else {
      $volumeName = "(" + $volume.DriveLetter + ":)"
  }

  return @{
      Name = $volumeName;
      HealthStatus = $volume.HealthStatus;
      DriveType = $volume.DriveType;
      DriveLetter = $volume.DriveLetter;
      FileSystem = $volume.FileSystem;
      FileSystemLabel = $volume.FileSystemLabel;
      Path = $volume.Path;
      Size = $volume.Size;
      SizeRemaining = $volume.SizeRemaining;
      }
}

}
## [END] New-StorageVolume ##
function Remove-StorageQuota {
<#

.SYNOPSIS
Remove Quota with the path.

.DESCRIPTION
Remove Quota with the path.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER path
    Path of the quota.
#> 
param
(
	# Path of the quota.
	[String]
	$path
)
Import-Module FileServerResourceManager

Remove-FsrmQuota -Path $path -Confirm:$false
}
## [END] Remove-StorageQuota ##
function Remove-StorageVolume {
<#

.SYNOPSIS
Remove a volume.

.DESCRIPTION
Remove a volume.

.ROLE
Administrators

.PARAMETER driveLetter
    The drive letter.
#> 
param (
    [Parameter(Mandatory = $true)]
    [String]
    $driveLetter
)
Import-Module Storage

Remove-Partition -DriveLetter $driveLetter -Confirm:$false


}
## [END] Remove-StorageVolume ##
function Resize-StorageVolume {
<#

.SYNOPSIS
Resizes the volume.

.DESCRIPTION
Resizes the volume.

.ROLE
Administrators

.PARAMETER driveLetter
	The drive letter.

.PARAMETER newSize
	The new size.
#> 
param (
	[Parameter(Mandatory = $true)]
	[String]
	$driveLetter,

	[UInt64]
	$newSize

)

Import-Module Storage

Resize-Partition -DriveLetter $driveLetter -Size $newSize
}
## [END] Resize-StorageVolume ##
function Set-StorageDiskOffline {
<#

.SYNOPSIS
Sets the disk offline.

.DESCRIPTION
Sets the disk offline.

.ROLE
Administrators

.PARAMETER diskNumber
	The disk number.

.PARAMETER isOffline
	True to set the disk offline.
#> 
param (
    [UInt32]
    $diskNumber,
    [Boolean]
    $isOffline = $true
)

Import-Module Storage

Set-Disk -Number $diskNumber -IsOffline $isOffline
}
## [END] Set-StorageDiskOffline ##
function Update-StorageQuota {
 <#

.SYNOPSIS
Update a new Quota for volume.

.DESCRIPTION
Update a new Quota for volume.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER disabledQuota
    Enable or disable quota.

.PARAMETER path
    Path of the quota.

.PARAMETER size
    The size of quota.

.PARAMETER softLimit
    Deny if usage exceeding quota limit.

#>

param
(
    # Enable or disable quota.
    [Parameter(Mandatory = $true)]
    [Boolean]
    $disabledQuota,

	# Path of the quota.
    [Parameter(Mandatory = $true)]
	[String]
	$path,

    # The size of quota.
    [Parameter(Mandatory = $true)]
    [String]
    $size,

    # Deny if usage exceeding quota limit.
    [Parameter(Mandatory = $true)]
    [Boolean]
    $softLimit
)
Import-Module FileServerResourceManager

$scriptArguments = @{
    Path = $path
    Disabled = $disabledQuota
    SoftLimit = $softLimit
}

if ($size) {
    $scriptArguments.Size = $size
}

Set-FsrmQuota @scriptArguments

}
## [END] Update-StorageQuota ##
function Add-FolderShare {
<#

.SYNOPSIS
Gets a new share name for the folder.

.DESCRIPTION
Gets a new share name for the folder. It starts with the folder name. Then it keeps appending "2" to the name
until the name is free. Finally return the name.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Path
    String -- The path to the folder to be shared.

.PARAMETER Name
    String -- The suggested name to be shared (the folder name).

.PARAMETER Force
    boolean -- override any confirmations

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path,    

    [Parameter(Mandatory = $true)]
    [String]
    $Name
)

Set-StrictMode -Version 5.0

while([bool](Get-SMBShare -Name $Name -ea 0)){
    $Name = $Name + '2';
}

New-SmbShare -Name "$Name" -Path "$Path"
@{ shareName = $Name }

}
## [END] Add-FolderShare ##
function Add-FolderShareNameUser {
<#

.SYNOPSIS
Adds a user to the folder share.

.DESCRIPTION
Adds a user to the folder share.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Name
    String -- Name of the share.

.PARAMETER AccountName
    String -- The user identification (AD / Local user).

.PARAMETER AccessRight
    String -- Access rights of the user.

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Name,

    [Parameter(Mandatory = $true)]
    [String]
    $AccountName,

    [Parameter(Mandatory = $true)]
    [String]
    $AccessRight
)

Set-StrictMode -Version 5.0

Grant-SmbShareAccess -Name "$Name" -AccountName "$AccountName" -AccessRight "$AccessRight" -Force


}
## [END] Add-FolderShareNameUser ##
function Add-FolderShareUser {
<#

.SYNOPSIS
Adds a user access to the folder.

.DESCRIPTION
Adds a user access to the folder.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Path
    String -- The path to the folder.

.PARAMETER Identity
    String -- The user identification (AD / Local user).

.PARAMETER FileSystemRights
    String -- File system rights of the user.

.PARAMETER AccessControlType
    String -- Access control type of the user.    

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path,

    [Parameter(Mandatory = $true)]
    [String]
    $Identity,

    [Parameter(Mandatory = $true)]
    [String]
    $FileSystemRights,

    [ValidateSet('Deny','Allow')]
    [Parameter(Mandatory = $true)]
    [String]
    $AccessControlType
)

Set-StrictMode -Version 5.0

function Remove-UserPermission
{
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Path,
    
        [Parameter(Mandatory = $true)]
        [String]
        $Identity,
        
        [ValidateSet('Deny','Allow')]
        [Parameter(Mandatory = $true)]
        [String]
        $ACT
    )

    $Acl = Get-Acl $Path
    $AccessRule = New-Object system.security.accesscontrol.filesystemaccessrule($Identity, 'ReadAndExecute','ContainerInherit, ObjectInherit', 'None', $ACT)
    $Acl.RemoveAccessRuleAll($AccessRule)
    Set-Acl $Path $Acl
}

If ($AccessControlType -eq 'Deny') {
    $FileSystemRights = 'FullControl'
    Remove-UserPermission $Path $Identity 'Allow'
} else {
    Remove-UserPermission $Path $Identity 'Deny'
}

$Acl = Get-Acl $Path
$AccessRule = New-Object system.security.accesscontrol.filesystemaccessrule($Identity, $FileSystemRights,'ContainerInherit, ObjectInherit', 'None', $AccessControlType)
$Acl.AddAccessRule($AccessRule)
Set-Acl $Path $Acl

}
## [END] Add-FolderShareUser ##
function Compress-ArchiveFileSystemEntity {
<#

.SYNOPSIS
Compresses the specified file system entity (files, folders) of the system.

.DESCRIPTION
Compresses the specified file system entity (files, folders) of the system on this server.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER pathSource
    String -- The path to compress.

.PARAMETER PathDestination
    String -- The destination path to compress into.

.PARAMETER Force
    boolean -- override any confirmations

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $PathSource,    

    [Parameter(Mandatory = $true)]
    [String]
    $PathDestination,

    [Parameter(Mandatory = $false)]
    [boolean]
    $Force
)

Set-StrictMode -Version 5.0

if ($Force) {
    Compress-Archive -Path $PathSource -Force -DestinationPath $PathDestination
} else {
    Compress-Archive -Path $PathSource -DestinationPath $PathDestination
}
if ($error) {
    $code = $error[0].Exception.HResult
    @{ status = "error"; code = $code; message = $error }
} else {
    @{ status = "ok"; }
}

}
## [END] Compress-ArchiveFileSystemEntity ##
function Edit-FolderShareInheritanceFlag {
<#

.SYNOPSIS
Modifies all users' IsInherited flag to false

.DESCRIPTION
Modifies all users' IsInherited flag to false
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Path
    String -- The path to the folder.

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path
)

Set-StrictMode -Version 5.0

$Acl = Get-Acl $Path
$Acl.SetAccessRuleProtection($True, $True)
Set-Acl -Path $Path -AclObject $Acl

}
## [END] Edit-FolderShareInheritanceFlag ##
function Edit-FolderShareUser {
<#

.SYNOPSIS
Edits a user access to the folder.

.DESCRIPTION
Edits a user access to the folder.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Path
    String -- The path to the folder.

.PARAMETER Identity
    String -- The user identification (AD / Local user).

.PARAMETER FileSystemRights
    String -- File system rights of the user.

.PARAMETER AccessControlType
    String -- Access control type of the user.    

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path,

    [Parameter(Mandatory = $true)]
    [String]
    $Identity,

    [Parameter(Mandatory = $true)]
    [String]
    $FileSystemRights,

    [ValidateSet('Deny','Allow')]
    [Parameter(Mandatory = $true)]
    [String]
    $AccessControlType
)

Set-StrictMode -Version 5.0

function Remove-UserPermission
{
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Path,
    
        [Parameter(Mandatory = $true)]
        [String]
        $Identity,
        
        [ValidateSet('Deny','Allow')]
        [Parameter(Mandatory = $true)]
        [String]
        $ACT
    )

    $Acl = Get-Acl $Path
    $AccessRule = New-Object system.security.accesscontrol.filesystemaccessrule($Identity, 'ReadAndExecute','ContainerInherit, ObjectInherit', 'None', $ACT)
    $Acl.RemoveAccessRuleAll($AccessRule)
    Set-Acl $Path $Acl
}

If ($AccessControlType -eq 'Deny') {
    $FileSystemRights = 'FullControl'
    Remove-UserPermission $Path $Identity 'Allow'
} else {
    Remove-UserPermission $Path $Identity 'Deny'
}

$Acl = Get-Acl $Path
$AccessRule = New-Object system.security.accesscontrol.filesystemaccessrule($Identity, $FileSystemRights,'ContainerInherit, ObjectInherit', 'None', $AccessControlType)
$Acl.SetAccessRule($AccessRule)
Set-Acl $Path $Acl




}
## [END] Edit-FolderShareUser ##
function Expand-ArchiveFileSystemEntity {
<#

.SYNOPSIS
Expands the specified file system entity (files, folders) of the system.

.DESCRIPTION
Expands the specified file system entity (files, folders) of the system on this server.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER pathSource
    String -- The path to expand.

.PARAMETER PathDestination
    String -- The destination path to expand into.

.PARAMETER Force
    boolean -- override any confirmations

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $PathSource,    

    [Parameter(Mandatory = $true)]
    [String]
    $PathDestination,

    [Parameter(Mandatory = $false)]
    [boolean]
    $Force
)

Set-StrictMode -Version 5.0

if ($Force) {
    Expand-Archive -Path $PathSource -Force -DestinationPath $PathDestination
} else {
    Expand-Archive -Path $PathSource -DestinationPath $PathDestination
}

if ($error) {
    $code = $error[0].Exception.HResult
    @{ status = "error"; code = $code; message = $error }
} else {
    @{ status = "ok"; }
}

}
## [END] Expand-ArchiveFileSystemEntity ##
function Get-BestHostNode {
<#

.SYNOPSIS
Returns the list of available cluster node names, and the best node name to host a new virtual machine.

.DESCRIPTION
Use the cluster CIM provider (MSCluster) to ask the cluster which node is the best to host a new virtual machine.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0
Import-Module CimCmdlets -ErrorAction SilentlyContinue
Import-Module FailoverClusters -ErrorAction SilentlyContinue

Import-LocalizedData -BindingVariable strings -FileName strings.psd1 -ErrorAction SilentlyContinue

###############################################################################
# Constants
###############################################################################

Set-Variable -Name LogName -Option Constant -Value "Microsoft-ServerManagementExperience" -ErrorAction SilentlyContinue
Set-Variable -Name LogSource -Option Constant -Value "SMEScripts" -ErrorAction SilentlyContinue
Set-Variable -Name clusterCimNameSpace -Option Constant -Value "root/MSCluster" -ErrorAction SilentlyContinue
Set-Variable -Name ScriptName -Option Constant -Value "Get-BestHostNode" -ErrorAction SilentlyContinue
Set-Variable -Name BestNodePropertyName -Option Constant -Value "BestNode" -ErrorAction SilentlyContinue
Set-Variable -Name StateUp -Option Constant -Value "0" -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Get the fully qualified domain name for the passed in server name from DNS.

.DESCRIPTION
Get the fully qualified domain name for the passed in server name from DNS.

#>

function GetServerFqdn([string]$netBIOSName) {
    return ([System.Net.DNS]::GetHostByName($netBIOSName).HostName)
}

<#

.SYNOPSIS
Are the cluster PowerShell cmdlets installed on this server?

.DESCRIPTION
Are the cluster PowerShell cmdlets installed on this server?

#>

function getIsClusterCmdletsAvailable() {
    $cmdlet = Get-Command "Get-Cluster" -ErrorAction SilentlyContinue

    return !!$cmdlet
}

<#

.SYNOPSIS
is the cluster CIM (WMI) provider installed on this server?

.DESCRIPTION
Returns true when the cluster CIM provider is installed on this server.

#>

function isClusterCimProviderAvailable() {
    $namespace = Get-CimInstance -Namespace $clusterCimNamespace -ClassName __NAMESPACE -ErrorAction SilentlyContinue

    return !!$namespace
}

<#

.SYNOPSIS
Get the MSCluster Cluster Service CIM instance from this server.

.DESCRIPTION
Get the MSCluster Cluster Service CIM instance from this server.

#>

function getClusterServiceCimInstance() {
    return Get-CimInstance -Namespace $clusterCimNamespace MSCluster_ClusterService -ErrorAction SilentlyContinue
}

<#

.SYNOPSIS
Get the list of the cluster nodes that are running.

.DESCRIPTION
Returns a list of cluster node names that are running using PowerShell.

#>

function getAllUpClusterNodeNames() {
    # Constants
    Set-Variable stateUp -Option Constant -Value "up"

    return Get-ClusterNode | Where-Object { $_.State -eq $stateUp } | ForEach-Object { (GetServerFqdn($_.Name)) }
}

<#

.SYNOPSIS
Get the list of the cluster nodes that are running.

.DESCRIPTION
Returns a list of cluster node names that are running using CIM.

#>

function getAllUpClusterCimNodeNames() {
##SkipCheck=true##
    $query = "select name, state from MSCluster_Node Where state = '{0}'" -f $StateUp
##SkipCheck=false##
    return Get-CimInstance -Namespace $clusterCimNamespace -Query $query | ForEach-Object { (GetServerFqdn($_.Name)) }
}

<#

.SYNOPSIS
Create a new instance of the "results" PS object.

.DESCRIPTION
Create a new PS object and set the passed in nodeNames to the appropriate property.

#>

function newResult([string []] $nodeNames) {
    $result = new-object PSObject
    $result | Add-Member -Type NoteProperty -Name Nodes -Value $nodeNames

    return $result;
}

<#

.SYNOPSIS
Remove any old lingering reservation for our typical VM.

.DESCRIPTION
Remove the reservation from the passed in id.

#>

function removeReservation($clusterService, [string] $rsvId) {
    Set-Variable removeReservationMethodName -Option Constant -Value "RemoveVmReservation"

    Invoke-CimMethod -CimInstance $clusterService -MethodName $removeReservationMethodName -Arguments @{ReservationId = $rsvId} -ErrorVariable +err | Out-Null
}

<#

.SYNOPSIS
Create a reservation for our typical VM.

.DESCRIPTION
Create a reservation for the passed in id.

#>

function createReservation($clusterService, [string] $rsvId) {
    Set-Variable createReservationMethodName -Option Constant -Value "CreateVmReservation"
    Set-Variable ReserveSettings -Option Constant -Value @{VmMemory = 2048; VmVirtualCoreCount = 2; VmCpuReservation = 0; VmFlags = 0; TimeSpan = 2000; ReservationId = $rsvId; LocalDiskSize = 0; Version = 0}

    $vmReserve = Invoke-CimMethod -CimInstance $clusterService -MethodName $createReservationMethodName -ErrorVariable va -Arguments $ReserveSettings

    return $vmReserve
}

<#

.SYNOPSIS
Use the Cluster CIM provider to find the best host name for a typical VM.

.DESCRIPTION
Returns the best host node name, or null when none are found.

#>

function askClusterServiceForBestHostNode() {
    # API parameters
    Set-Variable rsvId -Option Constant -Value "TempVmId1"

    # If the class exist, using api to get optimal host
    $clusterService = getClusterServiceCimInstance
    if (!!$clusterService) {
        $nodeNames = @(getAllUpClusterCimNodeNames)
        $result = newResult $nodeNames

        # remove old reserveration if there is any
        removeReservation $clusterService $rsvId

        $vmReserve = createReservation $clusterService $rsvId
        $id = $vmReserve.NodeId

        if ($id) {
##SkipCheck=true##
            $query = "select name, id from MSCluster_Node where id = '{0}'" -f $id
##SkipCheck=false##
            $bestNode = Get-CimInstance -Namespace $clusterCimNamespace -Query $query -ErrorAction SilentlyContinue

            if ($bestNode) {
                $result | Add-Member -Type NoteProperty -Name $BestNodePropertyName -Value (GetServerFqdn($bestNode.Name))

                return $result
            }
        }
    }

    return $null
}

<#

.SYNOPSIS
Get the name of the cluster node that has the least number of VMs running on it.

.DESCRIPTION
Return the name of the cluster node that has the least number of VMs running on it.

#>

function getLeastLoadedNode() {
    # Constants
    Set-Variable vmResourceTypeName -Option Constant -Value "Virtual Machine"
    Set-Variable OwnerNodePropertyName -Option Constant -Value "OwnerNode"

    $nodeNames = @(getAllUpClusterNodeNames)
    $bestNodeName = $null;

    $result = newResult $nodeNames

    $virtualMachinesPerNode = @{}

    # initial counts as 0
    $nodeNames | ForEach-Object { $virtualMachinesPerNode[$_] = 0 }

    $ownerNodes = Get-ClusterResource | Where-Object { $_.ResourceType -eq $vmResourceTypeName } | Microsoft.PowerShell.Utility\Select-Object $OwnerNodePropertyName
    $ownerNodes | ForEach-Object { $virtualMachinesPerNode[$_.OwnerNode.Name]++ }

    # find node with minimum count
    $bestNodeName = $nodeNames[0]
    $min = $virtualMachinesPerNode[$bestNodeName]

    $nodeNames | ForEach-Object {
        if ($virtualMachinesPerNode[$_] -lt $min) {
            $bestNodeName = $_
            $min = $virtualMachinesPerNode[$_]
        }
    }

    $result | Add-Member -Type NoteProperty -Name $BestNodePropertyName -Value (GetServerFqdn($bestNodeName))

    return $result
}

<#

.SYNOPSIS
Main

.DESCRIPTION
Use the various mechanism available to determine the best host node.

#>

function main() {
    if (isClusterCimProviderAvailable) {
        $bestNode = askClusterServiceForBestHostNode
        if (!!$bestNode) {
            return $bestNode
        }
    }

    if (getIsClusterCmdletsAvailable) {
        return getLeastLoadedNode
    } else {
        Microsoft.PowerShell.Management\New-EventLog -LogName $LogName -Source $LogSource -ErrorAction SilentlyContinue
        Microsoft.PowerShell.Management\Write-EventLog -LogName $LogName -Source $LogSource -EventId 0 -Category 0 -EntryType Warning `
            -Message "[$ScriptName]: The required PowerShell module (FailoverClusters) was not found."  -ErrorAction SilentlyContinue
        Write-Warning $strings.FailoverClustersModuleRequired
    }

    return $null
}

###############################################################################
# Script execution begins here.
###############################################################################

if (-not ($env:pester)) {
    $result = main
    if (!!$result) {
        return $result
    }

    # If neither cluster CIM provider or PowerShell cmdlets are available then simply
    # return this computer's name as the best host node...
    $nodeName = GetServerFqdn($env:COMPUTERNAME)

    $result = newResult @($nodeName)
    $result | Add-Member -Type NoteProperty -Name $BestNodePropertyName -Value $nodeName

    return $result
}

}
## [END] Get-BestHostNode ##
function Get-CimWin32LogicalDisk {
<#

.SYNOPSIS
Gets Win32_LogicalDisk object.

.DESCRIPTION
Gets Win32_LogicalDisk object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_LogicalDisk

}
## [END] Get-CimWin32LogicalDisk ##
function Get-CimWin32NetworkAdapter {
<#

.SYNOPSIS
Gets Win32_NetworkAdapter object.

.DESCRIPTION
Gets Win32_NetworkAdapter object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_NetworkAdapter

}
## [END] Get-CimWin32NetworkAdapter ##
function Get-CimWin32PhysicalMemory {
<#

.SYNOPSIS
Gets Win32_PhysicalMemory object.

.DESCRIPTION
Gets Win32_PhysicalMemory object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_PhysicalMemory

}
## [END] Get-CimWin32PhysicalMemory ##
function Get-CimWin32Processor {
<#

.SYNOPSIS
Gets Win32_Processor object.

.DESCRIPTION
Gets Win32_Processor object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_Processor

}
## [END] Get-CimWin32Processor ##
function Get-ClusterInventory {
<#

.SYNOPSIS
Retrieves the inventory data for a cluster.

.DESCRIPTION
Retrieves the inventory data for a cluster.

.ROLE
Readers

#>

import-module CimCmdlets -ErrorAction SilentlyContinue

# JEA code requires to pre-import the module (this is slow on failover cluster environment.)
import-module FailoverClusters -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Get the name of this computer.

.DESCRIPTION
Get the best available name for this computer.  The FQDN is preferred, but when not avaialble
the NetBIOS name will be used instead.

#>

function getComputerName() {
    $computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object Name, DNSHostName

    if ($computerSystem) {
        $computerName = $computerSystem.DNSHostName

        if ($null -eq $computerName) {
            $computerName = $computerSystem.Name
        }

        return $computerName
    }

    return $null
}

<#

.SYNOPSIS
Are the cluster PowerShell cmdlets installed on this server?

.DESCRIPTION
Are the cluster PowerShell cmdlets installed on this server?

#>

function getIsClusterCmdletAvailable() {
    $cmdlet = Get-Command "Get-Cluster" -ErrorAction SilentlyContinue

    return !!$cmdlet
}

<#

.SYNOPSIS
Get the MSCluster Cluster CIM instance from this server.

.DESCRIPTION
Get the MSCluster Cluster CIM instance from this server.

#>
function getClusterCimInstance() {
    $namespace = Get-CimInstance -Namespace root/MSCluster -ClassName __NAMESPACE -ErrorAction SilentlyContinue

    if ($namespace) {
        return Get-CimInstance -Namespace root/mscluster MSCluster_Cluster -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object fqdn, S2DEnabled
    }

    return $null
}


<#

.SYNOPSIS
Determines if the current cluster supports Failover Clusters Time Series Database.

.DESCRIPTION
Use the existance of the path value of cmdlet Get-StorageHealthSetting to determine if TSDB 
is supported or not.

#>
function getClusterPerformanceHistoryPath() {
    return $null -ne (Get-StorageSubSystem clus* | Get-StorageHealthSetting -Name "System.PerformanceHistory.Path")
}

<#

.SYNOPSIS
Get some basic information about the cluster from the cluster.

.DESCRIPTION
Get the needed cluster properties from the cluster.

#>
function getClusterInfo() {
    $returnValues = @{}

    $returnValues.Fqdn = $null
    $returnValues.isS2DEnabled = $false
    $returnValues.isTsdbEnabled = $false

    $cluster = getClusterCimInstance
    if ($cluster) {
        $returnValues.Fqdn = $cluster.fqdn
        $isS2dEnabled = !!(Get-Member -InputObject $cluster -Name "S2DEnabled") -and ($cluster.S2DEnabled -eq 1)
        $returnValues.isS2DEnabled = $isS2dEnabled

        if ($isS2DEnabled) {
            $returnValues.isTsdbEnabled = getClusterPerformanceHistoryPath
        } else {
            $returnValues.isTsdbEnabled = $false
        }
    }

    return $returnValues
}

<#

.SYNOPSIS
Are the cluster PowerShell Health cmdlets installed on this server?

.DESCRIPTION
Are the cluster PowerShell Health cmdlets installed on this server?

s#>
function getisClusterHealthCmdletAvailable() {
    $cmdlet = Get-Command -Name "Get-HealthFault" -ErrorAction SilentlyContinue

    return !!$cmdlet
}
<#

.SYNOPSIS
Are the Britannica (sddc management resources) available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) available on the cluster?

#>
function getIsBritannicaEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_Cluster -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Are the Britannica (sddc management resources) virtual machine available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) virtual machine available on the cluster?

#>
function getIsBritannicaVirtualMachineEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_VirtualMachine -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Are the Britannica (sddc management resources) virtual switch available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) virtual switch available on the cluster?

#>
function getIsBritannicaVirtualSwitchEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_VirtualSwitch -ErrorAction SilentlyContinue)
}

###########################################################################
# main()
###########################################################################

$clusterInfo = getClusterInfo

$result = New-Object PSObject

$result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $clusterInfo.Fqdn
$result | Add-Member -MemberType NoteProperty -Name 'IsS2DEnabled' -Value $clusterInfo.isS2DEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsTsdbEnabled' -Value $clusterInfo.isTsdbEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsClusterHealthCmdletAvailable' -Value (getIsClusterHealthCmdletAvailable)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaEnabled' -Value (getIsBritannicaEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaVirtualMachineEnabled' -Value (getIsBritannicaVirtualMachineEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaVirtualSwitchEnabled' -Value (getIsBritannicaVirtualSwitchEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsClusterCmdletAvailable' -Value (getIsClusterCmdletAvailable)
$result | Add-Member -MemberType NoteProperty -Name 'CurrentClusterNode' -Value (getComputerName)

$result

}
## [END] Get-ClusterInventory ##
function Get-ClusterNodes {
<#

.SYNOPSIS
Retrieves the inventory data for cluster nodes in a particular cluster.

.DESCRIPTION
Retrieves the inventory data for cluster nodes in a particular cluster.

.ROLE
Readers

#>

import-module CimCmdlets

# JEA code requires to pre-import the module (this is slow on failover cluster environment.)
import-module FailoverClusters -ErrorAction SilentlyContinue

###############################################################################
# Constants
###############################################################################

Set-Variable -Name LogName -Option Constant -Value "Microsoft-ServerManagementExperience" -ErrorAction SilentlyContinue
Set-Variable -Name LogSource -Option Constant -Value "SMEScripts" -ErrorAction SilentlyContinue
Set-Variable -Name ScriptName -Option Constant -Value $MyInvocation.ScriptName -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Are the cluster PowerShell cmdlets installed?

.DESCRIPTION
Use the Get-Command cmdlet to quickly test if the cluster PowerShell cmdlets
are installed on this server.

#>

function getClusterPowerShellSupport() {
    $cmdletInfo = Get-Command 'Get-ClusterNode' -ErrorAction SilentlyContinue

    return $cmdletInfo -and $cmdletInfo.Name -eq "Get-ClusterNode"
}

<#

.SYNOPSIS
Get the cluster nodes using the cluster CIM provider.

.DESCRIPTION
When the cluster PowerShell cmdlets are not available fallback to using
the cluster CIM provider to get the needed information.

#>

function getClusterNodeCimInstances() {
    # Change the WMI property NodeDrainStatus to DrainStatus to match the PS cmdlet output.
    return Get-CimInstance -Namespace root/mscluster MSCluster_Node -ErrorAction SilentlyContinue | `
        Microsoft.PowerShell.Utility\Select-Object @{Name="DrainStatus"; Expression={$_.NodeDrainStatus}}, DynamicWeight, Name, NodeWeight, FaultDomain, State
}

<#

.SYNOPSIS
Get the cluster nodes using the cluster PowerShell cmdlets.

.DESCRIPTION
When the cluster PowerShell cmdlets are available use this preferred function.

#>

function getClusterNodePsInstances() {
    return Get-ClusterNode -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object DrainStatus, DynamicWeight, Name, NodeWeight, FaultDomain, State
}

<#

.SYNOPSIS
Use DNS services to get the FQDN of the cluster NetBIOS name.

.DESCRIPTION
Use DNS services to get the FQDN of the cluster NetBIOS name.

.Notes
It is encouraged that the caller add their approprate -ErrorAction when
calling this function.

#>

function getClusterNodeFqdn([string]$clusterNodeName) {
    return ([System.Net.Dns]::GetHostEntry($clusterNodeName)).HostName
}

<#

.SYNOPSIS
Writes message to event log as warning.

.DESCRIPTION
Writes message to event log as warning.

#>

function writeToEventLog([string]$message) {
    Microsoft.PowerShell.Management\New-EventLog -LogName $LogName -Source $LogSource -ErrorAction SilentlyContinue
    Microsoft.PowerShell.Management\Write-EventLog -LogName $LogName -Source $LogSource -EventId 0 -Category 0 -EntryType Warning `
        -Message $message  -ErrorAction SilentlyContinue
}

<#

.SYNOPSIS
Get the cluster nodes.

.DESCRIPTION
When the cluster PowerShell cmdlets are available get the information about the cluster nodes
using PowerShell.  When the cmdlets are not available use the Cluster CIM provider.

#>

function getClusterNodes() {
    $isClusterCmdletAvailable = getClusterPowerShellSupport

    if ($isClusterCmdletAvailable) {
        $clusterNodes = getClusterNodePsInstances
    } else {
        $clusterNodes = getClusterNodeCimInstances
    }

    $clusterNodeMap = @{}

    foreach ($clusterNode in $clusterNodes) {
        $clusterNodeName = $clusterNode.Name.ToLower()
        try 
        {
            $clusterNodeFqdn = getClusterNodeFqdn $clusterNodeName -ErrorAction SilentlyContinue
        }
        catch 
        {
            $clusterNodeFqdn = $clusterNodeName
            writeToEventLog "[$ScriptName]: The fqdn for node '$clusterNodeName' could not be obtained. Defaulting to machine name '$clusterNodeName'"
        }

        $clusterNodeResult = New-Object PSObject

        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'FullyQualifiedDomainName' -Value $clusterNodeFqdn
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'Name' -Value $clusterNodeName
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'DynamicWeight' -Value $clusterNode.DynamicWeight
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'NodeWeight' -Value $clusterNode.NodeWeight
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'FaultDomain' -Value $clusterNode.FaultDomain
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'State' -Value $clusterNode.State
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'DrainStatus' -Value $clusterNode.DrainStatus

        $clusterNodeMap.Add($clusterNodeName, $clusterNodeResult)
    }

    return $clusterNodeMap
}

###########################################################################
# main()
###########################################################################

getClusterNodes

}
## [END] Get-ClusterNodes ##
function Get-ComputerName {
<#

.SYNOPSIS
Gets the computer name.

.DESCRIPTION
Gets the compuiter name.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

#>

Set-StrictMode -Version 5.0

$ComputerName = $env:COMPUTERNAME
@{ computerName = $ComputerName }

}
## [END] Get-ComputerName ##
function Get-FileNamesInPath {
<#

.SYNOPSIS
Enumerates all of the file system entities (files, folders, volumes) of the system.

.DESCRIPTION
Enumerates all of the file system entities (files, folders, volumes) of the system on this server.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

.PARAMETER Path
    String -- The path to enumerate.

.PARAMETER OnlyFolders
    switch -- 

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path,

    [Parameter(Mandatory = $false)]
    [switch]
    $OnlyFolders
)

Set-StrictMode -Version 5.0

function isFolder($item) {
    return $item.Attributes -match "Directory"
}

function getName($item) {
    $slash = '';

    if (isFolder $item) {
        $slash = '\';
    }

    return "$($_.Name)$slash"
}

if ($onlyFolders) {
    return (Get-ChildItem -Path $Path | Where-Object {isFolder $_}) | ForEach-Object { return "$($_.Name)\"} | Sort-Object
}

return (Get-ChildItem -Path $Path) | ForEach-Object { return getName($_)} | Sort-Object

}
## [END] Get-FileNamesInPath ##
function Get-FileSystemEntities {
<#

.SYNOPSIS
Enumerates all of the file system entities (files, folders, volumes) of the system.

.DESCRIPTION
Enumerates all of the file system entities (files, folders, volumes) of the system on this server.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

.PARAMETER Path
    String -- The path to enumerate.

.PARAMETER OnlyFiles
    switch -- 

.PARAMETER OnlyFolders
    switch -- 

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path,

    [Parameter(Mandatory = $false)]
    [Switch]
    $OnlyFiles,

    [Parameter(Mandatory = $false)]
    [Switch]
    $OnlyFolders
)

Set-StrictMode -Version 5.0

<#
.Synopsis
    Name: Get-FileSystemEntities
    Description: Gets all the local file system entities of the machine.

.Parameter Path
    String -- The path to enumerate.

.Returns
    The local file system entities.
#>
function Get-FileSystemEntities
{
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Path
    )

    $folderShares = Get-CimInstance -Class Win32_Share;

    return Get-ChildItem -Path $Path -Force |
        Microsoft.PowerShell.Utility\Select-Object @{Name="Caption"; Expression={$_.FullName}},
                      @{Name="CreationDate"; Expression={$_.CreationTimeUtc}},
                      Extension,
                      @{Name="IsHidden"; Expression={$_.Attributes -match "Hidden"}},
                      @{Name="IsShared"; Expression={[bool]($folderShares | Where-Object Path -eq $_.FullName)}},
                      Name,
                      @{Name="Type"; Expression={Get-FileSystemEntityType -Attributes $_.Attributes}},
                      @{Name="LastModifiedDate"; Expression={$_.LastWriteTimeUtc}},
                      @{Name="Size"; Expression={if ($_.PSIsContainer) { $null } else { $_.Length }}};
}

<#
.Synopsis
    Name: Get-FileSystemEntityType
    Description: Gets the type of a local file system entity.

.Parameter Attributes
    The System.IO.FileAttributes of the FileSystemEntity.

.Returns
    The type of the local file system entity.
#>
function Get-FileSystemEntityType
{
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileAttributes]
        $Attributes
    )

    if ($Attributes -match "Directory")
    {
        return "Folder";
    }
    else
    {
        return "File";
    }
}

$entities = Get-FileSystemEntities -Path $Path;
if ($OnlyFiles -and $OnlyFolders)
{
    return $entities;
}

if ($OnlyFiles)
{
    return $entities | Where-Object { $_.Type -eq "File" };
}

if ($OnlyFolders)
{
    return $entities | Where-Object { $_.Type -eq "Folder" };
}

return $entities;

}
## [END] Get-FileSystemEntities ##
function Get-FileSystemRoot {
<#

.SYNOPSIS
Enumerates the root of the file system (volumes and related entities) of the system.

.DESCRIPTION
Enumerates the root of the file system (volumes and related entities) of the system on this server.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0
import-module CimCmdlets

<#
.Synopsis
    Name: Get-FileSystemRoot
    Description: Gets the local file system root entities of the machine.

.Returns
    The local file system root entities.
#>
function Get-FileSystemRoot
{
    $volumes = Enumerate-Volumes;

    return $volumes |
        Microsoft.PowerShell.Utility\Select-Object @{Name="Caption"; Expression={$_.DriveLetter +":\"}},
                      @{Name="CreationDate"; Expression={$null}},
                      @{Name="Extension"; Expression={$null}},
                      @{Name="IsHidden"; Expression={$false}},
                      @{Name="Name"; Expression={if ($_.FileSystemLabel) { $_.FileSystemLabel + " (" + $_.DriveLetter + ":)"} else { "(" + $_.DriveLetter + ":)" }}},
                      @{Name="Type"; Expression={"Volume"}},
                      @{Name="LastModifiedDate"; Expression={$null}},
                      @{Name="Size"; Expression={$_.Size}},
                      @{Name="SizeRemaining"; Expression={$_.SizeRemaining}}
}

<#
.Synopsis
    Name: Get-Volumes
    Description: Gets the local volumes of the machine.

.Returns
    The local volumes.
#>
function Enumerate-Volumes
{
    Remove-Module Storage -ErrorAction Ignore; # Remove the Storage module to prevent it from automatically localizing

    $isDownlevel = [Environment]::OSVersion.Version.Major -lt 10;
    if ($isDownlevel)
    {
        $disks = Get-CimInstance -ClassName MSFT_Disk -Namespace root/Microsoft/Windows/Storage | Where-Object { !$_.IsClustered };
        $partitions = @($disks | Get-CimAssociatedInstance -ResultClassName MSFT_Partition)
        if ($partitions.Length -eq 0) {
            $volumes = Get-CimInstance -ClassName MSFT_Volume -Namespace root/Microsoft/Windows/Storage;
        } else {
            $volumes = $partitions | Get-CimAssociatedInstance -ResultClassName MSFT_Volume;
        }
    }
    else
    {
        $subsystem = Get-CimInstance -ClassName MSFT_StorageSubSystem -Namespace root/Microsoft/Windows/Storage| Where-Object { $_.FriendlyName -like "Win*" };
        $volumes = $subsystem | Get-CimAssociatedInstance -ResultClassName MSFT_Volume;
    }

    return $volumes | Where-Object { 
        try {
            [byte]$_.DriveLetter -ne 0 -and $_.DriveLetter -ne $null -and $_.Size -gt 0
        } catch {
            $false
        } 
    };
}

Get-FileSystemRoot;

}
## [END] Get-FileSystemRoot ##
function Get-FolderItemCount {
<#

.SYNOPSIS
Gets the count of elements in the folder

.DESCRIPTION
Gets the count of elements in the folder
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Path
    String -- The path to the folder

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path    
)

Set-StrictMode -Version 5.0

$directoryInfo = Get-ChildItem $Path | Microsoft.PowerShell.Utility\Measure-Object
$directoryInfo.count
}
## [END] Get-FolderItemCount ##
function Get-FolderOwner {
<#

.SYNOPSIS
Gets the owner of a folder.

.DESCRIPTION
Gets the owner of a folder.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path
)

Set-StrictMode -Version 5.0

$Owner = (Get-Acl $Path).Owner
@{ owner = $Owner; }
}
## [END] Get-FolderOwner ##
function Get-FolderShareNameUserAccess {
<#

.SYNOPSIS
Gets user access rights to a folder share

.DESCRIPTION
Gets user access rights to a folder share
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Name
    String -- Name of the share.

.PARAMETER AccountName
    String -- The user identification (AD / Local user).

.PARAMETER AccessRight
    String -- Access rights of the user.

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Name,

    [Parameter(Mandatory = $true)]
    [String]
    $AccountName
)

Set-StrictMode -Version 5.0

Get-SmbShareAccess -Name "$Name" | Microsoft.PowerShell.Utility\Select-Object AccountName, AccessControlType, AccessRight | Where-Object {$_.AccountName -eq "$AccountName"}

}
## [END] Get-FolderShareNameUserAccess ##
function Get-FolderShareNames {
<#

.SYNOPSIS
Gets the existing share names of a shared folder

.DESCRIPTION
Gets the existing share names of a shared folder
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Path
    String -- The path to the folder.

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path
)

Set-StrictMode -Version 5.0

Get-CimInstance -Class Win32_Share -Filter Path="'$Path'" | Microsoft.PowerShell.Utility\Select-Object Name

}
## [END] Get-FolderShareNames ##
function Get-FolderSharePath {
<#

.SYNOPSIS
Gets the existing share names of a shared folder

.DESCRIPTION
Gets the existing share names of a shared folder
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Name
    String -- The share name to the shared folder.

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Name
)

Set-StrictMode -Version 5.0

Get-CimInstance -Class Win32_Share -Filter Name="'$Name'" | Microsoft.PowerShell.Utility\Select-Object Path

}
## [END] Get-FolderSharePath ##
function Get-FolderShareStatus {
<#

.SYNOPSIS
Checks if a folder is shared

.DESCRIPTION
Checks if a folder is shared
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Path
    String -- the path to the folder.

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path
)

Set-StrictMode -Version 5.0

$Shared = [bool](Get-CimInstance -Class Win32_Share -Filter Path="'$Path'")
@{ isShared = $Shared }
}
## [END] Get-FolderShareStatus ##
function Get-FolderShareUsers {
<#

.SYNOPSIS
Gets the user access rights of a folder

.DESCRIPTION
Gets the user access rights of a folder
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Path
    String -- The path to the folder.

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path
)

Set-StrictMode -Version 5.0

Get-Acl $Path |  Microsoft.PowerShell.Utility\Select-Object -ExpandProperty Access | Microsoft.PowerShell.Utility\Select-Object IdentityReference, FileSystemRights, AccessControlType

}
## [END] Get-FolderShareUsers ##
function Get-ItemProperties {
<#

.SYNOPSIS
Get item's properties.

.DESCRIPTION
Get item's properties on this server.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

.PARAMETER Path
    String -- the path to the item whose properites are requested.

.PARAMETER ItemType
    String -- What kind of item?

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path,

    [Parameter(Mandatory = $true)]
    [String]
    $ItemType
)

Set-StrictMode -Version 5.0

switch ($ItemType) {
    0 {
        Get-Volume $Path | Microsoft.PowerShell.Utility\Select-Object -Property *
    }
    default {
        Get-ItemProperty $Path | Microsoft.PowerShell.Utility\Select-Object -Property *
    }
}

}
## [END] Get-ItemProperties ##
function Get-ItemType {
<#

.SYNOPSIS
Enumerates all of the file system entities (files, folders, volumes) of the system.

.DESCRIPTION
Enumerates all of the file system entities (files, folders, volumes) of the system on this server.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

.PARAMETER Path
    String -- the path to the folder where enumeration should start.

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path
)

Set-StrictMode -Version 5.0

<#
.Synopsis
    Name: Get-FileSystemEntityType
    Description: Gets the type of a local file system entity.

.Parameter Attributes
    The System.IO.FileAttributes of the FileSystemEntity.

.Returns
    The type of the local file system entity.
#>
function Get-FileSystemEntityType
{
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileAttributes]
        $Attributes
    )

    if ($Attributes -match "Directory")
    {
        return "Folder";
    }
    else
    {
        return "File";
    }
}

if (Test-Path -LiteralPath $Path) {
    return Get-FileSystemEntityType -Attributes (Get-Item $Path).Attributes
} else {
    return ''
}

}
## [END] Get-ItemType ##
function Get-ServerInventory {
<#

.SYNOPSIS
Retrieves the inventory data for a server.

.DESCRIPTION
Retrieves the inventory data for a server.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0

Import-Module CimCmdlets

<#

.SYNOPSIS
Converts an arbitrary version string into just 'Major.Minor'

.DESCRIPTION
To make OS version comparisons we only want to compare the major and 
minor version.  Build number and/os CSD are not interesting.

#>

function convertOsVersion([string]$osVersion) {
    [Ref]$parsedVersion = $null
    if (![Version]::TryParse($osVersion, $parsedVersion)) {
        return $null
    }

    $version = [Version]$parsedVersion.Value
    return New-Object Version -ArgumentList $version.Major, $version.Minor
}

<#

.SYNOPSIS
Determines if CredSSP is enabled for the current server or client.

.DESCRIPTION
Check the registry value for the CredSSP enabled state.

#>

function isCredSSPEnabled() {
    Set-Variable credSSPServicePath -Option Constant -Value "WSMan:\localhost\Service\Auth\CredSSP"
    Set-Variable credSSPClientPath -Option Constant -Value "WSMan:\localhost\Client\Auth\CredSSP"

    $credSSPServerEnabled = $false;
    $credSSPClientEnabled = $false;

    $credSSPServerService = Get-Item $credSSPServicePath -ErrorAction SilentlyContinue
    if ($credSSPServerService) {
        $credSSPServerEnabled = [System.Convert]::ToBoolean($credSSPServerService.Value)
    }

    $credSSPClientService = Get-Item $credSSPClientPath -ErrorAction SilentlyContinue
    if ($credSSPClientService) {
        $credSSPClientEnabled = [System.Convert]::ToBoolean($credSSPClientService.Value)
    }

    return ($credSSPServerEnabled -or $credSSPClientEnabled)
}

<#

.SYNOPSIS
Determines if the Hyper-V role is installed for the current server or client.

.DESCRIPTION
The Hyper-V role is installed when the VMMS service is available.  This is much
faster then checking Get-WindowsFeature and works on Windows Client SKUs.

#>

function isHyperVRoleInstalled() {
    $vmmsService = Get-Service -Name "VMMS" -ErrorAction SilentlyContinue

    return $vmmsService -and $vmmsService.Name -eq "VMMS"
}

<#

.SYNOPSIS
Determines if the Hyper-V PowerShell support module is installed for the current server or client.

.DESCRIPTION
The Hyper-V PowerShell support module is installed when the modules cmdlets are available.  This is much
faster then checking Get-WindowsFeature and works on Windows Client SKUs.

#>
function isHyperVPowerShellSupportInstalled() {
    # quicker way to find the module existence. it doesn't load the module.
    return !!(Get-Module -ListAvailable Hyper-V -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Determines if Windows Management Framework (WMF) 5.0, or higher, is installed for the current server or client.

.DESCRIPTION
Windows Admin Center requires WMF 5 so check the registey for WMF version on Windows versions that are less than
Windows Server 2016.

#>
function isWMF5Installed([string] $operatingSystemVersion) {
    Set-Variable Server2016 -Option Constant -Value (New-Object Version '10.0')   # And Windows 10 client SKUs
    Set-Variable Server2012 -Option Constant -Value (New-Object Version '6.2')

    $version = convertOsVersion $operatingSystemVersion
    if (-not $version) {
        # Since the OS version string is not properly formatted we cannot know the true installed state.
        return $false
    }

    if ($version -ge $Server2016) {
        # It's okay to assume that 2016 and up comes with WMF 5 or higher installed
        return $true
    }
    else {
        if ($version -ge $Server2012) {
            # Windows 2012/2012R2 are supported as long as WMF 5 or higher is installed
            $registryKey = 'HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine'
            $registryKeyValue = Get-ItemProperty -Path $registryKey -Name PowerShellVersion -ErrorAction SilentlyContinue

            if ($registryKeyValue -and ($registryKeyValue.PowerShellVersion.Length -ne 0)) {
                $installedWmfVersion = [Version]$registryKeyValue.PowerShellVersion

                if ($installedWmfVersion -ge [Version]'5.0') {
                    return $true
                }
            }
        }
    }

    return $false
}

<#

.SYNOPSIS
Determines if the current usser is a system administrator of the current server or client.

.DESCRIPTION
Determines if the current usser is a system administrator of the current server or client.

#>
function isUserAnAdministrator() {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

<#

.SYNOPSIS
Get some basic information about the Failover Cluster that is running on this server.

.DESCRIPTION
Create a basic inventory of the Failover Cluster that may be running in this server.

#>
function getClusterInformation() {
    $returnValues = @{}

    $returnValues.IsS2dEnabled = $false
    $returnValues.IsCluster = $false
    $returnValues.ClusterFqdn = $null

    $namespace = Get-CimInstance -Namespace root/MSCluster -ClassName __NAMESPACE -ErrorAction SilentlyContinue
    if ($namespace) {
        $cluster = Get-CimInstance -Namespace root/MSCluster -ClassName MSCluster_Cluster -ErrorAction SilentlyContinue
        if ($cluster) {
            $returnValues.IsCluster = $true
            $returnValues.ClusterFqdn = $cluster.Fqdn
            $returnValues.IsS2dEnabled = !!(Get-Member -InputObject $cluster -Name "S2DEnabled") -and ($cluster.S2DEnabled -gt 0)
        }
    }

    return $returnValues
}

<#

.SYNOPSIS
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the passed in computer name.

.DESCRIPTION
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the passed in computer name.

#>
function getComputerFqdnAndAddress($computerName) {
    $hostEntry = [System.Net.Dns]::GetHostEntry($computerName)
    $addressList = @()
    foreach ($item in $hostEntry.AddressList) {
        $address = New-Object PSObject
        $address | Add-Member -MemberType NoteProperty -Name 'IpAddress' -Value $item.ToString()
        $address | Add-Member -MemberType NoteProperty -Name 'AddressFamily' -Value $item.AddressFamily.ToString()
        $addressList += $address
    }

    $result = New-Object PSObject
    $result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $hostEntry.HostName
    $result | Add-Member -MemberType NoteProperty -Name 'AddressList' -Value $addressList
    return $result
}

<#

.SYNOPSIS
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the current server or client.

.DESCRIPTION
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the current server or client.

#>
function getHostFqdnAndAddress($computerSystem) {
    $computerName = $computerSystem.DNSHostName
    if (!$computerName) {
        $computerName = $computerSystem.Name
    }

    return getComputerFqdnAndAddress $computerName
}

<#

.SYNOPSIS
Are the needed management CIM interfaces available on the current server or client.

.DESCRIPTION
Check for the presence of the required server management CIM interfaces.

#>
function getManagementToolsSupportInformation() {
    $returnValues = @{}

    $returnValues.ManagementToolsAvailable = $false
    $returnValues.ServerManagerAvailable = $false

    $namespaces = Get-CimInstance -Namespace root/microsoft/windows -ClassName __NAMESPACE -ErrorAction SilentlyContinue

    if ($namespaces) {
        $returnValues.ManagementToolsAvailable = !!($namespaces | Where-Object { $_.Name -ieq "ManagementTools" })
        $returnValues.ServerManagerAvailable = !!($namespaces | Where-Object { $_.Name -ieq "ServerManager" })
    }

    return $returnValues
}

<#

.SYNOPSIS
Check the remote app enabled or not.

.DESCRIPTION
Check the remote app enabled or not.

#>
function isRemoteAppEnabled() {
    Set-Variable key -Option Constant -Value "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\TSAppAllowList"

    $registryKeyValue = Get-ItemProperty -Path $key -Name fDisabledAllowList -ErrorAction SilentlyContinue

    if (-not $registryKeyValue) {
        return $false
    }
    return $registryKeyValue.fDisabledAllowList -eq 1
}

<#

.SYNOPSIS
Check the remote app enabled or not.

.DESCRIPTION
Check the remote app enabled or not.

#>

<#
c
.SYNOPSIS
Get the Win32_OperatingSystem information

.DESCRIPTION
Get the Win32_OperatingSystem instance and filter the results to just the required properties.
This filtering will make the response payload much smaller.

#>
function getOperatingSystemInfo() {
    return Get-CimInstance Win32_OperatingSystem | Microsoft.PowerShell.Utility\Select-Object csName, Caption, OperatingSystemSKU, Version, ProductType
}

<#

.SYNOPSIS
Get the Win32_ComputerSystem information

.DESCRIPTION
Get the Win32_ComputerSystem instance and filter the results to just the required properties.
This filtering will make the response payload much smaller.

#>
function getComputerSystemInfo() {
    return Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | `
        Microsoft.PowerShell.Utility\Select-Object TotalPhysicalMemory, DomainRole, Manufacturer, Model, NumberOfLogicalProcessors, Domain, Workgroup, DNSHostName, Name, PartOfDomain
}

###########################################################################
# main()
###########################################################################

$operatingSystem = getOperatingSystemInfo
$computerSystem = getComputerSystemInfo
$isAdministrator = isUserAnAdministrator
$fqdnAndAddress = getHostFqdnAndAddress $computerSystem
$hostname = hostname
$netbios = $env:ComputerName
$managementToolsInformation = getManagementToolsSupportInformation
$isWmfInstalled = isWMF5Installed $operatingSystem.Version
$clusterInformation = getClusterInformation -ErrorAction SilentlyContinue
$isHyperVPowershellInstalled = isHyperVPowerShellSupportInstalled
$isHyperVRoleInstalled = isHyperVRoleInstalled
$isCredSSPEnabled = isCredSSPEnabled
$isRemoteAppEnabled = isRemoteAppEnabled

$result = New-Object PSObject
$result | Add-Member -MemberType NoteProperty -Name 'IsAdministrator' -Value $isAdministrator
$result | Add-Member -MemberType NoteProperty -Name 'OperatingSystem' -Value $operatingSystem
$result | Add-Member -MemberType NoteProperty -Name 'ComputerSystem' -Value $computerSystem
$result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $fqdnAndAddress.Fqdn
$result | Add-Member -MemberType NoteProperty -Name 'AddressList' -Value $fqdnAndAddress.AddressList
$result | Add-Member -MemberType NoteProperty -Name 'Hostname' -Value $hostname
$result | Add-Member -MemberType NoteProperty -Name 'NetBios' -Value $netbios
$result | Add-Member -MemberType NoteProperty -Name 'IsManagementToolsAvailable' -Value $managementToolsInformation.ManagementToolsAvailable
$result | Add-Member -MemberType NoteProperty -Name 'IsServerManagerAvailable' -Value $managementToolsInformation.ServerManagerAvailable
$result | Add-Member -MemberType NoteProperty -Name 'IsWmfInstalled' -Value $isWmfInstalled
$result | Add-Member -MemberType NoteProperty -Name 'IsCluster' -Value $clusterInformation.IsCluster
$result | Add-Member -MemberType NoteProperty -Name 'ClusterFqdn' -Value $clusterInformation.ClusterFqdn
$result | Add-Member -MemberType NoteProperty -Name 'IsS2dEnabled' -Value $clusterInformation.IsS2dEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsHyperVRoleInstalled' -Value $isHyperVRoleInstalled
$result | Add-Member -MemberType NoteProperty -Name 'IsHyperVPowershellInstalled' -Value $isHyperVPowershellInstalled
$result | Add-Member -MemberType NoteProperty -Name 'IsCredSSPEnabled' -Value $isCredSSPEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsRemoteAppEnabled' -Value $isRemoteAppEnabled

$result

}
## [END] Get-ServerInventory ##
function Get-TempFolderPath {
<#

.SYNOPSIS
Gets the temporary folder (%temp%) for the user.

.DESCRIPTION
Gets the temporary folder (%temp%) for the user.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

#>

Set-StrictMode -Version 5.0

return $env:TEMP

}
## [END] Get-TempFolderPath ##
function Install-MMAgent {
<#

.SYNOPSIS
Download and install Microsoft Monitoring Agent for Windows.

.DESCRIPTION
Download and install Microsoft Monitoring Agent for Windows.

.PARAMETER workspaceId
The log analytics workspace id a target node has to connect to.

.PARAMETER workspacePrimaryKey
The primary key of log analytics workspace.

.PARAMETER taskName
The task name.

.ROLE
Readers

#>

param(
    [Parameter(Mandatory = $true)]
    [String]
    $workspaceId,
    [Parameter(Mandatory = $true)]
    [String]
    $workspacePrimaryKey,
    [Parameter(Mandatory = $true)]
    [String]
    $taskName
)

$Script = @'
$mmaExe = Join-Path -Path $env:temp -ChildPath 'MMASetup-AMD64.exe'
if (Test-Path $mmaExe) {
    Remove-Item $mmaExe
}

Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?LinkId=828603 -OutFile $mmaExe

$extractFolder = Join-Path -Path $env:temp -ChildPath 'SmeMMAInstaller'
if (Test-Path $extractFolder) {
    Remove-Item $extractFolder -Force -Recurse
}

&$mmaExe /c /t:$extractFolder
$setupExe = Join-Path -Path $extractFolder -ChildPath 'setup.exe'
for ($i=1; $i -le 10; $i++) {
    if(-Not(Test-Path $setupExe)) {
        sleep -s 6
    }
}

&$setupExe /qn NOAPM=1 ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=0 OPINSIGHTS_WORKSPACE_ID=$workspaceId OPINSIGHTS_WORKSPACE_KEY=$workspacePrimaryKey AcceptEndUserLicenseAgreement=1
'@

$Script = '$workspaceId = ' + "'$workspaceId';" + $Script
$Script = '$workspacePrimaryKey =' + "'$workspacePrimaryKey';" + $Script

$ScriptFile = Join-Path -Path $env:LocalAppData -ChildPath "$taskName.ps1"
$ResultFile = Join-Path -Path $env:temp -ChildPath "$taskName.log"
if (Test-Path $ResultFile) {
    Remove-Item $ResultFile
}

$Script | Out-File $ScriptFile
if (-Not(Test-Path $ScriptFile)) {
    $message = "Failed to create file:" + $ScriptFile
    Write-Error $message
    return #If failed to create script file, no need continue just return here
}

#Create a scheduled task
$User = [Security.Principal.WindowsIdentity]::GetCurrent()
$Role = (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$arg = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -c $ScriptFile >> $ResultFile 2>&1"
if(!$Role)
{
  Write-Warning "To perform some operations you must run an elevated Windows PowerShell console."
}

$Scheduler = New-Object -ComObject Schedule.Service

#Try to connect to schedule service 3 time since it may fail the first time
for ($i=1; $i -le 3; $i++)
{
  Try
  {
    $Scheduler.Connect()
    Break
  }
  Catch
  {
    if($i -ge 3)
    {
      Write-EventLog -LogName Application -Source "SME Register $taskName" -EntryType Error -EventID 1 -Message "Can't connect to Schedule service"
      Write-Error "Can't connect to Schedule service" -ErrorAction Stop
    }
    else
    {
      Start-Sleep -s 1
    }
  }
}

$RootFolder = $Scheduler.GetFolder("\")
#Delete existing task
if($RootFolder.GetTasks(0) | Where-Object {$_.Name -eq $TaskName})
{
  Write-Debug("Deleting existing task" + $TaskName)
  $RootFolder.DeleteTask($TaskName,0)
}

$Task = $Scheduler.NewTask(0)
$RegistrationInfo = $Task.RegistrationInfo
$RegistrationInfo.Description = $TaskName
$RegistrationInfo.Author = $User.Name

$Triggers = $Task.Triggers
$Trigger = $Triggers.Create(7) #TASK_TRIGGER_REGISTRATION: Starts the task when the task is registered.
$Trigger.Enabled = $true

$Settings = $Task.Settings
$Settings.Enabled = $True
$Settings.StartWhenAvailable = $True
$Settings.Hidden = $False
$Settings.ExecutionTimeLimit  = "PT20M" # 20 minutes

$Action = $Task.Actions.Create(0)
$Action.Path = "powershell"
$Action.Arguments = $arg

#Tasks will be run with the highest privileges
$Task.Principal.RunLevel = 1

#Start the task to run in Local System account. 6: TASK_CREATE_OR_UPDATE
$RootFolder.RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $Null, 1) | Out-Null
#Wait for running task finished
$RootFolder.GetTask($TaskName).Run(0) | Out-Null
while($Scheduler.GetRunningTasks(0) | Where-Object {$_.Name -eq $TaskName})
{
  Start-Sleep -s 1
}

#Clean up
$RootFolder.DeleteTask($TaskName,0)
Remove-Item $ScriptFile

if (Test-Path $ResultFile)
{
    Get-Content -Path $ResultFile | Out-String -Stream
    Remove-Item $ResultFile
}

}
## [END] Install-MMAgent ##
function New-Folder {
<#

.SYNOPSIS
Create a new folder.

.DESCRIPTION
Create a new folder on this server.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

.PARAMETER Path
    String -- the path to the parent of the new folder.

.PARAMETER NewName
    String -- the folder name.

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path,

    [Parameter(Mandatory = $true)]
    [String]
    $NewName
)

Set-StrictMode -Version 5.0

$pathSeparator = [System.IO.Path]::DirectorySeparatorChar;
$newItem = New-Item -ItemType Directory -Path ($Path.TrimEnd($pathSeparator) + $pathSeparator + $NewName)

return $newItem |
    Microsoft.PowerShell.Utility\Select-Object @{Name="Caption"; Expression={$_.FullName}},
                  @{Name="CreationDate"; Expression={$_.CreationTimeUtc}},
                  Extension,
                  @{Name="IsHidden"; Expression={$_.Attributes -match "Hidden"}},
                  Name,
                  @{Name="Type"; Expression={Get-FileSystemEntityType -Attributes $_.Attributes}},
                  @{Name="LastModifiedDate"; Expression={$_.LastWriteTimeUtc}},
                  @{Name="Size"; Expression={if ($_.PSIsContainer) { $null } else { $_.Length }}};

}
## [END] New-Folder ##
function Remove-AllShareNames {
<#

.SYNOPSIS
Removes all shares of a folder.

.DESCRIPTION
Removes all shares of a folder.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Path
    String -- The path to the folder.

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path    
)

Set-StrictMode -Version 5.0

$CimInstance = Get-CimInstance -Class Win32_Share -Filter Path="'$Path'"
$RemoveShareCommand = ''
if ($CimInstance.name -And $CimInstance.name.GetType().name -ne 'String') { $RemoveShareCommand = $CimInstance.ForEach{ 'Remove-SmbShare -Name "' + $_.name + '" -Force'} } 
Else { $RemoveShareCommand = 'Remove-SmbShare -Name "' + $CimInstance.Name + '" -Force'}
if($RemoveShareCommand) { $RemoveShareCommand.ForEach{ Invoke-Expression $_ } }


}
## [END] Remove-AllShareNames ##
function Remove-FileSystemEntity {
<#

.SYNOPSIS
Remove the passed in file or path.

.DESCRIPTION
Remove the passed in file or path from this server.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER path
    String -- the file or path to remove.

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path
)

Set-StrictMode -Version 5.0

Remove-Item -Path $Path -Confirm:$false -Force -Recurse

}
## [END] Remove-FileSystemEntity ##
function Remove-FolderShareUser {
<#

.SYNOPSIS
Removes a user from the folder access.

.DESCRIPTION
Removes a user from the folder access.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Path
    String -- The path to the folder.

.PARAMETER Identity
    String -- The user identification (AD / Local user).

.PARAMETER FileSystemRights
    String -- File system rights of the user.

.PARAMETER AccessControlType
    String -- Access control type of the user.    

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path,

    [Parameter(Mandatory = $true)]
    [String]
    $Identity,

    [Parameter(Mandatory = $true)]
    [String]
    $FileSystemRights,

    [ValidateSet('Deny','Allow')]
    [Parameter(Mandatory = $true)]
    [String]
    $AccessControlType
)

Set-StrictMode -Version 5.0

function Remove-UserPermission
{
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Path,
    
        [Parameter(Mandatory = $true)]
        [String]
        $Identity,
        
        [ValidateSet('Deny','Allow')]
        [Parameter(Mandatory = $true)]
        [String]
        $ACT
    )

    $Acl = Get-Acl $Path
    $AccessRule = New-Object system.security.accesscontrol.filesystemaccessrule($Identity, 'ReadAndExecute','ContainerInherit, ObjectInherit', 'None', $ACT)
    $Acl.RemoveAccessRuleAll($AccessRule)
    Set-Acl $Path $Acl
}

Remove-UserPermission $Path $Identity 'Allow'
Remove-UserPermission $Path $Identity 'Deny'
}
## [END] Remove-FolderShareUser ##
function Rename-FileSystemEntity {
<#

.SYNOPSIS
Rename a folder.

.DESCRIPTION
Rename a folder on this server.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Path
    String -- the path to the folder.

.PARAMETER NewName
    String -- the new folder name.

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path,

    [Parameter(Mandatory = $true)]
    [String]
    $NewName
)

Set-StrictMode -Version 5.0

<#
.Synopsis
    Name: Get-FileSystemEntityType
    Description: Gets the type of a local file system entity.

.Parameters
    $Attributes: The System.IO.FileAttributes of the FileSystemEntity.

.Returns
    The type of the local file system entity.
#>
function Get-FileSystemEntityType
{
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileAttributes]
        $Attributes
    )

    if ($Attributes -match "Directory")
    {
        return "Folder";
    }
    else
    {
        return "File";
    }
}

Rename-Item -Path $Path -NewName $NewName -PassThru |
    Microsoft.PowerShell.Utility\Select-Object @{Name="Caption"; Expression={$_.FullName}},
                @{Name="CreationDate"; Expression={$_.CreationTimeUtc}},
                Extension,
                @{Name="IsHidden"; Expression={$_.Attributes -match "Hidden"}},
                Name,
                @{Name="Type"; Expression={Get-FileSystemEntityType -Attributes $_.Attributes}},
                @{Name="LastModifiedDate"; Expression={$_.LastWriteTimeUtc}},
                @{Name="Size"; Expression={if ($_.PSIsContainer) { $null } else { $_.Length }}};

}
## [END] Rename-FileSystemEntity ##
function Test-FileSystemEntity {
<#

.SYNOPSIS
Checks if a file or folder exists

.DESCRIPTION
Checks if a file or folder exists
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

.PARAMETER Path
    String -- The path to check if it exists

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path    
)

Set-StrictMode -Version 5.0

Test-Path -path $Path

}
## [END] Test-FileSystemEntity ##

# SIG # Begin signature block
# MIIdjgYJKoZIhvcNAQcCoIIdfzCCHXsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU98VIdgvIa8dX+3gIG4ZCKT/c
# 5zagghhqMIIE2jCCA8KgAwIBAgITMwAAASDzON/Hnq4y7AAAAAABIDANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgxMDI0MjEwNzM4
# WhcNMjAwMTEwMjEwNzM4WjCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEm
# MCQGA1UECxMdVGhhbGVzIFRTUyBFU046MjI2NC1FMzNFLTc4MEMxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCO1OidLADhraPZx5FTVbd0PlB1xUfJ0J9zuRe1282yigKI
# +r7rvHTBllcSjV+E6G3BKO1FX7oV2CGaAGduTl2kk0vGSlrXC48bzR0SAb1Ui49r
# bUJTA++yfZA+34s8vYUye1XX2T5D0GKukK1hLkf8d7p2A5nygvMtnnybzmEVavSd
# g8lYzjK2EuekiLzL/lYUxAp2vRNFUitr7MHix5iU2nHEG4yU8crlXjYFgJ7q3CFv
# Il1yMsP/j+wk+1oCC1oLV6iOBcpq0Nxda/o+qN78nQFoQssfHoA9YdBGUnRHk+dK
# Sq5+GiV3AY0TRad2ZRzLcIcNmUJXny26YG+eokTpAgMBAAGjggEJMIIBBTAdBgNV
# HQ4EFgQUIkw9WwdWW+zV8Il/Jq7A7bh6G7cwHwYDVR0jBBgwFoAUIzT42VJGcArt
# QPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL2NybC5taWNyb3Nv
# ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNy
# bDBYBggrBgEFBQcBAQRMMEowSAYIKwYBBQUHMAKGPGh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNydDATBgNV
# HSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQUFAAOCAQEAE4tuQuXzzaC2OIk4
# ZhJanhsgQv9Tk8ns/9elb8pAgYyZlSwxUtovV8Pd70jtAt0U/wjGd9n+QQJZKILM
# 6WCIieZFkZbqT9Ut9zA+tc2eQn4mt62PlyA+YJZNHEiPZhwgbjfLIwMRsm845B4N
# KN7WmfYwspHdT/mPgLWaBsSWS80PuAtpG3N+o9eTHskT+qauYAMqhZExfI8S2Rg4
# kdqAm7EU/Nroe4g0p+eKw6CAQ2ZuhuqHMMPgcQlSejcEbpS5WAzdCRd6qDXPHh0r
# C3FayhXrwu/KKuNW2hR1ZCx/ieNiR8+lWt1JxXgWAttgaRtR3VqGlL4aolg41UCo
# XfN1IjCCBf8wggPnoAMCAQICEzMAAAEDXiUcmR+jHrgAAAAAAQMwDQYJKoZIhvcN
# AQELBQAwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYG
# A1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTAeFw0xODA3MTIy
# MDA4NDhaFw0xOTA3MjYyMDA4NDhaMHQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xHjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANGUdjbmhqs2/mn5RnyLiFDLkHB/
# sFWpJB1+OecFnw+se5eyznMK+9SbJFwWtTndG34zbBH8OybzmKpdU2uqw+wTuNLv
# z1d/zGXLr00uMrFWK040B4n+aSG9PkT73hKdhb98doZ9crF2m2HmimRMRs621TqM
# d5N3ZyGctloGXkeG9TzRCcoNPc2y6aFQeNGEiOIBPCL8r5YIzF2ZwO3rpVqYkvXI
# QE5qc6/e43R6019Gl7ziZyh3mazBDjEWjwAPAf5LXlQPysRlPwrjo0bb9iwDOhm+
# aAUWnOZ/NL+nh41lOSbJY9Tvxd29Jf79KPQ0hnmsKtVfMJE75BRq67HKBCMCAwEA
# AaOCAX4wggF6MB8GA1UdJQQYMBYGCisGAQQBgjdMCAEGCCsGAQUFBwMDMB0GA1Ud
# DgQWBBRHvsDL4aY//WXWOPIDXbevd/dA/zBQBgNVHREESTBHpEUwQzEpMCcGA1UE
# CxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJpY28xFjAUBgNVBAUTDTIz
# MDAxMis0Mzc5NjUwHwYDVR0jBBgwFoAUSG5k5VAF04KqFzc3IrVtqMp1ApUwVAYD
# VR0fBE0wSzBJoEegRYZDaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljQ29kU2lnUENBMjAxMV8yMDExLTA3LTA4LmNybDBhBggrBgEFBQcBAQRV
# MFMwUQYIKwYBBQUHMAKGRWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y2VydHMvTWljQ29kU2lnUENBMjAxMV8yMDExLTA3LTA4LmNydDAMBgNVHRMBAf8E
# AjAAMA0GCSqGSIb3DQEBCwUAA4ICAQCf9clTDT8NJuyiRNgN0Z9jlgZLPx5cxTOj
# pMNsrx/AAbrrZeyeMxAPp6xb1L2QYRfnMefDJrSs9SfTSJOGiP4SNZFkItFrLTuo
# LBWUKdI3luY1/wzOyAYWFp4kseI5+W4OeNgMG7YpYCd2NCSb3bmXdcsBO62CEhYi
# gIkVhLuYUCCwFyaGSa/OfUUVQzSWz4FcGCzUk/Jnq+JzyD2jzfwyHmAc6bAbMPss
# uwculoSTRShUXM2W/aDbgdi2MMpDsfNIwLJGHF1edipYn9Tu8vT6SEy1YYuwjEHp
# qridkPT/akIPuT7pDuyU/I2Au3jjI6d4W7JtH/lZwX220TnJeeCDHGAK2j2w0e02
# v0UH6Rs2buU9OwUDp9SnJRKP5najE7NFWkMxgtrYhK65sB919fYdfVERNyfotTWE
# cfdXqq76iXHJmNKeWmR2vozDfRVqkfEU9PLZNTG423L6tHXIiJtqv5hFx2ay1//O
# kpB15OvmhtLIG9snwFuVb0lvWF1pKt5TS/joynv2bBX5AxkPEYWqT5q/qlfdYMb1
# cSD0UaiayunR6zRHPXX6IuxVP2oZOWsQ6Vo/jvQjeDCy8qY4yzWNqphZJEC4Omek
# B1+g/tg7SRP7DOHtC22DUM7wfz7g2QjojCFKQcLe645b7gPDHW5u5lQ1ZmdyfBrq
# UvYixHI/rjCCBgcwggPvoAMCAQICCmEWaDQAAAAAABwwDQYJKoZIhvcNAQEFBQAw
# XzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jvc29m
# dDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# MB4XDTA3MDQwMzEyNTMwOVoXDTIxMDQwMzEzMDMwOVowdzELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgUENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAn6Fssd/b
# SJIqfGsuGeG94uPFmVEjUK3O3RhOJA/u0afRTK10MCAR6wfVVJUVSZQbQpKumFww
# JtoAa+h7veyJBw/3DgSY8InMH8szJIed8vRnHCz8e+eIHernTqOhwSNTyo36Rc8J
# 0F6v0LBCBKL5pmyTZ9co3EZTsIbQ5ShGLieshk9VUgzkAyz7apCQMG6H81kwnfp+
# 1pez6CGXfvjSE/MIt1NtUrRFkJ9IAEpHZhEnKWaol+TTBoFKovmEpxFHFAmCn4Tt
# VXj+AZodUAiFABAwRu233iNGu8QtVJ+vHnhBMXfMm987g5OhYQK1HQ2x/PebsgHO
# IktU//kFw8IgCwIDAQABo4IBqzCCAacwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4E
# FgQUIzT42VJGcArtQPt2+7MrsMM1sw8wCwYDVR0PBAQDAgGGMBAGCSsGAQQBgjcV
# AQQDAgEAMIGYBgNVHSMEgZAwgY2AFA6sgmBAVieX5SUT/CrhClOVWeSkoWOkYTBf
# MRMwEQYKCZImiZPyLGQBGRYDY29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0
# MS0wKwYDVQQDEyRNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHmC
# EHmtFqFKoKWtTHNY9AcTLmUwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC5t
# aWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvbWljcm9zb2Z0cm9vdGNlcnQu
# Y3JsMFQGCCsGAQUFBwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraS9jZXJ0cy9NaWNyb3NvZnRSb290Q2VydC5jcnQwEwYDVR0l
# BAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQEFBQADggIBABCXisNcA0Q23em0rXfb
# znlRTQGxLnRxW20ME6vOvnuPuC7UEqKMbWK4VwLLTiATUJndekDiV7uvWJoc4R0B
# hqy7ePKL0Ow7Ae7ivo8KBciNSOLwUxXdT6uS5OeNatWAweaU8gYvhQPpkSokInD7
# 9vzkeJkuDfcH4nC8GE6djmsKcpW4oTmcZy3FUQ7qYlw/FpiLID/iBxoy+cwxSnYx
# PStyC8jqcD3/hQoT38IKYY7w17gX606Lf8U1K16jv+u8fQtCe9RTciHuMMq7eGVc
# WwEXChQO0toUmPU8uWZYsy0v5/mFhsxRVuidcJRsrDlM1PZ5v6oYemIp76KbKTQG
# dxpiyT0ebR+C8AvHLLvPQ7Pl+ex9teOkqHQ1uE7FcSMSJnYLPFKMcVpGQxS8s7Ow
# TWfIn0L/gHkhgJ4VMGboQhJeGsieIiHQQ+kr6bv0SMws1NgygEwmKkgkX1rqVu+m
# 3pmdyjpvvYEndAYR7nYhv5uCwSdUtrFqPYmhdmG0bqETpr+qR/ASb/2KMmyy/t9R
# yIwjyWa9nR2HEmQCPS2vWY+45CHltbDKY7R4VAXUQS5QrJSwpXirs6CWdRrZkocT
# dSIvMqgIbqBbjCW/oO+EyiHW6x5PyZruSeD3AWVviQt9yGnI5m7qp5fOMSn/DsVb
# XNhNG6HY+i+ePy5VFmvJE6P9MIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCBI4wggSKAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAEDXiUcmR+jHrgAAAAAAQMwCQYFKw4DAhoFAKCB
# ojAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUU9rDe/TcUCeCrz3DC/7gWn6z+Aow
# QgYKKwYBBAGCNwIBDDE0MDKgFIASAE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbTANBgkqhkiG9w0BAQEFAASCAQCzvmbFVpRL9ag2
# /RVc4MyhiQqHU+Vh83lC9GgeYeeeAKO3ej+LnSZksrXXbMbgdVPVguUZDORyU4yb
# vWxH9Mt3kwcp5Td2ZzyYZHXwkIAPLSKnuz90Q9V36F4fiIxT31hlUnOJ/fY7JQRF
# LH7dHiSiehrrNDi6G5EGECdiEDHpxaS9acd15sLdGkJouYnrUf6iDGYIUZC4saBO
# QqJ4chNLcnrqFrPGgn5CSPGjvWNjnizASwjqQWzo4GLWGDA8gzZTDoetZWRiPuny
# E4pbRQTu6teeGgV/eIa6tRl8biLUHI2+yiJyB0C7UWILWhwSStRPNl11wvTE7cWb
# sdzYfYqkoYICKDCCAiQGCSqGSIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQQITMwAAASDzON/Hnq4y7AAAAAABIDAJBgUrDgMCGgUA
# oF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTkw
# NDAyMjEyMDQ5WjAjBgkqhkiG9w0BCQQxFgQU+mpy5z9XyAqr8W59OIKhDivxHtAw
# DQYJKoZIhvcNAQEFBQAEggEARJIuM1hq6gYElbEWqigdIuNYnQqEkYLZcFtcabaf
# nHLjgkkRJITkV2Lev/NbYWaliJ2no69rhqqS0Lb3wjEdjW8Td9unMAvFDi47SMBz
# o57su1/sacBsjiO8hpnzD+6wJzXQy0v/gdE9+UTgEdxLxwRuGdGjrYv5KQG9sgVt
# MVjBuDv1DtDRhyHr7PhRmN8ioJDXIHpbJAV4cuLHcl43N3LtNcbDQUhTKzNz4p2W
# 31THILSGlYYLw2+MLUp0hkrJy+GRDCrLm053VwtSUlGMGY2zRgDCd2shz/yjMy/H
# EOpqbgNhZ8cw0puYTV6gcrFM4KSqBsYAWO7N+0/SUP0VVg==
# SIG # End signature block
