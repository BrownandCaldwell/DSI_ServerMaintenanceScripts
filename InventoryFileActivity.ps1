#$basePath = "\\bcvabfp01\Projects\GIS\Admin" 
$basePath = $args[0]
#$hostName = Split-Path -Path $basePath 
$hostName = $basePath
#$hostName = $env:COMPUTERNAME
$logFile = ($hostName -replace "\\", "_") + '_FileInventory.log'
Start-Transcript -Append -Path $logFile


$inc = 50
$errorFound = $false
$connString = "DRIVER={SQL Server};Server=sqlaz.bc.com;Database=Branch2Cloud;IntegratedSecurity=Yes;"
$start = Get-Date
Write-Host $start $basePath

$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString= $connString
$conn.open()

$cmd = new-object System.Data.Odbc.OdbcCommand("DELETE FROM DigitalFileAssets WHERE [HostName] = '$hostName'" ,$conn)
$cmd.CommandTimeout = 900
$result = $cmd.ExecuteNonQuery()
Write-Host "DELETE query result:" $result


function Do-Inventory ($connString, $hostName, $thisPath, $inc){    
    $conn = New-Object System.Data.Odbc.OdbcConnection
    $conn.ConnectionString= $connString
    $conn.open()    

    $table = $null
    $table = Get-ChildItem -LiteralPath $thisPath -Recurse -Force -Include @('*.*') | Select-Object  BaseName, Mode, Name, Length, DirectoryName, IsReadOnly, FullName, Extension, CreationTime, `
      CreationTimeUtc, LastAccessTime, LastAccessTimeUtc, LastWriteTime, LastWriteTimeUtc, Attributes, @{n='Owner'; e={(Get-Acl $_.FullName).Owner}}, @{N="HostName"; E={$hostName}} # -ErrorAction SilentlyContinue
    if ($table -isnot [array]) {$table = @($table)}
    Write-Host "Found" $thisPath "with" $table.Length "files/folders"

    if ($table.Length -gt 0) {
        for($i=0; $i -le $table.Length; $i=$i+$inc){

            # Write-Host $i   

            $qry = "INSERT INTO DigitalFileAssets ([BaseName], [Mode], [FileName], [PathLength], [DirectoryName], [IsReadOnly], [FullName], [Extension], [CreationTime],  [CreationTimeUtc], [LastAccessTime], [LastAccessTimeUtc], [LastWriteTime], [LastWriteTimeUtc], [Attributes], [Owner], [Hostname], [inserted_dt], [folder1], [folder2], [folder3], [folder4], [folder5], [folder6], [folder7]) VALUES`n"
            $now = Get-Date
    
            for($j=0; $j -lt $inc; $j++) {
                if ($i+$j -gt $table.Length - 1) {break}

                $file = $table[$i+$j]
                #Write-Host "      " $file.FullName
                if ($file -ne $null) {
                    $fileParts = $file.Fullname.Replace("'","''").Split("\") | Select-Object -Skip 2 -First 7
                    $qry = $qry + "    ( "
                    $qry = $qry + "'{0}'," -f $file.BaseName.Replace("'","''")
                    $qry = $qry + "'{0}'," -f $file.Mode
                    $qry = $qry + "'{0}'," -f $file.Name.Replace("'","''")
                    $qry = $qry + "'{0}'," -f $file.Length
                    if ($file.DirectoryName -ne $null) {$qry = $qry + "'{0}'," -f $file.DirectoryName.Replace("'","''") }
                    else {$qry = $qry + "NULL,"}
                    $qry = $qry + "'{0}'," -f $file.IsReadOnly
                    $qry = $qry + "'{0}'," -f $file.FullName.Replace("'","''")
                    $qry = $qry + "'{0}'," -f $file.Extension
                    $qry = $qry + "'{0}'," -f $file.CreationTime
                    $qry = $qry + "'{0}'," -f $file.CreationTimeUtc
                    $qry = $qry + "'{0}'," -f $file.LastAccessTime
                    $qry = $qry + "'{0}'," -f $file.LastAccessTimeUtc
                    $qry = $qry + "'{0}'," -f $file.LastWriteTime
                    $qry = $qry + "'{0}'," -f $file.LastWriteTimeUtc
                    $qry = $qry + "'{0}'," -f $file.Attributes
                    $qry = $qry + "'{0}'," -f $file.Owner
                    $qry = $qry + "'{0}'," -f $file.HostName
                    $qry = $qry + "'{0}'" -f $now
                    for($k=0; $k -lt 7; $k++) {$qry = $qry + ",'{0}'" -f $fileParts[$k]}
                    $qry = $qry + "),`n" 
                }
            }
            
            $qry = $qry.Substring(0,$qry.Length-2) + ';'
            #Write-Host $qry
            $cmd = new-object System.Data.Odbc.OdbcCommand($qry,$conn) 
            $cmd.CommandTimeout = 900
            Try {$result = $cmd.ExecuteNonQuery() }
            Catch { 
                Write-Host "ERROR RUNNING" $qry    
                Write-Host $_
                $errorFound = $true
            }
            #Write-Host "        INSERT query result:" $result 
        }
    }
    $conn.close()
}


foreach($path in Get-ChildItem $basePath){
    $pathToProcess = (Join-Path $basePath $path)
    #Do-Inventory $connString $hostName $pathToProcess $inc
    Start-Job -ScriptBlock ${Function:Do-Inventory} -ArgumentList $connString, $hostName, $pathToProcess, $inc #| Wait-Job | Receive-Job
}

$jobs = Get-Job
while ($jobs.Length -gt 0) {
    $remainingJobs = @()

    foreach($job in $jobs) {
        if ($job.State -eq "Running") {
            $remainingJobs += $job
        }
        else {
            Receive-Job $job
        }
    }
    $jobs = $remainingJobs
    Write-Host "Waiting on" $jobs.Length "jobs to finish" (Get-Date)
    Start-Sleep -Seconds 60.0
    
}

$end = Get-Date
$ts = New-TimeSpan -Start $start -End $end
$errorFlag = 0
if ($errorFound) {$errorFlag = 1}
$seconds = $ts.Days * 86400.0 + $ts.Hours * 3600.0 + $ts.Minutes * 60.0 + $ts.Seconds * 1.0
$qry = "INSERT INTO InventoryScriptResults ([HostName], [seconds], [logfile], [Errors], [ExecutionTS]) VALUES ('$hostName', $seconds, '$logFile', $errorFlag, '$end')`n"
#Write-Host $qry
$cmd = new-object System.Data.Odbc.OdbcCommand($qry,$conn)
$result = $cmd.ExecuteNonQuery()
$conn.close()

Write-Host "Done in $seconds seconds"
if ($errorFound) {Write-Host "ERRORS FOUND, refer to log file"}

Stop-Transcript