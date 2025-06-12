function Get-Command-Directory {
	[CmdletBinding()]
	param (
		[Parameter(
			Mandatory=$true,
			Position=0,
			HelpMessage="the command name"
		)]
		[string] $Name
	)

	$source = $(Get-Command $Name).Source

	if (Test-Path $source) {
		$Path = Split-Path -Path $source | Resolve-Path
		return $Path
	}
	else {
		Write-Error "$name is not an application or script"
	}
}

function Import-Module-Check {
	[CmdletBinding()]
	param (
		[Parameter(
			Mandatory=$true,
			Position=0
		)]
		[string] $Module,
		[Parameter(
			Mandatory=$false
		)]
		[switch] $NoError = $true
	)
	if (Test-Path $Module) {
		Import-Module $Module
	} elseif (-not $NoError) {
		Write-Error "Warning: $Module does not exist"
	}
}

function Set-Light-Theme {
	[CmdletBinding()]
	param (
		[Parameter(
			Position=0
		)]
		[switch] $Dark = $false
	)

	$RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
	$Value   = 1

	if ($Dark) { $Value = 0 }

	# New-ItemProperty -Path $RegPath `
	# 	-Name SystemUsesLightTheme  `
	# 	-Type Dword -Value $Value   `
	# 	-Force

	New-ItemProperty -Path $RegPath `
		-Name AppsUseLightTheme     `
		-Type Dword -Value $Value   `
		-Force

}

function Set-MSVC-Env {
	$devshell = "$env:VS_ROOT\Common7\Tools\Launch-VsDevShell.ps1"
	if (-not $(Test-Path -PathType Leaf $devshell)) {
		Write-Error "$devshell does not exist"
		return
	}
	& $devshell
	$utf8 = [System.Text.Encoding]::GetEncoding("utf-8")
	[console]::InputEncoding  = $utf8
	[Console]::OutputEncoding = $utf8
	Write-Output "Set I/O encoding to UTF-8" $utf8
}

