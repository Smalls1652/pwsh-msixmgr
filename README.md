# `msixmgr.exe` PowerShell wrapper

Wraps the [`msixmgr.exe` tool](https://docs.microsoft.com/en-us/azure/virtual-desktop/app-attach-msixmgr) as a PowerShell function using PowerShell Crescendo.

## Building

> ⚠️ **Note:** You will need to have the [`Microsoft.PowerShell.Crescendo` module](https://www.powershellgallery.com/packages/Microsoft.PowerShell.Crescendo) installed for PowerShell.

1. Launch a PowerShell console and navigate to the source code's directory.
2. Run `.\build.ps1`

The module output will be located in `out\pwsh-msixmgr\`.

## Using

> ⚠️ **Note:** You **will need** the [`msixmgr.exe` executable](https://docs.microsoft.com/en-us/azure/virtual-desktop/app-attach-msixmgr) reachable in your `PATH` environment variable. Unfortunately it is not provided as an installable tool, so you will either have to manually download it, extract it, and add the directory it's located in into your `PATH` environment variable.
>  
> If you want a fast and easy way to do this, you can run the script [`Install-MsixMgrTool.ps1`](tools/Install-MsixMgrTool.ps1) located in the `tools\` directory of this repo. You will want to run it like this:
>  
> ```powershell
> .\Install-MsixMgrTool.ps1 -AddToUserPathEnvironmentVariable
> ```
>  
> This will install `msixmgr.exe` to your user profile and add it to your user account's `PATH` environment variable.

### `New-MsixAppAttachVolume`

> ⚠️ **Note:** The PowerShell console will need to be elevated with admin permissions for it to work.

Create a MSIX App Attach volume to use for Azure Virtual Desktop session hosts.

#### Example 01

Create a MSIX app attach package.

```powershell
New-MsixAppAttachVolume -PackagePath "path\to\MyApp.msix" -DestinationPath "path\to\MyApp.vhd" -VhdSize 250 -FileType "VHD" -RootDirectoryName "app"
```
