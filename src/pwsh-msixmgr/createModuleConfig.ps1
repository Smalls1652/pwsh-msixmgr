[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [switch]$DoNotBuildCommandConfigs
)

Write-Verbose "Creating module config"

$moduleConfigDirPath = Join-Path -Path $PSScriptRoot -ChildPath "module-config\"
$commandConfigsDirPath = Join-Path -Path $PSScriptRoot -ChildPath "command-configs\"

# Remove the 'module-config\' directory, if needed, and then create it.
if (Test-Path -Path $moduleConfigDirPath) {
    Write-Verbose "Cleaning '$($moduleConfigDirPath)'"
    Remove-Item -Path $moduleConfigDirPath -Recurse -Force
}
$null = New-Item -Path $moduleConfigDirPath -ItemType "Directory"

$outFile = Join-Path -Path $PSScriptRoot -ChildPath "module-config\module.json"


if (!$DoNotBuildCommandConfigs) {
    # Remove the 'command-configs\' directory, if needed, and then create it.
    if (Test-Path -Path $commandConfigsDirPath) {
        Write-Verbose "Cleaning '$($commandConfigsDirPath)'"
        Remove-Item -Path $commandConfigsDirPath -Recurse -Force
    }
    $null = New-Item -Path $commandConfigsDirPath -ItemType "Directory"

    # Run each script in the directory that starts as 'createCommand_'.
    $createScripts = Get-ChildItem -Path $PSScriptRoot | Where-Object { $PSItem.Name -like "createCommand_*" -and $PSItem.Extension -eq ".ps1" }
    foreach ($createScriptItem in $createScripts) {
        . "$($createScriptItem.FullName)"
    }
}
else {
    Write-Warning "Not rebuilding the command configs."
}

# Get all of the generated command config items.
$commandConfigFiles = Get-ChildItem -Path $commandConfigsDirPath | Where-Object { $PSItem.Extension -eq ".json" }

# Import all of the generated command configs into an array.
$commands = [System.Collections.Generic.List[pscustomobject]]::new()
foreach ($commandConfigItem in $commandConfigFiles) {
    $commands.Add((Get-Content -Path $commandConfigItem.FullName -Raw | ConvertFrom-Json))
}

# Generate the Crescendo module.
$crescendoModule = @{
    "`$schema" = "https://aka.ms/PowerShell/Crescendo/Schemas/2021-11";
    "Commands" = $commands;
}
$crescendoModule | ConvertTo-Json -Depth 10 | Out-File -FilePath $outFile