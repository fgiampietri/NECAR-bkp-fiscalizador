$currentdb = "$($PWD.Path)\ls.db"
$bakdb = "$($PWD.Path)\ls.db.bak"
$tmpdb = "$($PWD.Path)\ls.tmp.db"
        $updatepathscript = "$($PWD.Path)\backupFiscalizadorDBv10test.ps1"
        $updatedscript    = "https://raw.githubusercontent.com/fgiampietri/NECAR-bkp-fiscalizador/main/backupFiscalizadorDBv10test.ps1"
        try {
            (New-Object System.Net.Webclient).DownloadFile($updatedscript, $updatepathscript)
           # Start-Process PowerShell -Arg $updatepathscript
            exit
            
        }
        catch {
            Write-PSFMessage -Level Debug -Message "Falló Actulizacion"
        }


        # Give luckystrike a sec to close & release handles.
Write-Output "[*] Sleeping 3 seconds"
Start-Sleep -Seconds 3

Write-Output "[*] Done!"
Write-Output "`nUpdates in 2.0 - Word support "
Read-Host "`nPress any key to continue. If errors, grab a screenshot and submit an issue with the debug log on github, otherwise run the new version of Backup Fiscalizador. !"
