# Function to create and configure a Dev Drive
function Create-DevDrive {
    param (
        [string]$vhdPath,
        [string]$fileSystemLabel,
        [int]$sizeGB = 80
    )

    # Check if the directory for VHDs exists, create it if not
    $vhdDir = [System.IO.Path]::GetDirectoryName($vhdPath)
    if (-not (Test-Path -Path $vhdDir)) {
        New-Item -ItemType Directory -Path $vhdDir
    }

    # Create a new VHD
    New-VHD -Path $vhdPath -SizeBytes ($sizeGB * 1GB) -Dynamic

    # Mount the VHD
    Mount-VHD -Path $vhdPath

    # Get the most recently added disk
    $disk = Get-Disk | Sort-Object -Property Number -Descending | Select-Object -First 1

    # Initialize the disk
    Initialize-Disk -Number $disk.Number -PartitionStyle GPT -Confirm:$false

    # Create a new partition and assign a drive letter
    $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter

    # Format the partition as ReFS and set the Dev Drive flag
    Format-Volume -DriveLetter $partition.DriveLetter -FileSystem ReFS -NewFileSystemLabel $fileSystemLabel -Full -Force

    # Query the Dev Drive status
    fsutil devdrv query $partition.DriveLetter

    # Return the drive letter of the new partition
    return $partition.DriveLetter
}

# Paths and labels for the Dev Drives
$devDriveConfigs = @(
    @{ Path = "D:\devDrives\npm_cache.vhdx"; Label = "npm_cache" },
    @{ Path = "D:\devDrives\nuget_cache.vhdx"; Label = "nuget_cache" },
    @{ Path = "D:\devDrives\pip_cache.vhdx"; Label = "pip_cache" },
    @{ Path = "D:\devDrives\cargo_cache.vhdx"; Label = "cargo_cache" },
    @{ Path = "D:\devDrives\maven_cache.vhdx"; Label = "maven_cache" }
)

# Create and configure each Dev Drive
foreach ($config in $devDriveConfigs) {
    $driveLetter = Create-DevDrive -vhdPath $config.Path -fileSystemLabel $config.Label
    Write-Output "Created and mounted Dev Drive for $($config.Label) at drive letter $driveLetter"
}
