[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [switch]$DoNotBuildCommandConfigs
)

$srcPath = Join-Path -Path $PSScriptRoot -ChildPath "src\pwsh-msixmgr\"
$createModuleScript = Join-Path -Path $srcPath -ChildPath "createModuleConfig.ps1"
$moduleConfigPath = Join-Path -Path $srcPath -ChildPath "module-config\module.json"

$outDirPath = Join-Path -Path $PSScriptRoot -ChildPath "out"
$moduleOutDirPath = Join-Path -Path $outDirPath -ChildPath "pwsh-msixmgr"

. "$($createModuleScript)" -DoNotBuildCommandConfigs:$DoNotBuildCommandConfigs

if (Test-Path -Path $outDirPath) {
    Remove-Item -Path $outDirPath -Recurse -Force
}
$null = New-Item -Path $outDirPath -ItemType "Directory"
$null = New-Item -Path $moduleOutDirPath -ItemType "Directory"

Write-Verbose "Creating module"
Push-Location -Path $moduleOutDirPath
Export-CrescendoModule -ModuleName "pwsh-msixmgr" -ConfigurationFile $moduleConfigPath -Force
Pop-Location