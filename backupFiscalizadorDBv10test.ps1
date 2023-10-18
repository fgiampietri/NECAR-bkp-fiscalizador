#Requires -Version 5

<#
.SYNOPSIS
    BackupFiscalizador es una herramienta para hacer backup del Fiscalizador de Neural en CABA
.DESCRIPTION
	Genera un backup de las bases ANPR y NLOCHESTRATOR Truncadas y comprimidas
	Terminology:

		
		"Template"			An xls file that is saved in the database to be used for generating a new, infected file.


	Quick Start Guide:

		1) Run the backupFiscalizador.ps1 script. Se debe correr con permisos de Administrador
		

	Restrictions/Prereqs:
		- Luckystrike currently only makes .xls documents (97-2003 format).
		- Luckystrike requires PowerShell v5.
		- Luckystrike requires the PSSQLite module to be installed (install.ps1 handles this).

.PARAMETER Debug

	Spits out all the information to the screen.

.PARAMETER API

	Does not load menus. Allows for dot-sourcing of luckystrike and calling functions.

.NOTES
	CURRENTVERSION:			1.0

	Version History:		
							07/07/2023	1.0.0	Version Inicial para testing.
							
    Contributors: 			Federico giampietri @fedegiampietri

    Help Last Modified: 	07/07/2023
#>

[CmdletBinding()]
Param
(
	[string] $fiscalizador,
	[string] $SQLInstance,
	[bool]   $update
)

	##chequeo de parametros
	If($PSBoundParameters.ContainsKey("update")) {
		Write-Host "update exists"
		
	}
	else {
		Write-Host "udate not exists"
		$update = $true
	}

#Backup DATABASE Fiscalizador

$version = "1.0"
$requiredmodules = @('dbatools.library', 'dbatools','7-zip','PSFramework')
#$dbpath = "$($PWD.Path)\ls.db"
$githubver  = "https://raw.githubusercontent.com/fgiampietri/NECAR-bkp-fiscalizador/main/currentversion.txt"
$updatefile = "https://raw.githubusercontent.com/fgiampietri/NECAR-bkp-fiscalizador/main/update.ps1"

$date = Get-Date -format MMddyyyyHHmmss
#Install-Modules needed
try {
    if((Get-Module | Where-Object {$_.name -eq "dbatools.library"})) {Write-host " dbatools.library loaded"} else {Import-Module .\modules\dbatools.library\2023.5.5\dbatools.library.psm1}
    if((Get-Module | Where-Object {$_.name -eq "dbatools"}))         {Write-host " dbatools loaded"}         else {Import-Module .\modules\dbatools\dbatools.psm1}
    if((Get-Module | Where-Object {$_.name -eq "7-zip"}))            {Write-host " 7-zip loaded"}            else {Import-Module .\modules\7-zip\7-zip.psm1}
    if((Get-Module | Where-Object {$_.name -eq "PSFramework"}))      {Write-host " PSFramework loaded"}      else {Import-Module .\modules\PSFramework\1.8.291\PSFramework.psm1}
    Write-PSFMessage -Level Debug -Message "modules Loaded Sucessfully !" 
} catch {
	Write-PSFMessage -Level Debug -Message "Error loading modules !" }


## import-module .\modules\dbatools
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true
Set-DbatoolsConfig -FullName sql.connection.encrypt   -Value $false

## Load Global Config

## Log Provider Settings
$paramSetPSFLoggingProvider = @{
    Name          = 'logfile'
    InstanceName  = 'BackupFiscalizador'
    FilePath      = 'C:\FiscalizadorBkp\logs\BackupFiscalizador-%Date%.log'
    Enabled       = $true
    LogRotatePath = 'C:\FiscalizadorBkp\logs\TBackupFiscalizador-*.log'
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider
# Base Directory
# This must match with the UpdateService/LocalePath entry ($Config.UpdateService.LocalePath)
# in the JSON configuration file if you want to use the automated update/Distribution features!
$global:BaseDirectory = "C:\FiscalizadorBkp\"

# JSON configuration filename to use
$global:BaseConfig = "config.json"

# Load and parse the JSON configuration file
try {
	$global:Config = Get-Content "$BaseDirectory$BaseConfig" -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue | ConvertFrom-Json -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
} catch {
	Write-PSFMessage -Level Debug -Message "The Base configuration file is missing!" }

# Check the configuration
if (!($Config)) {
    Write-PSFMessage -Level Debug -Message "The Base configuration file is missing!" 
}
## Functions
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
		Write-PSFMessage -Level Debug -Message $_ 
	}
	
	Write-PSFMessage -Level Debug -Message "CURRENT VERSION: $version"
	Write-PSFMessage -Level Debug -Message "NEXT VERSION:    $nextversion "
	if (($null -ne $nextversion)  -and ($version -ne $nextversion))
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
			#Write-PSFMessage -Level Debug -Message "Update available. Do you want to update ? Your payloads/templates will be preserved success"
			Write-PSFMessage -Level Debug -Message "Actualizando"
			<#  $response = Read-Host "`nPlease select Y or N"
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
			#>

				try {
					(New-Object System.Net.Webclient).DownloadFile($updatefile, $updatepath)
					Start-Process PowerShell -Arg $updatepath
					exit
					
				}
				catch {
					Write-PSFMessage -Level Debug -Message "Falló Actulizacion"
				}	
		}
	}
	else
	{
		Write-PSFMessage -Level Debug -Message "Unable to check for updates. Internet connection not available." 
	}
}


function backup_Fiscalizador {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    PROCESS {
        foreach ($Computer in $ComputerName) {
            try {
                Test-WSMan -ComputerName $Computer
            }
            catch {
                Write-Warning -Message "Unable to connect to Computer: $Computer"
            }
        }
    }

}

<#
	Now we read the JSON File and use it
#>
# Internal Version information (For future use)
$global:ConfigVersion = ($Config.basic.ConfigVersion)

# Customer Info (For future use)
$global:Company = ($Config.basic.Customer)

# Environment (Production, Leaduser, Testing, Development)
$global:environment = ($Config.basic.environment)

<#
	Any further Script here
#>


    $bkpLocalDirNecar 			= $Config.NECAR.bkpLocalDirNecar

<#   $bkpLocalDirNecarcompressed = "C:\FiscalizadorBkp\backupcompressed\"
    $bkpFinalLocalDirNecar 		= "C:\FiscalizadorBkp\backup\"
    $bkpRemoteShareNECAR 		= "\\nas-01\Data\backups\Fiscalizadores\"
    $InstanciaSQLSFicalizador 	= "LOCALHOST"
    $NeuralDBName 			 	= "ANPR"
    $NeuralOrchestratorDBName 	= "NLORCHESTRATOR"
    $NeuralStageDBName 			= "ANPR_Stage"
    $NeuralStageDBNameDIR       = "C:\FiscalizadorBkp\sqldata"
    $modulestoload              = "dbatools dbatools.library PSFramework 7-zip"
#>

Write-host $bkpLocalDirNecar


# Verbose
#Write-PSFMessage -Message "Test Message"
# Host
#Write-PSFMessage -Level Host -Message "Message visible to the user"
# Debug
#Write-PSFMessage -Level Debug -Message "Very well hidden message"
# Warning
#Write-PSFMessage -Level Warning -Message "Warning Message"

 
if ($update)
{
	Write-host "Actualizando"
	Process-Updates
	
}
else{
	Write-host "no actualizar , corro con la version actual"
}