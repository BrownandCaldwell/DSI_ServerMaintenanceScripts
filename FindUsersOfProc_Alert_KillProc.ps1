. ".\Get-UserSessions.ps1"
$procName = $args[0]

$message = "This is an automated email. Our script noticed that you left $procname open on $hostname and are disconnected. In 55 minutes, this process will be manually-automatically terminated. 

If you are trying to run something long-term, ask to be added to the exception white-list."

$rdpSessions = Get-UserSessions
$procSessions = Get-Process -IncludeUsername $procName
$idleSessions = @()

foreach($i in $procSessions ) {
    $cleanName = $i.UserName.Replace("BC\","")
    
    if ($rdpSessions[$cleanName].STATE -like 'Disc') {
        Write-Output $cleanName $i.Id
        
        Send-MailMessage -To ($cleanName + "@brwncald.com") -From "s-arcgis@brwncald.com"  -Subject "You left $procName running on $hostname" -Body $message -Credential (Get-Credential) -SmtpServer "smtp.brwncald.com" -Port 587
        $idleSessions += $i.Id
    }
}

Start-Sleep -s 60

foreach($i in $idleSessions){
    Stop-Process -ID $i -Force -ErrorVariable err -ErrorAction SilentlyContinue
}