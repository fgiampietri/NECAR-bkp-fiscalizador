$currentdb = "$($PWD.Path)\ls.db"
$bakdb = "$($PWD.Path)\ls.db.bak"
$tmpdb = "$($PWD.Path)\ls.tmp.db"

# Give luckystrike a sec to close & release handles.
Write-Output "[*] Sleeping 3 seconds"
Start-Sleep -Seconds 3

Write-Output "[*] Done!"
Write-Output "`nUpdates in 2.0 - Word support "
Read-Host "`nPress any key to continue. If errors, grab a screenshot and submit an issue with the debug log on github, otherwise run the new version of Backup Fiscalizador. !
