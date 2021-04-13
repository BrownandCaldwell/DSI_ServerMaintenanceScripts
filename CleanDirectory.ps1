$dirToCLean = $args[0].ToString()
$age  = -$args[1] # in days
$sizeLimit = $args[2] # in GB
$action = $args[3]
$message = $args[4]
$size  = 0
$limit = (Get-Date).AddDays($age)

$hostName = hostname
$logFile = "Clean out" + $dirToCLean + "_on_" + ($hostName -replace "\\", "_") + ".log"
Start-Transcript -Append -Path $logFile

function CleanPath($path, $notifyList){
    $size = (Get-ChildItem $path -Recurse -File | Measure-Object -Property Length -Sum -ErrorAction Continue).Sum/1000000000
    
    if ($size -gt $sizeLimit) {
        Write-Host $size "GB in" $path
        if ($action.ToLower().Contains("delete")) {
            Write-Host "  Deleting content from" $path
            $files = Get-ChildItem -Path $path -Recurse -File | Where-Object { ($_.LastWriteTime -lt $limit) } 
            foreach ($file in $files) {
                Write-Host "    Deleting" $file
                Remove-Item $file.FullName -Force -Recurse -ErrorAction Continue
            }
        }
        if ($action.ToLower().Contains("notify")) { 
            Write-Host "Sending email to $($_.Name)@brwncald.com: $message, action: $action"
            Send-MailMessage -To  -From "noreply@brwncald.com"  -Subject "Folder $path on $hostname has grown too large, action taken: $action" -Body $message -Credential (Get-Credential) -SmtpServer "smtp.brwncald.com"
        }
    }
}

if ($dirToCLean.ToLower().StartsWith("userprofile")) {
    $Users = Get-ChildItem C:\Users
    $Users | ForEach-Object {
        $path = Join-Path C:\Users $dirToClean.Replace("userprofile","$_")
        
        if (Test-Path -Path $path) {
            CleanPath $path ($_.Name + "@brwncald.com")
        }
    }
}
else {CleanPath $dirToClean "csomerlot@brwncald.com"}