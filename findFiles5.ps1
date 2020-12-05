
function ConvertTo-Hex {
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]$InputObject
    )

    $hex = [char[]]$InputObject |
           ForEach-Object { '{0:X2}' -f [int]$_ }

    if ($hex -ne $null) {
        return (-join $hex)
    }
}

#Add-OdbcDsn -Name "active" -DriverName "SQL Server Native Client 11.0" -DsnType "System" -SetPropertyValue @("Server=keydbsdev.bc.com", "Trusted_Connection=Yes", "Database=BranchToCloud")
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString= "DRIVER={SQL Server};Server=keydbsdev.bc.com;Database=Branch2Cloud;IntegratedSecurity=Yes;"
$conn.open()

$qry = ''
$table = Get-ChildItem $args[0] -Recurse -Include @('*.*') | Select-Object  BaseName, Mode, Name, Length, DirectoryName, Directory, IsReadOnly, Exists, FullName, Extension, CreationTime, CreationTimeUtc, LastAccessTime, LastAccessTimeUtc, LastWriteTime, LastWriteTimeUtc, Attributes, @{n='Owner'; e={(Get-Acl $_.FullName).Owner}}, @{N="HostName"; E={$env:COMPUTERNAME}} # -ErrorAction SilentlyContinue
foreach($file in $table){

    # Write-Host -NoNewline $file.FullName " "
    #$filehash = $null
    $filehash = Get-FileHash -Path $file.FullName -Algorithm "SHA256"# -ErrorAction SilentlyContinue
    if ($filehash -ne $null) {
        #$folder = $file.Directory | ConvertTo-Hex
        
        ## OR IGNORE skips rows that already have that hash, essentially only adding rows with new hashs which would only be from changed files
        $qry = "INSERT INTO DigitalFileAssets (FullName,SHA256,Directory,Extension,LastWriteTimeUtc,LastAccessTimeUtc,Owner,Length,Hostname) VALUES( '{0}','{1}','{2}','{3}','{4}','{5}','{6}',{7},'{8}');`n" -f $file.FullName, $filehash.Hash, $file.Directory, $file.Extension, $file.LastWriteTimeUtc, $file.LastAccessTimeUtc, $file.Owner, $file.Length, $file.HostName
        #Write-Host $qry
        $cmd = new-object System.Data.Odbc.OdbcCommand($qry,$conn)
        $result = $cmd.ExecuteNonQuery()
        #Write-Host $result $hash #$file.Directory.GetHashCode() $filehash.Hash.GetHashCode()
        if ($result -eq 1) {Write-Host "is new or has changed"}
        else {Write-Host "skipped"}
    }
    else {Write-Host "Can't compute SHA256 hash for" $file.FullName}
}
#Set-ODBC-Data $qry
$conn.close()
