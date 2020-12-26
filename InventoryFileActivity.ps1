#Write-Host "Scanning" $args[0]
$basePath = "\\bc\corp\PW_Exports" # $args[0]
$hostName = Split-Path -Path $basePath 
#$hostName = $env:COMPUTERNAME
$logFile = ($hostName -replace "\\", "_") + 'FileInventory.log'
Start-Transcript -Append -Path $logFile


$inc = 100
$objects = 0
$bytes  = 0
$errorFound = $false
$connString = "DRIVER={SQL Server};Server=sqlaz.bc.com;Database=Branch2Cloud;IntegratedSecurity=Yes;"
$start = Get-Date
Write-Host $start

#Add-OdbcDsn -Name "active" -DriverName "SQL Server Native Client 11.0" -DsnType "System" -SetPropertyValue @("Server=keydbsdev.bc.com", "Trusted_Connection=Yes", "Database=Branch2Cloud")
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString= $connString
$conn.open()

$cmd = new-object System.Data.Odbc.OdbcCommand("DELETE FROM DigitalFileAssets WHERE [HostName] = '$hostName'" ,$conn)
$result = $cmd.ExecuteNonQuery()
Write-Host "DELETE query result:" $result


function Do-Inventory ($connString, $hostName, $thisPath, $inc){    
    $conn = New-Object System.Data.Odbc.OdbcConnection
    $conn.ConnectionString= $connString
    $conn.open()    

    $table = $null
    $table = Get-ChildItem $thisPath -Recurse -Include @('*.*') | Select-Object  BaseName, Mode, Name, Length, DirectoryName, IsReadOnly, FullName, Extension, CreationTime, `
      CreationTimeUtc, LastAccessTime, LastAccessTimeUtc, LastWriteTime, LastWriteTimeUtc, Attributes, @{n='Owner'; e={(Get-Acl $_.FullName).Owner}}, @{N="HostName"; E={$hostName}} # -ErrorAction SilentlyContinue
    if ($table -isnot [array]) {$table = @($table)}
    #Write-Host "    " $table.Length
    if ($table.Length -gt 0) {
        $objects = $objects + $table.Length
        for($i=0; $i -le $table.Length; $i=$i+$inc){

            # Write-Host $i   

            $qry = "INSERT INTO DigitalFileAssets ([BaseName], [Mode], [FileName], [PathLength], [DirectoryName], [IsReadOnly], [FullName], [Extension], [CreationTime],  [CreationTimeUtc], [LastAccessTime], [LastAccessTimeUtc], [LastWriteTime], [LastWriteTimeUtc], [Attributes], [Owner], [Hostname], [inserted_dt], [folder1], [folder2], [folder3], [folder4], [folder5], [folder6], [folder7]) VALUES`n"
            $now = Get-Date
    
            for($j=0; $j -lt $inc; $j++) {
                if ($i+$j -gt $table.Length - 1) {break}

                $file = $table[$i+$j]
                #Write-Host "      " $file.FullName
                if ($file -ne $null) {
                    $fileParts = $file.Fullname.Split("\") | Select-Object -First 7
                    $qry = $qry + "    ( '{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}','{14}','{15}','{16}','{17}','{18}','{19}','{20}','{21}','{22}','{23}','{24}'),`n" `
                        -f $file.BaseName, $file.Mode, $file.Name, $file.Length, $file.DirectoryName, $file.IsReadOnly, $file.FullName, $file.Extension, $file.CreationTime, `
                         $file.CreationTimeUtc, $file.LastAccessTime, $file.LastAccessTimeUtc, $file.LastWriteTime, $file.LastWriteTimeUtc, $file.Attributes, $file.Owner, $file.HostName, $now, `
                         $fileParts[0], $fileParts[1], $fileParts[2], $fileParts[3], $fileParts[4], $fileParts[5], $fileParts[6]
                }
            }
            
            $qry = $qry.Substring(0,$qry.Length-2) + ';'
            #Write-Host $qry
            $cmd = new-object System.Data.Odbc.OdbcCommand($qry,$conn) 
            Try {$result = $cmd.ExecuteNonQuery() }
            Catch { 
                $errorFound = $true 
                Write-Host "ERROR RUNNING" $qry    
                Write-Host $_
            }
            #Write-Host "        INSERT query result:" $result 
        }
    }
    $conn.close()
}


foreach($path in Get-ChildItem $basePath){
    $pathToProcess = (Join-Path $basePath $path) -replace "'","''"
    Write-Host "  " $pathToProcess
    #Do-Inventory $conn $hostName $pathToProcess $inc
    Start-Job -ScriptBlock ${Function:Do-Inventory} -ArgumentList $connString, $hostName, $pathToProcess, $inc #| Wait-Job | Receive-Job
}

$end = Get-Date
$ts = New-TimeSpan -Start $start -End $end
$seconds = $ts.Days * 86400.0 + $ts.Hours * 3600.0 + $ts.Minutes * 60.0 + $ts.Seconds * 1.0
$qry = "INSERT INTO InventoryScriptResults ([HostName], [seconds], [bytes], [objects] [logfile]) VALUES ('$hostName', $seconds, $bytes, $objects, '$logFile')`n"
#$cmd = new-object System.Data.Odbc.OdbcCommand($qry,$conn)
Write-Host $qry "`n`n"
$conn.close()

Stop-Transcript