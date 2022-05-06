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
try {
    $procSessions = Get-Process -IncludeUsername $procName -ErrorAction Stop
}
catch {
    Write-Host "No instances running"
    exit
}
$idleSessions = @()

$whitelist = $null
if (Test-Path -Path .\whitelist.json -PathType leaf) {
    $whitelist = @{}
    $jsonObj = Get-Content -Raw -Path whitelist.json | ConvertFrom-Json
    foreach($property in $jsonObj.PSObject.Properties) {
        $whitelist[$property.Name] = $property.Value
    }
}


foreach($i in $procSessions ) {
    $cleanName = $i.UserName.Replace("BC\","").ToLower()
    if ($whitelist -ne $null) {
        if ($whitelist.ContainsKey($cleanName)) {
            if ($whitelist[$cleanName].Contains($procName) ) {
                Write-Host "Skipping this for" $cleanName
                continue
            }
        }
    }
    $proc = $i.Id
	#Write-Host ($userState.ToLower()) ($rdpSessions[$cleanName].STATE.ToLower())
    if ($userState.ToLower().Contains($rdpSessions[$cleanName].STATE.ToLower())) {
        #Write-Output $cleanName $i.Id
        $idleSessions += $proc

        if ($action.ToLower().Contains("notify")) {
            Send-MailMessage -To ($cleanName + "@brwncald.com") -From "noreply@brwncald.com"  -Subject "You left $procName running on $hostname (process $proc)" -BodyAsHtml $message -SmtpServer "smtp.brwncald.com"
            Write-Host "Sent email to $cleanName@brwncald.com: You left $procName running on $hostName (process $proc)." 
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
