
$path = "C:\Users\Administrator\OneDrive - Brown and Caldwell"  #$args[0]

Function Get-FolderItem {
    <#
        .SYNOPSIS
            Lists all files under a specified folder regardless of character limitation on path depth.

        .DESCRIPTION
            Lists all files under a specified folder regardless of character limitation on path depth.

        .PARAMETER Path
            The type name to list out available constructors and parameters

        .PARAMETER Filter
            Optional parameter to specify a specific file or file type. Wildcards (*) allowed.
            Default is '*.*'
        
        .PARAMETER ExcludeFile
            Exclude Files matching given names/paths/wildcards

        .PARAMETER MaxAge
            Exclude files older than n days.

        .PARAMETER MinAge
            Exclude files newer than n days.     

        .EXAMPLE
            Get-FolderItem -Path "C:\users\Administrator\Desktop\PowerShell Scripts"

            LastWriteTime : 4/25/2012 12:08:06 PM
            FullName      : C:\users\Administrator\Desktop\PowerShell Scripts\3_LevelDeep_ACL.ps1
            Name          : 3_LevelDeep_ACL.ps1
            ParentFolder  : C:\users\Administrator\Desktop\PowerShell Scripts
            Length        : 4958

            LastWriteTime : 5/29/2012 6:30:18 PM
            FullName      : C:\users\Administrator\Desktop\PowerShell Scripts\AccountAdded.ps1
            Name          : AccountAdded.ps1
            ParentFolder  : C:\users\Administrator\Desktop\PowerShell Scripts
            Length        : 760

            LastWriteTime : 4/24/2012 5:48:57 PM
            FullName      : C:\users\Administrator\Desktop\PowerShell Scripts\AccountCreate.ps1
            Name          : AccountCreate.ps1
            ParentFolder  : C:\users\Administrator\Desktop\PowerShell Scripts
            Length        : 52812

            Description
            -----------
            Returns all files under the PowerShell Scripts folder.

        .EXAMPLE
            $files = Get-ChildItem | Get-FolderItem
            $files | Group-Object ParentFolder | Select Count,Name

            Count Name
            ----- ----
               95 C:\users\Administrator\Desktop\2012 12 06 SysInt
               15 C:\users\Administrator\Desktop\DataMove
                5 C:\users\Administrator\Desktop\HTMLReportsinPowerShell
               31 C:\users\Administrator\Desktop\PoshPAIG_2_0_1
               30 C:\users\Administrator\Desktop\PoshPAIG_2_1_3
               67 C:\users\Administrator\Desktop\PoshWSUS_2_1
              437 C:\users\Administrator\Desktop\PowerShell Scripts
                9 C:\users\Administrator\Desktop\PowerShell Widgets
               92 C:\users\Administrator\Desktop\Working

            Description
            -----------
            This example shows Get-FolderItem taking pipeline input from Get-ChildItem and then saves
            the output to $files. Group-Object is used with $Files to show the count of files in each
            folder from where the command was executed.

        .EXAMPLE
            Get-FolderItem -Path $Pwd -MinAge 45

            LastWriteTime : 4/25/2012 12:08:06 PM
            FullName      : C:\users\Administrator\Desktop\PowerShell Scripts\3_LevelDeep_ACL.ps1
            Name          : 3_LevelDeep_ACL.ps1
            ParentFolder  : C:\users\Administrator\Desktop\PowerShell Scripts
            Length        : 4958

            LastWriteTime : 5/29/2012 6:30:18 PM
            FullName      : C:\users\Administrator\Desktop\PowerShell Scripts\AccountAdded.ps1
            Name          : AccountAdded.ps1
            ParentFolder  : C:\users\Administrator\Desktop\PowerShell Scripts
            Length        : 760

            Description
            -----------
            Gets files that have a LastWriteTime of greater than 45 days.

        .INPUTS
            System.String
        
        .OUTPUTS
            System.IO.RobocopyDirectoryInfo

        .NOTES
            Name: Get-FolderItem
            Author: Boe Prox
            Date Created: 31 March 2013
            Version History:
            Version 1.5 - 09 Jan 2014
                -Fixed bug in ExcludeFile parameter; would only work on one file exclusion and not multiple
                -Allowed for better streaming of output by Invoke-Expression to call the command vs. invoking
                a scriptblock and waiting for that to complete before display output.  
            Version 1.4 - 27 Dec 2013
                -Added FullPathLength property          
            Version 1.3 - 08 Nov 2013
                -Added ExcludeFile parameter
            Version 1.2 - 29 July 2013
                -Added Filter parameter for files
                -Fixed bug with ParentFolder property
                -Added default value for Path parameter            
            Version 1.1
                -Added ability to calculate file hashes
            Version 1.0
                -Initial Creation
    #>
    [cmdletbinding(DefaultParameterSetName='Filter')]
    Param (
        [parameter(Position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName')]
        [string[]]$Path = $PWD,
        [parameter(ParameterSetName='Filter')]
        [string[]]$Filter = '*.*',    
        [parameter(ParameterSetName='Exclude')]
        [string[]]$ExcludeFile,              
        [parameter()]
        [int]$MaxAge,
        [parameter()]
        [int]$MinAge
    )
    Begin {
        $params = New-Object System.Collections.Arraylist
        $params.AddRange(@("/L","/S","/NJH","/BYTES","/FP","/NC","/NDL","/TS","/XJ","/R:0","/W:0"))
        If ($PSBoundParameters['MaxAge']) {
            $params.Add("/MaxAge:$MaxAge") | Out-Null
        }
        If ($PSBoundParameters['MinAge']) {
            $params.Add("/MinAge:$MinAge") | Out-Null
        }
    }
    Process {
        ForEach ($item in $Path) {
            Try {
                $item = (Resolve-Path -LiteralPath $item -ErrorAction Stop).ProviderPath
                If (-Not (Test-Path -LiteralPath $item -Type Container -ErrorAction Stop)) {
                    Write-Warning ("{0} is not a directory and will be skipped" -f $item)
                    Return
                }
                If ($PSBoundParameters['ExcludeFile']) {
                    $Script = "robocopy `"$item`" NULL $Filter $params /XF $($ExcludeFile  -join ',')"
                } Else {
                    $Script = "robocopy `"$item`" NULL $Filter $params"
                }
                Write-Verbose ("Scanning {0}" -f $item)
                Invoke-Expression $Script | ForEach {
                    Try {
                        If ($_.Trim() -match "^(?<Size>\d+)\s(?<Date>\S+\s\S+)\s+(?<FullName>.*)") {
                            $object = New-Object PSObject -Property @{
                                ParentFolder = $matches.fullname -replace '(.*\\).*','$1'
                                FullName = $matches.FullName
                                Name = $matches.fullname -replace '.*\\(.*)','$1'
                                Length = [int64]$matches.Size
                                LastWriteTime = [datetime]$matches.Date
                                Extension = $matches.fullname -replace '.*\.(.*)','$1'
		                        FullPathLength = [int] $matches.FullName.Length
                                Owner = (Get-Acl $matches.FullName -ErrorAction SilentlyContinue).Owner
                                #Hash = (Get-FileHash -Path $matches.FullName -Algorithm "SHA256" -ErrorAction SilentlyContinue).Hash
                            }
                            $object.pstypenames.insert(0,'System.IO.RobocopyDirectoryInfo')
                            If ($object.Extension.Contains("\")) {
                                $object.Extension = ""
                            }
                            Write-Output $object
                        } Else {
                            Write-Verbose ("Not matched: {0}" -f $_)
                        }
                    } Catch {
                        Write-Warning ("{0}" -f $_.Exception.Message)
                        Return
                    }
                }
            } Catch {
                Write-Warning ("{0}" -f $_.Exception.Message)
                Return
            }
        }
    }
}

$start = Get-Date


$conn = New-Object System.Data.Odbc.OdbcConnection
#$conn.ConnectionString= "DRIVER={SQL Server};Server=keydbsdev.bc.com;Database=BranchToCloud;IntegratedSecurity=Yes;"
$conn.ConnectionString = "DRIVER=SQLite3 ODBC Driver;Database=C:\Users\Administrator\OneDrive - Brown and Caldwell\TTAC\findFiles2.db;LongNames=0;Timeout=1000;NoTXN=0;SyncPragma=NORMAL;StepAPI=0;"
$conn.open()

$machineName = $env:COMPUTERNAME
# $machineName = "BCSYRNAS01"
$qry = "DELETE FROM DigitalFileAssets WHERE [Hostname] = '{0}'" -f $machineName
$cmd = new-object System.Data.Odbc.OdbcCommand($qry,$conn)
try { $result = $cmd.ExecuteNonQuery() }
catch { Write-Host "ERROR:" $qry }
Write-Host "Clearing previous entries from DB for" $machineName "count" $result

$table = Get-FolderItem -Path $path
foreach($file in $table){
    #Write-Host $file.Length $file.LastWriteTime $file.FullName
    
    $qry = "INSERT INTO DigitalFileAssets (Name,FileFullName,Directory,Extension,SHA256,LastModifiedTime,Bytes,Owner,Hostname) VALUES( '{0}','{1}','{2}','{3}','{4}','{5}',{6},'{7}','{8}');`n" -f `
        $file.Name.Replace("'","''"), $file.FullName.Replace("'","''"), $file.ParentFolder, $file.Extension, $file.Hash, $file.LastWriteTime, $file.Length, $file.Owner, $machineName
    #Write-Host $qry
    $cmd = new-object System.Data.Odbc.OdbcCommand($qry,$conn)
    try { 
        $result = $cmd.ExecuteNonQuery() 
        if ($result -eq 0) {Write-Host "Command failed:" $qry}
    }
    catch { Write-Host "ERROR:" $qry }
    
}
$conn.close()

$end = Get-Date
$ts = New-TimeSpan -Start $start -End $end

Write-Host "Took $($ts.Days * 86400.0 + $ts.Hours * 3600.0 + $ts.Minutes * 60.0 + $ts.Seconds * 1.0) seconds to run"
