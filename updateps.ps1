function UpdatesAvailable()
{
	$updateavailable = $false
	$nextversion = $null
	try
	{
		$nextversion = (New-Object System.Net.WebClient).DownloadString($githubver).Trim([Environment]::NewLine)
	}
	catch [System.Exception] 
	{
		Write-Message $_ "debug"
	}
	
	Write-Message "CURRENT VERSION: $version" "debug"
	Write-Message "NEXT VERSION: $nextversion" "debug"
	if ($nextversion -ne $null -and $version -ne $nextversion)
	{
		#An update is most likely available, but make sure
		$updateavailable = $false
		$curr = $version.Split('.')
		$next = $nextversion.Split('.')
		for($i=0; $i -le ($curr.Count -1); $i++)
		{
			if ([int]$next[$i] -gt [int]$curr[$i])
			{
				$updateavailable = $true
				break
			}
		}
	}
	return $updateavailable
}

function Process-Updates()
{
	if (Test-Connection 8.8.8.8 -Count 1 -Quiet)
	{
		$updatepath = "$($PWD.Path)\update.ps1"
		if (Test-Path -Path $updatepath)	
		{
			#Remove-Item $updatepath
		}
		if (UpdatesAvailable)
		{
			Write-Message "Update available. Do you want to update luckystrike? Your payloads/templates will be preserved." "success"
			$response = Read-Host "`nPlease select Y or N"
			while (($response -match "[YyNn]") -eq $false)
			{
				$response = Read-Host "This is a binary situation. Y or N please."
			}

			if ($response -match "[Yy]")
			{	
				(New-Object System.Net.Webclient).DownloadFile($updatefile, $updatepath)
				Start-Process PowerShell -Arg $updatepath
				exit
			}
		}
	}
	else
	{
		Write-Message "Unable to check for updates. Internet connection not available." "warning"
	}
}
