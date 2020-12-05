. ".\Get-UserSessions.ps1"

$message = "This is an automated email. Our script noticed that you left ArcMap open on AZR-GISTS01 and are disconnected. In 55 minutes, this process will be manually-automatically terminated. 

If you are trying to run something long-term, try switching to using Pro, or ask to be added to the exception white-list."

$rdpSessions = Get-UserSessions
$arcmapSessions = Get-Process -IncludeUsername arcmap
$idleSessions = @()

foreach($i in $arcmapSessions ) {
    $cleanName = $i.UserName.Replace("BC\","")
    
    if ($rdpSessions[$cleanName].STATE -like 'Disc') {
        Write-Output $cleanName $i.Id
        
        Send-MailMessage -To ($cleanName + "@brwncald.com") -From "csomerlot@brwncald.com"  -Subject "You left GIS running on AZR-GISTS01" -Body $message -Credential (Get-Credential) -SmtpServer "smtp.brwncald.com" -Port 587
        $idleSessions += $i.Id
    }
}

Start-Sleep -s 60

foreach($i in $idleSessions){
    Stop-Process -ID $i -Force -ErrorVariable err -ErrorAction SilentlyContinue
}