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

function Get-CodePage {
    [CmdletBinding()]
    param()

	$items = [ordered]@{
		Input  = [Console]::InputEncoding
		Output = [Console]::OutputEncoding
	}

	foreach ($kv in $items.GetEnumerator()) {
		[PSCustomObject]@{
			Type     = $kv.Key
			Name     = $kv.Value.EncodingName
			WebName  = $kv.Value.WebName
			Encoding = $kv.Value
		}
	}
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

function Find-MSVC-Instance {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false)]
		[string] $InstallerRoot = "${env:PROGRAMFILES(X86)}\Microsoft Visual Studio\Installer",

		[Parameter(Mandatory=$false)]
		[string] $InstanceId,

		[Parameter()]
		[switch] $FullOutput = $false
	)

	$vswhere = "$InstallerRoot\vswhere.exe"
	$vswhere_exist = Test-Path -LiteralPath "$vswhere" -PathType Leaf

	if (-not $vswhere_exist) {
		throw [System.IO.FileNotFoundException]::new("Unable to find 'vswhere.exe' under '$InstallerRoot'")
	}

	$vswhere_args = @("-format", "json", "-nocolor", "-nologo")
	if ($InstanceId -ieq "latest") {
		$vswhere_args += "-latest"
	}

	$json = & "$vswhere" @vswhere_args | ConvertFrom-Json

	if (-not $json) {
		throw "No Visual Studio instances found."
	}

	if ($InstanceId -and $InstanceId -ine "latest") {
		$json = $json | Where-Object { $_.instanceId -eq $InstanceId }
		if (-not $json) {
			throw "Visual Studio instance with InstanceId '$InstanceId' not found."
		}
	}

	if (-not $FullOutput) {
		$json = $json | ForEach-Object {
			[PSCustomObject]@{
				InstanceId       = $_.instanceId
				DisplayName      = $_.displayName
				Description      = $_.description
				InstallationPath = $_.installationPath
			}
		}
	}

	return $json
}

function Set-MSVC-Env {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false)]
		[string] $InstanceId
	)

	$devshellScript = "Common7\Tools\Launch-VsDevShell.ps1"
	$vs_root = $null

	function Test-VSRoot {
		param([string]$Path)
		if ($Path) {
			$devshell = Join-Path $Path $devshellScript
			if (Test-Path -LiteralPath $devshell -PathType Leaf) {
				return $true
			}
		}
		return $false
	}

	# Step 1: Try InstanceId if specified
	if ($InstanceId) {
		$instance = Find-MSVC-Instance -InstanceId $InstanceId -ErrorAction SilentlyContinue
		if ($instance) {
			$vs_root = $instance.InstallationPath
		}
		else {
			Write-Host "ERROR: Invalid instance id '$InstanceId', falling back to env:VS_ROOT." -ForegroundColor Red
		}
	}

	# Step 2: Fallback to VS_ROOT
	if (-not $vs_root -and $env:VS_ROOT) {
		if (Test-VSRoot $env:VS_ROOT) {
			$vs_root = $env:VS_ROOT
		}
		else {
			Write-Host "ERROR: Invalid env:VS_ROOT '$env:VS_ROOT', falling back to latest." -ForegroundColor Red
		}
	}

	# Step 3: Fallback to latest
	if (-not $vs_root) {
		$instance = Find-MSVC-Instance -InstanceId "latest" -ErrorAction SilentlyContinue
		if ($instance) {
			$vs_root = $instance.InstallationPath
		}
	}

	if (-not $vs_root -or -not (Test-VSRoot $vs_root)) {
		throw "Unable to locate Visual Studio installation."
	}

	$devshell = Join-Path $vs_root $devshellScript
	& $devshell -Arch amd64 -HostArch amd64 -SkipAutomaticLocation
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
