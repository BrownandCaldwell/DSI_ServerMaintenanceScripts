. ".\Get-UserSessions.ps1"

$rdpSessions = Get-UserSessions
$arcmapSessions = Get-Process -IncludeUsername arcmap
$idleSessions = @{}

foreach($i in $arcmapSessions ) {
    $cleanName = $i.UserName.Replace("BC\","")
    
    if (-not $idleSessions.ContainsKey($cleanName)) {
        $idleSessions[$cleanName] = @{rdpInfo = $rdpSessions[$cleanName]; arcmapProc = @{}}
    }
    $idleSessions[$cleanName]["arcmapProc"][$i.Id] = $i.CPU
    
}

Start-Sleep -s 6

Write-Output $idleSessions.Count
foreach($i in $idleSessions.Keys){
    $sessionIsActive = $false
    Write-Output $i 
    #Write-Output $idleSessions[$i]
    #Write-Output $idleSessions[$i]["arcmapProc"]
    foreach($Id in $idleSessions[$i]["arcmapProc"].Keys) {
        $result = Get-Process -ID $Id
        $oldCPU = $idleSessions[$i]["arcmapProc"][$Id]
        if (($result -notlike $null) -and ($result.CPU - $oldCPU -gt 0)) {
            $sessionIsActive = $true
        }
    }
    
    
    if (-not $sessionIsActive) {
        Write-Output "Shutting down" $i 
        tsdiscon $idleSessions[$i]["rdpInfo"].ID
    }
}
