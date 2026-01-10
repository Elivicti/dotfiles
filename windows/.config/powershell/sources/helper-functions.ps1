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

function Set-CodePage {
	[CmdletBinding()]
	param (
		[Parameter(
			Position=0
		)]
		[string] $Encoding
	)
	$codepage = [System.Text.Encoding]::GetEncoding($Encoding);
	$name = $codepage.EncodingName

	[Console]::InputEncoding  = $codepage
	[Console]::OutputEncoding = $codepage

	Write-Output "Set I/O encoding to $name" $codepage
}

function Set-MSVC-Env {
	[CmdletBinding()]
	param (
		[Parameter()]
		[switch] $Utf8 = $false
	)

	$devshell = "$env:VS_ROOT\Common7\Tools\Launch-VsDevShell.ps1"
	if (-not $(Test-Path -PathType Leaf $devshell)) {
		Write-Error "$devshell does not exist"
		return
	}
	& $devshell -Arch amd64 -HostArch amd64 -SkipAutomaticLocation

	if ($Utf8) {
		Set-CodePage "utf-8"
	}
}

function Sync-GitRepo {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Path,
		[Parameter()]
		[switch] $Quiet,

		[Parameter()]
		[switch] $Fetch,
		[Parameter()]
		[switch] $NoPull,
		[Parameter()]
		[switch] $Status
	)

	if (-not $(Test-Path -PathType Container $Path)) {
		Write-Error "${Path}: path is not a directory"
		return
	}

	if (-not $Quiet) { Write-Output "[INFO] Directory: $Path" }

	if ($Fetch) {
		if (-not $Quiet) { Write-Output "[INFO] Running: git fetch" }
		pwsh -WorkingDirectory "$Path" -NoProfile -c "git fetch"

		if ($LASTEXITCODE -ne 0) { return; }
	}

	if (-not $NoPull) {
		if (-not $Quiet) { Write-Output "[INFO] Running: git pull" }
		pwsh -WorkingDirectory "$Path" -NoProfile -c "git pull"
	}

	if ($Status) {
		if (-not $Quiet) { Write-Output "[INFO] Running: git status" }
		pwsh -WorkingDirectory "$Path" -NoProfile -c "git status"
	}
}

function vcpkg-update {
	param (
		[Parameter()]
		[switch] $NoPull
	)
	$vcpkg_root = $(Get-Command-Directory vcpkg).Path
	Sync-GitRepo $vcpkg_root -Fetch -Status -NoPull:$NoPull
}

function Make-Hidden {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
		[string[]] $Paths
	)

	foreach ($path in $Paths) {
		$item = Get-Item "$path" -ErrorAction Stop
		$attr = $item.Attributes -bor [System.IO.FileAttributes]::System -bor [System.IO.FileAttributes]::Hidden
		$item.Attributes = $attr

		Write-Output "$path"
	}
}
function Make-Shown {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
		[string[]] $Paths
	)

	foreach ($path in $Paths) {
		$item = Get-Item "$path" -ErrorAction Stop
		$attr = [System.IO.FileAttributes]::System -bor [System.IO.FileAttributes]::Hidden
		$item.Attributes = $item.Attributes -band (-bnot $attr)

		Write-Output "$path"
	}
}
