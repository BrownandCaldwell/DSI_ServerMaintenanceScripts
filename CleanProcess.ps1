. ".\Get-UserSessions.ps1"
$procName = $args[0]
$sleepMins = 1
$hostName = hostname
#$hostName = $env:COMPUTERNAME
$logFile = $procName + "_on_" + ($hostName -replace "\\", "_") + ".log"
Start-Transcript -Append -Path $logFile

$userState=$args[1]
if ($userState.ToLower() -like "any") {$userState = "Disc;Active"}
$action = $args[2]
$message = $args[3] 

$rdpSessions = Get-UserSessions
$procSessions = Get-Process -IncludeUsername $procName
$idleSessions = @()

foreach($i in $procSessions ) {
    $cleanName = $i.UserName.Replace("BC\","")
    $proc = $i.Id
	Write-Host ($userState.ToLower()) ($rdpSessions[$cleanName].STATE.ToLower())
    if ($userState.ToLower().Contains($rdpSessions[$cleanName].STATE.ToLower())) {
        Write-Output $cleanName $i.Id
        $idleSessions += $proc

        if ($action.ToLower().Contains("notify")) {
            Send-MailMessage -To ($cleanName + "@brwncald.com") -From "-csomerlot@brwncald.com"  -Subject "You left $procName running on $hostname" -Body $message -SmtpServer "smtp.brwncald.com"
            Write-Host "Sent email to $cleanName@brwncald.com: You left $procName running on $hostName (process $proc). $message" 
        }
    }
}

if ($action.ToLower().Contains("kill")) {
    if ($action.ToLower().Contains("wait")) {
        Start-Sleep -s (60 * $sleepMins)
    }
    foreach($i in $idleSessions){
        Write-Host "    Killing process $i"
        Stop-Process -ID $i -Force -ErrorVariable err -ErrorAction SilentlyContinue
    }
}

Stop-Transcript
