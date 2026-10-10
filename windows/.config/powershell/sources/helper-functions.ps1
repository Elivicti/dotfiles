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

function Open-WithExplorer {
	<#
	.SYNOPSIS
		Opens a path in Windows Explorer (explorer.exe).

	.DESCRIPTION
		Behavior:
		  - A [file]        -> Opens its containing folder and selects the file (-Select is ignored).
		  - A [directory]   -> Opens the directory directly by default.
		  - A [directory] + -Select -> Opens the parent folder and selects the directory.
		  - A missing path  -> Writes an error and does NOT launch explorer.
		  - Supports: relative paths, UNC paths, environment variables, shell: namespace,
					  file:// URIs, pipeline input, and empty path (current directory).

	.PARAMETER Path
		The path to open. Accepts pipeline input.

	.PARAMETER Select
		Only meaningful for directories. When set, opens the parent folder and selects
		the directory instead of opening it. Ignored for files (files are always selected).

	.PARAMETER PassThru
		Returns the argument(s) actually passed to explorer.exe. Useful for debugging.

	.EXAMPLE
		Open-WithExplorer .
		Open-WithExplorer "$env:USERPROFILE\Desktop"
		Open-WithExplorer "C:\Windows" -Select         # select Windows inside C:\
		Open-WithExplorer "C:\Windows\notepad.exe"     # select notepad.exe
		Open-WithExplorer "shell:MyComputer"
		Open-WithExplorer "\\server\share\folder"
		Open-WithExplorer "C:\path\does\not\exist"     # errors out, no explorer
	#>
	[CmdletBinding()]
	[OutputType([void], [string])]
	param(
		[Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[Alias('FullName', 'LiteralPath', 'PSPath')]
		[string] $Path,

		[switch] $Select,

		[switch] $PassThru
	)

	process {
		$arg    = $null   # path handed to explorer.exe
		$isFile = $false

		if ([string]::IsNullOrWhiteSpace($Path) -or $Path -eq '.' -or $Path -eq '.\') {
			# Empty or "." means current directory.
			$arg = (Get-Location).ProviderPath
		}
		elseif ($Path -match '^shell:') {
			# shell: namespace (e.g. shell:MyComputer). Test-Path is unreliable here,
			# so skip the existence check and pass it through as-is.
			$arg = $Path
		}
		elseif ($Path -match '^file://') {
			# Convert file:// URI to a local path, then validate.
			try {
				$localPath = ([uri]$Path).LocalPath
			}
			catch {
				Write-Error "Cannot parse file URI: $Path"
				return
			}
			if (-not (Test-Path -LiteralPath $localPath)) {
				Write-Error "Path does not exist: $Path"
				return
			}
			$arg = $localPath
		}
		else {
			# Expand %VAR% style environment variables.
			$expanded = [Environment]::ExpandEnvironmentVariables($Path)

			# Bail out early if the path does not exist; do not launch explorer.
			if (-not (Test-Path -LiteralPath $expanded)) {
				Write-Error "Path does not exist: $Path"
				return
			}

			# -LiteralPath avoids wildcard interpretation of characters like [ ].
			$resolved = Resolve-Path -LiteralPath $expanded -ErrorAction Stop

			if ($resolved.Provider.Name -ne 'FileSystem') {
				# Non-filesystem provider (e.g. registry). Use PSPath.
				$arg = $resolved.PSPath
			}
			else {
				$arg    = $resolved.ProviderPath
				$isFile = (Get-Item -LiteralPath $arg -ErrorAction Stop).PSIsContainer -eq $false
			}
		}

		# The shell: namespace does not accept /select.
		$needSelect = $false
		if ($arg -notmatch '^shell:') {
			if ($isFile) {
				# File -> always select; -Select is ignored.
				$needSelect = $true
			}
			elseif ($Select) {
				# Directory + -Select -> select inside the parent folder.
				$needSelect = $true
			}
			# Directory without -Select -> open it directly.
		}

		if ($needSelect) {
			# /select, and the path must be glued into one argument; quoting is handled here.
			$arguments = "/select,`"$arg`""
			if ($PassThru) { $arguments }
			Start-Process -FilePath 'explorer.exe' -ArgumentList $arguments -ErrorAction Stop
		}
		else {
			if ($PassThru) { $arg }
			Start-Process -FilePath 'explorer.exe' -ArgumentList $arg -ErrorAction Stop
		}
	}
}
