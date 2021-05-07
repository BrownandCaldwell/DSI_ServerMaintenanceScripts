$hostName = $env:COMPUTERNAME
$dirToCLean = $args[0].ToString()
$age  = $args[1] # in days
$sizeLimit = $args[2] # in GB
$action = $args[3]
$message = $args[4].ToString().Replace("VM", $hostName).Replace("sizeLimit", $sizeLimit)
$size  = 0

$logFile = "Clean_out_" + ($dirToCLean -replace "\\", ".") + "_on_" + ($hostName -replace "\\", "_") + ".log"
Start-Transcript -Append -Path $logFile

function CleanPath($path, $notifyList){
    $size = (Get-ChildItem $path -Recurse -File | Measure-Object -Property Length -Sum -ErrorAction Continue).Sum/1000000000
    Write-Host $path $size
    if ($size -gt $sizeLimit) {
        Write-Host $size "GB in" $path
        if ($action.ToLower().Contains("delete")) {
            Write-Host "  Deleting content from" $path
            if ($age -eq "Any") {
                $files = Get-ChildItem -Path $path -Recurse -File
            }
            else {
                $files = Get-ChildItem -Path $path -Recurse -File | Where-Object { ($_.LastWriteTime -lt (Get-Date).AddDays(-$age)) } 
            }
            foreach ($file in $files) {
                Write-Host "    Deleting" $file
                Remove-Item $file.FullName -Force -Recurse -ErrorAction Continue
            }
        }
        if ($action.ToLower().Contains("notify")) { 
            Write-Host "Sending email to $($_.Name)@brwncald.com: $message, action: $action"
            Send-MailMessage -To "$($_.Name)@brwncald.com" -From "noreply@brwncald.com"  -Subject "Folder $path on $hostname has grown too large, action taken: $action" -Body $message -SmtpServer "smtp.brwncald.com"
        }
    }
}

if ($dirToCLean.ToLower().StartsWith("userprofile")) {
    $Users = Get-ChildItem C:\Users
    $Users | ForEach-Object {
        $path = Join-Path C:\Users $dirToClean.Replace("userprofile","$_")
        
        if (Test-Path -Path $path) {
            Write-Host $path
            CleanPath $path ($_.Name + "@brwncald.com")
        }
    }
}
else {CleanPath $dirToClean "csomerlot@brwncald.com"}