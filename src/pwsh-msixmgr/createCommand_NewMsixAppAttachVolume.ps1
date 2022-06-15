[CmdletBinding()]
param()

# Import the 'ParamInfoItem' class.
$paramInfoItemClassPath = Join-Path -Path $PSScriptRoot -ChildPath "class_ParamInfoItem.ps1"
. "$($paramInfoItemClassPath)"

Write-Verbose "Creating command config for 'New-MsixAppAttachVolume'"

$configFileOutPath = Join-Path -Path $PSScriptRoot -ChildPath "command-configs\New-MsixAppAttachVolume.crescendo.json"

# Define the parameters needed.
$paramsToAdd = @(
    [ParamInfoItem]::new("PackagePath", "-packagePath", "string", "The path to the MSIX package."),
    [ParamInfoItem]::new("DestinationPath", "-destination", "string", "The output file path."),
    [ParamInfoItem]::new("VhdSizeInMB", "-vhdSize", "int", "The size of the VHD file in MB."),
    [ParamInfoItem]::new("OutputFileType", "-filetype", "string", "The type the output file should be in (VHD, VHDX, or CIM).", "VHD"),
    [ParamInfoItem]::new("RootDirectoryName", "-rootDirectory", "string", "The root directory name to use in the output file (Does not need to be anything specific).", "app")
)

# Create the Crescendo Command object.
$msixmgrCommand = New-CrescendoCommand -Verb "New" -Noun "MsixAppAttachVolume" -OriginalName "msixmgr.exe"

# Set the platform to only Windows, since 'msixmgr' is only available on Windows.
$msixmgrCommand.Platform = @("Windows")

# Set the description.
$msixmgrCommand.Description = "Create a MSIX app attach volume from a MSIX package to use with Azure Virtual Desktop."

# Set the parameters that are required to run the function properly.
$msixmgrCommand.OriginalCommandElements = @(
    "-Unpack"
    "-applyAcls",
    "-create"
)

# Add each parameter option.
$i = 0
foreach ($paramItem in $paramsToAdd) {
    # Create the parameter object from the supplied parameter info.
    $paramObj = New-ParameterInfo -Name $paramItem.Name -OriginalName $paramItem.OriginalName
    $paramObj.ParameterType = $paramItem.ParameterType
    $paramObj.Position = $i
    $paramObj.Description = $paramItem.Description

    # If it has a default value, set it in the object.
    if ($null -ne $paramItem.DefaultValue) {
        $paramObj.DefaultValue = $paramItem.DefaultValue
    }

    # Add to the command's parameters property.
    $msixmgrCommand.Parameters.Add($paramObj)

    $i++
}

# Add '[ValidateSet()]' decorator to the '-OutputFileType' parameter.
# Should probably do this differently...
($msixmgrCommand.Parameters | Where-Object { $PSItem.Name -eq "OutputFileType" })[0].AdditionalParameterAttributes = @("[ValidateSet(`"VHD`", `"VHDX`", `"CIM`")]")

# Had to disable this method of exporting the command, as it broke the 'Export-CrescendoModule' command.
#Export-CrescendoCommand -command $msixmgrCommand -targetDirectory $configFileOutPath

# Export the command config.
$msixmgrCommand | ConvertTo-Json -Depth 10 | Out-File -FilePath $configFileOutPath