$POSH_HOME = "$env:LOCALAPPDATA\Programs\oh-my-posh"
$posh = "$POSH_HOME\bin\oh-my-posh.exe"

function Get-Random-Posh-Theme {
	[CmdletBinding()]
	param (
		[Parameter()]
		[switch] $PlainPath = $false
	)

	$all_themes = Get-ChildItem -Path $env:POSH_THEMES_PATH -File
	$theme = $all_themes | Get-Random
	if ($PlainPath) {
		Write-Output $theme.FullName
	}
	else {
		Write-Output $theme
	}
}

$POSH_MODULE_CACHE = "$PSScriptRoot\Cached-Oh-My-Posh.psm1"

$MY_POSH_THEME = $env:POSH_THEME
$DEFAULT_POSH_THEME = "pwsh.omp.json"

# set to default value if not valid
if (-not ($MY_POSH_THEME -and $(Test-Path -PathType Leaf $MY_POSH_THEME))) {
	$MY_POSH_THEME = "$PSScriptRoot\$DEFAULT_POSH_THEME"
}

function Update-Posh-Cache {
	[CmdletBinding()]
	param (
		[Parameter(
			Mandatory=$false,
			Position=0,
			HelpMessage="Path to oh-my-posh theme."
		)]
		[string] $Theme
	)
	if ($Theme) {
		[System.IO.FileInfo] $theme_file = $Theme

		if (($theme_file.Exists) -and ($theme_file.Attributes.HasFlag([System.IO.FileAttributes]::Archive))) {
			$MY_POSH_THEME = $theme_file.FullName
		}
		else {
			Write-Error "$($theme_file.FullName) is not a file, defaulting to $DEFAULT_POSH_THEME"
			$MY_POSH_THEME = "$PSScriptRoot\$DEFAULT_POSH_THEME"
		}
	}

	$posh_init = & $posh --init --shell pwsh --config "$MY_POSH_THEME"
	$module_cmd = $posh_init.Split('|')[0].Trim()
	Invoke-Expression $module_cmd | Out-File $POSH_MODULE_CACHE
}

if (-not $(Test-Path -PathType Leaf $POSH_MODULE_CACHE)) {
	Update-Posh-Cache $MY_POSH_THEME
}

# Caching the module code to speed up powershell startup time
$posh_module = Import-Module $POSH_MODULE_CACHE -PassThru -Force

