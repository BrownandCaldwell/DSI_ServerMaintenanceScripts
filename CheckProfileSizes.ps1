
"userDir,userDirSize" | Out-File -FilePath .\Profiles.csv
foreach($userDir in Join-Path C:\Users * -Resolve) {
    #Write-Host $userDir ((Get-ChildItem (Join-Path $userDir AppData) -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB)
    #$AppDataSize = ((Get-ChildItem (Join-Path $userDir AppData) -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB)
    $userDirSize = ((Get-ChildItem $userDir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1GB)
    if ($userDirSize -gt 1.0) {
        ($userDir -Replace "C:\\Users\\", "") + ";," + $userDirSize | Out-File -Append -FilePath .\Profiles.csv
    }
}