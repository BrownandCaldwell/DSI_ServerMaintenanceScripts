Write-Host "Scanning" $args[0]
$basePath = $args[0]
$inc  = 10

#Add-OdbcDsn -Name "active" -DriverName "SQL Server Native Client 11.0" -DsnType "System" -SetPropertyValue @("Server=keydbsdev.bc.com", "Trusted_Connection=Yes", "Database=Branch2Cloud")
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString= "DRIVER={SQL Server};Server=keydbsdev.bc.com;Database=Branch2Cloud;IntegratedSecurity=Yes;"
$conn.open()

foreach($path in Get-ChildItem $basePath){
    Write-Host "  " (Join-Path $basePath $path)
    $start = Get-Date
    $table = $null
    $table = Get-ChildItem (Join-Path $basePath $path) -Recurse -Include @('*.*') | Select-Object  BaseName, Mode, Name, Length, DirectoryName, IsReadOnly, FullName, Extension, CreationTime, `
      CreationTimeUtc, LastAccessTime, LastAccessTimeUtc, LastWriteTime, LastWriteTimeUtc, Attributes, @{n='Owner'; e={(Get-Acl $_.FullName).Owner}}, @{N="HostName"; E={$env:COMPUTERNAME}} # -ErrorAction SilentlyContinue
    if ($table -isnot [array]) {$table = @($table)}
    #Write-Host "    " $table.Length
    if ($table.Length -gt 0) {
        for($i=0; $i -le $table.Length; $i=$i+$inc){
    
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
            #if ($i+$j -gt $table.Length - 1) {break} 
            $qry = $qry.Substring(0,$qry.Length-2) + ';'
            # Write-Host $qry
            $cmd = new-object System.Data.Odbc.OdbcCommand($qry,$conn)
            $result = $cmd.ExecuteNonQuery()
            # Write-Host $i      
        }
    }
    $end = Get-Date
    $ts = New-TimeSpan -Start $start -End $end
    Write-Host "     Scanned in $($ts.Days * 86400.0 + $ts.Hours * 3600.0 + $ts.Minutes * 60.0 + $ts.Seconds * 1.0) seconds"
    
}
#Set-ODBC-Data $qry
$conn.close()
