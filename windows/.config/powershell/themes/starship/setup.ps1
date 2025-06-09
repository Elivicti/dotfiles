
# NOTE: https://github.com/starship/starship

$ENV:STARSHIP_CONFIG = "$PSScriptRoot\configs.toml"
Invoke-Expression (&starship init powershell)
