. ".\Get-UserSessions.ps1"
$procName = $args[0]
$sleepMins = 0
$hostName = hostname
#$hostName = $env:COMPUTERNAME
$logFile = "Kill_" + $procName + "_on_" + ($hostName -replace "\\", "_") + ".log"
Start-Transcript -Append -Path $logFile

$message = "This is an automated email. Our script noticed that you left $procname open on $hostname and are disconnected. In $sleepMins minutes, this process will be manually-automatically terminated. 

If you are trying to run something long-term, ask to be added to the exception white-list."

$rdpSessions = Get-UserSessions
$procSessions = Get-Process -IncludeUsername $procName
$idleSessions = @()

foreach($i in $procSessions ) {
    $cleanName = $i.UserName.Replace("BC\","")
    $proc = $i.Id
    #if ($rdpSessions[$cleanName].STATE -like 'Disc') {
    #    Write-Output $cleanName $i.Id
        
        #Send-MailMessage -To ($cleanName + "@brwncald.com") -From "noreply@brwncald.com"  -Subject "You left $procName running on $hostname" -Body $message -Credential (Get-Credential) -SmtpServer "smtp.brwncald.com" -Port 587
        Write-Host "Sent email to $cleanName@brwncald.com: You left $procName running on $hostName (process $proc)." 
        $idleSessions += $proc
    #}
}

Start-Sleep -s (60 * $sleepMins)

foreach($i in $idleSessions){
    Write-Host "    Killing process $i"
    Stop-Process -ID $i -Force -ErrorVariable err -ErrorAction SilentlyContinue
}

Stop-Transcript