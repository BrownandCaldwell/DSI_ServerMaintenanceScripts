
$path = "V:\Akron"
$start = Get-Date

Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue -Include @('*.*') | Select-Object  BaseName, Mode, Name, Length, DirectoryName, Directory, IsReadOnly, Exists, FullName, Extension, CreationTime, CreationTimeUtc, LastAccessTime, LastAccessTimeUtc, LastWriteTime, LastWriteTimeUtc, Attributes, @{n='Owner'; e={(Get-Acl $_.FullName).Owner}}, @{N="HostName"; E={$env:COMPUTERNAME}} | Export-Csv -Path .\Files.csv -NoTypeInformation

$end = Get-Date
$ts = New-TimeSpan -Start $start -End $end

Write-Host "Took $($ts.Days * 86400.0 + $ts.Hours * 3600.0 + $ts.Minutes * 60.0 + $ts.Seconds * 1.0) seconds to run"