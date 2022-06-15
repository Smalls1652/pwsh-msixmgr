[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$InstallPath,
    [Parameter(Position = 1)]
    [switch]$AddToUserPathEnvironmentVariable
)

function updateEnvironmentPathVar {
    [CmdletBinding()]
    param()
    
    $env:Path = "$([System.Environment]::GetEnvironmentVariable("Path","Machine"));$([System.Environment]::GetEnvironmentVariable("Path","User"))"
}

$msixmgrZipUrl = "https://aka.ms/msixmgr"

$finalInstallPath = $null
$dirDoesNotExist = $false
if ([string]::IsNullOrEmpty($InstallPath)) {
    # If 'InstallPath' is null, then set the final install path to 'path\to\userprofile\.msixmgr'.
    # The path is built by getting the user profile path from current user's environment variables.
    $finalInstallPath = Join-Path -Path ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)) -ChildPath ".msixmgr\"

    if ((Test-Path -Path $finalInstallPath) -eq $false) {
        # If the install path doesn't exist, set 'dirDoesNotExist' to true.
        $dirDoesNotExist = $true
    }
}
else {
    # If 'InstallPath' is not null, then try to resolve the path.
    try {
        $finalInstallPath = (Resolve-Path -Path $InstallPath -ErrorAction "Stop").Path
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        # If the path wasn't resolved, then set 'dirDoesNotExist' to true
        # and set the final install path to what was provided in 'InstallPath'.
        $dirDoesNotExist = $true
        $finalInstallPath = $InstallPath
    }
    catch {
        # If 'Resolve-Path' encountered any other error, then terminate with that error.
        $errorDetails = $PSItem
        $PSCmdlet.ThrowTerminatingError($errorDetails)
    }

    if (($dirDoesNotExist -eq $false) -and ((Get-Item -Path $finalInstallPath).Attributes -ne [System.IO.FileAttributes]::Directory)) {
        # If the path has been resolved successfully and the item is not a directory,
        # then throw a terminating error.
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.IO.IOException]::new("The install path specified is not a directory."),
                "InstallPathNotDir",
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $finalInstallPath
            )
        )
    }
}

Write-Verbose "Install path: $($finalInstallPath)"
Write-Verbose "Install path does not exist: $($dirDoesNotExist)"

if ($dirDoesNotExist -eq $true) {
    # Create the install path, if it doesn't exist.
    $finalInstallPath = (New-Item -Path $finalInstallPath -ItemType "Directory" -ErrorAction "Stop").FullName
}

if ($dirDoesNotExist -eq $false) {
    # If the install path was set as already existing,
    # remove all the current files in that directory.
    Write-Verbose "Removing all currently installed files."
    $installedItems = Get-ChildItem -Path $finalInstallPath
    foreach ($installedItem in $installedItems) {
        if ($installedItem.Attributes -eq [System.IO.FileAttributes]::Directory) {
            Remove-Item -Path $installedItem -Force -Recurse -Verbose:$false
        }
        else {
            Remove-Item -Path $installedItem -Force -Verbose:$false
        }
    }
}

$tmpOutputDirPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.IO.Path]::GetRandomFileName())
$tmpOutputZipOutPath = Join-Path -Path $tmpOutputDirPath -ChildPath "msixmgr.zip"
$tmpOutputZipExpandedPath = Join-Path -Path $tmpOutputDirPath -ChildPath "msixmgr\"

$null = New-Item -Path $tmpOutputDirPath -ItemType "Directory"

Write-Verbose "Downloading 'msixmgr' ZIP file."
$ProgressPreference = "SilentlyContinue"
Invoke-WebRequest -Uri $msixmgrZipUrl -OutFile $tmpOutputZipOutPath
$ProgressPreference = "Continue"

Write-Verbose "Unzipping the ZIP file."
$ProgressPreference = "SilentlyContinue"
$null = Expand-Archive -Path $tmpOutputZipOutPath -DestinationPath $tmpOutputZipExpandedPath -Verbose:$false
$ProgressPreference = "Continue"

$x64BinDir = Join-Path -Path $tmpOutputZipExpandedPath -ChildPath "x64\"
$itemsInExpandedDir = Get-ChildItem -Path $x64BinDir

foreach ($fileItem in $itemsInExpandedDir) {
    Write-Verbose "Copying $($fileItem.Name) -> $($finalInstallPath)"

    $fileDstPath = Join-Path -Path $finalInstallPath -ChildPath $fileItem.Name
    Copy-Item -Path $fileItem.FullName -Destination $fileDstPath -Recurse -Force -Verbose:$false
}

Write-Verbose "Cleaning up temporary files."
Remove-Item -Path $tmpOutputDirPath -Force -Recurse

if ($AddToUserPathEnvironmentVariable -eq $true) {
    # If the 'AddToUserPathEnvironmentVariable' switch parameter was provided,
    # then start the process of adding the install path to the current user's PATH environment variable.

    # Get the current items in the PATH variable.
    Write-Verbose "Getting the items in the current user's PATH environment variable."
    $currentPathVarItems = [System.Collections.Generic.List[string]]::new((Get-ItemPropertyValue -Path "HKCU:\Environment\" -Name "Path").Split(";"))
    
    $trimmedInstallPath = [System.IO.Path]::TrimEndingDirectorySeparator($finalInstallPath)
    if ($trimmedInstallPath -notin $currentPathVarItems) {
        # If the install path is not in the PATH variable, then add it in.

        Write-Warning "'$($trimmedInstallPath)' is not in the current user's PATH environment variable. Adding..."
        $currentPathVarItems.Add($trimmedInstallPath)

        $null = Set-ItemProperty -Path "HKCU:\Environment\" -Name "Path" -Value ([string]::Join(";", $currentPathVarItems))

        # Refresh the current PowerShell session's definition of the PATH variable with the newly added contents.
        Write-Verbose "Refreshing the current session's PATH environment variable."
        updateEnvironmentPathVar
    }
    else {
        # If the install path is already in the PATH variable, then do nothing.
        Write-Verbose "'$($trimmedInstallPath)' is already in the current user's PATH environment variable."
    }
}