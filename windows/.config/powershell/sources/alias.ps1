
function Open-WithYazi {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$YaziArgs
	)

	try {
		Get-Command yazi -ErrorAction Stop > $null
	}
	catch {
		Write-Error $_.Exception.Message
		return
	}

	$tmp = (New-TemporaryFile).FullName
	yazi $YaziArgs --cwd-file="$tmp"
	$cwd = Get-Content -Path $tmp -Encoding UTF8
	if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
		Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
	}
	Remove-Item -Path $tmp
}

Set-Alias -Name yz -Value Open-WithYazi
