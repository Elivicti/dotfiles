Import-Module "$PSScriptRoot\sources\helper-functions.ps1"

Import-Module-Check "$env:VCPKG_ROOT\scripts\posh-vcpkg"

# set ctrl+d exit pwsh
Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function DeleteCharOrExit


$NVIM      = "~\AppData\Local\nvim"
$NVIM_DATA = "~\AppData\Local\nvim-data"

# Note: switch to starship at somepoint
# starship currently lacks support for conditional prompt parts
$theme_manager = "starship"
Import-Module "$PSScriptRoot\themes\$theme_manager\setup.ps1"
