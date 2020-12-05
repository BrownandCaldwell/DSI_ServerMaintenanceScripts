function Get-UserSessions
{
  <#
      .SYNOPSIS
      A PowerShell version of qwinsta using qwinsta output as the input

      .DESCRIPTION
      Takes qwinsta output and manipulates it so that it outputs correctly as an array that can be piped correctly into other commands.

      .PARAMETER ComputerName
      Specify the name of the computer you want to query.
      Defaults to using the local hostname if the parameter is not used

      .EXAMPLE
      Example 1:
      Get-UserSessions
      Queries the local computer and returns the list of user sessions.

      Example 2:
      Get-UserSessions -ComputerName MYSERVER
      Queries the server MYSERVER and returns the list of user sessions.

      .NOTES
      Should work with all versions of PowerShell and all versions of Windows that have qwinsta.exe installed.
      Script still relies on qwinsta.exe for its input

      .LINK

      .INPUTS
      alphanumeric for -ComputerName

      .OUTPUTS
      array of user sessions to host

      .NOTES
      Version :        1.0
      Author :         Leon Evans
      Creation Date :  11th November 2018
      Location : https://gallery.technet.microsoft.com/scriptcenter/site/search?f%5B0%5D.Type=User&f%5B0%5D.Value=Guyver-1
      Purpose/Change: Original Version
  #>


  [OutputType([array])]
  Param
  (
    # SPECIFY COMPUTER NAME. DEFAULTS TO LOCAL HOSTS COMPUTERNAME #
    [Parameter(
        ValueFromPipelineByPropertyName=$true,
        Position=0,
    HelpMessage='Input the Hostname of the computer you want to query')]
    [ValidatePattern('[A-Za-z0-9]')]
    [string]$ComputerName = $env:COMPUTERNAME
  )

  Begin
  {
    ### CREATE ARRAYS ###
    $DefaultNullStateUsers = @()
    $DefaultStateUsers = @()
    $ActiveUsers = @()
    $DisconnectedUsers = @()
    $FinalUserList = @()
    $hashedUserList = @{}
    
    ### CREATE NEW PROPERTIES ###
    $ModUsername = @{
      Expression = {$null}
      Name = 'USERNAME'
    }
    
    $ModSessionname = @{
      Expression = {$null}
      Name = 'SESSIONAME'
    }

    $SwapUserWithSession = @{
      Expression = {$_.USERNAME -replace ("$($_.USERNAME)","$($_.SESSIONNAME)")}
      Name = 'USERNAME'
    }

    $ModID = @{
      Expression = {$_.ID -replace ("$($_.ID)","$($_.USERNAME)")}
      Name = 'ID'
    }

    $ModState = @{
      Expression = {$_.STATE -replace ("$($_.STATE)","$($_.ID)")}
      Name = 'STATE'
    }

    $ModType = @{
      Expression = {$_.TYPE -replace ("$($_.TYPE)","$($_.STATE)")}
      Name = 'TYPE'
    }

    $ModDevice = @{
      Expression = {$_.DEVICE -replace ("$($_.DEVICE)","$($_.TYPE)")}
      Name = 'DEVICE'
    }
      
    ### GET ALL USER SESSIONS WITH QWINSTA ###
    $qwinsta = $null
    $qwinsta = qwinsta.exe /server:$ComputerName | ForEach-Object {
      $_.Trim() -replace '\s+',','
    } | ConvertFrom-Csv
  }
  Process
  {
    ###PROCESS USER SESSIONS FROM QWINSTA OUTPUT ###
    # GET ALL DEFAULT USERS WITH NO STATE #
    foreach ($i in $qwinsta) {
      if (($i.STATE -like $null) -and ($i.SESSIONNAME -like 'services' -or $i.SESSIONNAME -like 'console' -or $i.SESSIONNAME -like 'rdp-tcp')) {
        $DefaultNullStateUsers += @($i)
      }
    }
    
    # GET ALL DEFAULT USERS WITH A STATE #
    foreach ($i in $qwinsta) {
      if (($i.STATE -notlike $null) -and ($i.SESSIONNAME -like 'services' -or $i.SESSIONNAME -like 'console' -or $i.SESSIONNAME -like 'rdp-tcp')) {
        $DefaultStateUsers += @($i)
      }
    }
    
    # GET ALL ACTIVE RDP USERS #
    foreach ($i in $qwinsta) {
      if (($i.SESSIONNAME -like 'rdp-tcp#*') -and ($i.SESSIONNAME -notlike 'services' -or $i.SESSIONNAME -notlike 'console' -or $i.SESSIONNAME -notlike 'rdp-tcp')) {
        $ActiveUsers += @($i)
      }
    }
    
    # GET ALL DISCONNECTED RDP USERS #
    foreach ($i in $qwinsta) {
      if (($i.STATE -like $null -and $i.SESSIONNAME -notlike 'services') -and ($i.STATE -like $null -and $i.SESSIONNAME -notlike 'console') -and ($i.STATE -like $null -and $i.SESSIONNAME -notlike 'rdp-tcp')) {
        $DisconnectedUsers += @($i)
      }
    }
    
    ### FIX BROKEN CSV FORMATTING ###
    $FixedDefaultNullStateUsers = $DefaultNullStateUsers | Select-Object -Property SESSIONNAME,$ModUsername,$ModID,$ModState,$ModType,$ModDevice
    $FixedDisconnectedUsers = $DisconnectedUsers | Select-Object -Property $ModSessionName,$SwapUserWithSession,$ModID,$ModState,$ModType,$ModDevice


    ### MERGE LISTS OF USERS BACK INTO ONE FINAL LIST ###
    $FinalUserList += $FixedDefaultNullStateUsers
    $FinalUserList += $DefaultStateUsers
    $FinalUserList += $ActiveUsers
    $FinalUserList += $FixedDisconnectedUsers

    foreach ($i in $FinalUserList) {
        if ($i.USERNAME -notlike $null) {
            $hashedUserList[$i.USERNAME] = $i
        }
    }
  }
  End
  {
    ### OUTPUT ###
    #$FinalUserList
    $hashedUserList
  }
}
