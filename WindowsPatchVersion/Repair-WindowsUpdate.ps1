#Function to test existing reg keys
function Test-RegistryValue {

     param (     
      [parameter(Mandatory=$true)]
      [ValidateNotNullOrEmpty()]$Path,     
     [parameter(Mandatory=$true)]
      [ValidateNotNullOrEmpty()]$Value
     )
     
     try {
     Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
      return $true
      }
     
     catch {
     return $false
     } 
}

$regPath = 'HKLM:\SOFTWARE\Iber0\UpdateState\' # Record Output last executión
$daysBetweenRepairs = '30' # Time in days, which has to elapse before each repair is launched

# Checking whether the registry entries exist
if((Test-RegistryValue -Path $regPath -Value 'UpdateValid') -eq $false){
     Write-Output 'UpdateState value registry not found'
      Exit 1
}
if((Test-RegistryValue -Path $regPath -Value 'Repair1') -eq $false){
     Write-Output 'Repair1 value registry not found'
      Exit 1
}
if((Test-RegistryValue -Path $regPath -Value 'Repair2') -eq $false){
     Write-Output 'Repair2 value registry not found'
      Exit 1
}
if((Test-RegistryValue -Path $regPath -Value 'Repair3') -eq $false){
     Write-Output 'Repair3 value registry not found'
      Exit 1
}

# if all registry keys exist, we continue to see what repair to launch
$updateState = Get-ItemPropertyValue -Path $regPath -Name 'UpdateValid'

# Cheking if repair is necessary
if ($updateState -eq 'OK') {
     Write-Output 'Repair not necessary'
     Exit 0
}

# Launch repair1
$repair1State = Get-ItemPropertyValue -Path $regPath -Name 'Repair1'
if($repair1State -eq '0'){
     
      #Add registry entries
      Set-ItemProperty $RegPath "Repair1" -Value '1' -type String
      Set-ItemProperty $RegPath "Repair1Date" -Value $(get-date) -type String

     #### Repair1 
     # Stop Services
     Get-Service -Name wuauserv,bits,cryptsvc,msiserver | Stop-Service

     # Delete all qmgr.dat files to clear stuck Bits jobs
     Remove-Item -Path "$env:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\qmgr*.dat"

     # Backing up the Windows Update cache folders to generate the cache again
     Rename-Item -Path "$env:SYSTEMROOT\SoftwareDistribution\DataStore" -NewName 'DataStore.bak'
     Rename-Item -Path "$env:SYSTEMROOT\SoftwareDistribution\Download" -NewName 'Download.bak'
     Rename-Item -Path "$env:SYSTEMROOT\System32\catroot2" -NewName 'catroot2.bak'

     # Resets security descriptors for BITS and Windows Update services 
     $null = Start-Process -FilePath 'sc.exe' -ArgumentList 'sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)'
     $null = Start-Process -FilePath 'sc.exe' -ArgumentList 'sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)'

     # Re-register the DLLs related to the Windows Update Agent.
     $dlls = @(
          'atl.dll'
          'urlmon.dll'
          'mshtml.dll'
          'shdocvw.dll'
          'browseui.dll'
          'jscript.dll'
          'vbscript.dll'
          'scrrun.dll'
          'msxml.dll'
          'msxml3.dll'
          'msxml6.dll'
          'actxprxy.dll'
          'softpub.dll'
          'wintrust.dll'
          'dssenh.dll'
          'rsaenh.dll'
          'gpkcsp.dll'
          'sccbase.dll'
          'slbcsp.dll'
          'cryptdlg.dll'
          'oleaut32.dll'
          'ole32.dll'
          'shell32.dll'
          'initpki.dll'
          'wuapi.dll'
          'wuaueng.dll'
          'wuaueng1.dll'
          'wucltui.dll'
          'wups.dll'
          'wups2.dll'
          'wuweb.dll'
          'qmgr.dll'
          'qmgrprxy.dll'
          'wucltux.dll'
          'muweb.dll'
          'wuwebv.dll'
     )
     foreach ($dll in $dlls) {
     regsvr32.exe "$env:SYSTEMROOT\System32\$dll" /s
     }

     # Clean WSUS entries from the Windows registry
     @('AccountDomainSid','PingID','SusClientId','SusClientIDValidation') | ForEach-Object {
          Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Name $_ -ErrorAction Ignore
     }

     # Reset ACL for WUA
     $null = wuauclt.exe /resetauthorization

     # Vuelvo a arrancar los servicios
     Get-Service -Name wuauserv,bits,cryptsvc | Start-Service

     # Repair damaged files with DISM
     $processOptionsDism = @{
          FilePath = "DISM.exe"
          ArgumentList = "/Online /Cleanup-Image /RestoreHealth"
     }
     Start-Process @processOptionsDism
     Write-Output 'Repair1 implemented'
    
     # Launching the update search
     (New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()
     Exit 0
}


## For launch repair2, repair1 had to be launched more than days ago defined in $daysBetweenRepairs
# Checking whether the registry entry exist
if((Test-RegistryValue -Path $regPath -Value 'Repair1Date') -eq $false){
     Write-Output 'Repair1Date value registry not found'
      Exit 1
}

# Checking if sufficient time has passed
$repair1Date = [dateTime]$(Get-ItemPropertyValue -Path $regPath -Name 'Repair1Date')
$timeElapsedRepair1 = New-TimeSpan -Start $repair1Date -End $(Get-Date)
if (($timeElapsedRepair1.Days) -le $daysBetweenRepairs){
     Write-Output 'Time elapsed since repair1 not sufficient'
     Exit 1
}

# Launch repair2
$repair2State = Get-ItemPropertyValue -Path $regPath -Name 'Repair2'
if($repair2State -eq '0'){

     ## Repair2 
     # Function to download patchs
     Function Get-WindowsUpdatesInstall
     {
          <#
          .SYNOPSIS
               Download and install updates.
          .DESCRIPTION
               Use Get-WindowsUpdatesInstall to get list of available updates, next download and install it. 
               There are two types of filtering update: Pre search criteria, Post search criteria.
               - Pre search works on server side, like example: ( IsInstalled = 0 and IsHidden = 0 and CategoryIds contains '0fa1201d-4330-4fa8-8ae9-b877473b6441' )
               - Post search work on client side after downloading the pre-filtered list of updates, like example $KBArticleID -match $Update.KBArticleIDs
               
               Update occurs in four stages: 1. Search for updates, 2. Choose updates, 3. Download updates, 4. Install updates.
               
          .PARAMETER UpdateType
               Pre search criteria. Finds updates of a specific type, such as 'Driver' and 'Software'. Default value contains all updates.
          .PARAMETER UpdateID
               Pre search criteria. Finds updates of a specific UUID (or sets of UUIDs), such as '12345678-9abc-def0-1234-56789abcdef0'.
          .PARAMETER RevisionNumber
               Pre search criteria. Finds updates of a specific RevisionNumber, such as '100'. This criterion must be combined with the UpdateID param.
          .PARAMETER CategoryIDs
               Pre search criteria. Finds updates that belong to a specified category (or sets of UUIDs), such as '0fa1201d-4330-4fa8-8ae9-b877473b6441'.
          .PARAMETER IsInstalled
               Pre search criteria. Finds updates that are installed on the destination computer.
          .PARAMETER IsHidden
               Pre search criteria. Finds updates that are marked as hidden on the destination computer. Default search criteria is only not hidden upadates.
          
          .PARAMETER WithHidden
               Pre search criteria. Finds updates that are both hidden and not on the destination computer. Overwrite IsHidden param. Default search criteria is only not hidden upadates.
               
          .PARAMETER Criteria
               Pre search criteria. Set own string that specifies the search criteria.
          .PARAMETER ShowSearchCriteria
               Show choosen search criteria. Only works for pre search criteria.
               
          .PARAMETER Category
               Post search criteria. Finds updates that contain a specified category name (or sets of categories name), such as 'Updates', 'Security Updates', 'Critical Updates', etc...
               
          .PARAMETER KBArticleID
               Post search criteria. Finds updates that contain a KBArticleID (or sets of KBArticleIDs), such as 'KB982861'.
          
          .PARAMETER Title
               Post search criteria. Finds updates that match part of title, such as ''
          .PARAMETER NotCategory
               Post search criteria. Finds updates that not contain a specified category name (or sets of categories name), such as 'Updates', 'Security Updates', 'Critical Updates', etc...
               
          .PARAMETER NotKBArticleID
               Post search criteria. Finds updates that not contain a KBArticleID (or sets of KBArticleIDs), such as 'KB982861'.
          
          .PARAMETER NotTitle
               Post search criteria. Finds updates that not match part of title.
               
          .PARAMETER IgnoreUserInput
               Post search criteria. Finds updates that the installation or uninstallation of an update can't prompt for user input.
          
          .PARAMETER IgnoreRebootRequired
               Post search criteria. Finds updates that specifies the restart behavior that not occurs when you install or uninstall the update.
          
          .PARAMETER ServiceID
               Set ServiceIS to change the default source of Windows Updates. It overwrite ServerSelection parameter value.
          .PARAMETER WindowsUpdate
               Set Windows Update Server as source. Default update config are taken from computer policy.
               
          .PARAMETER MicrosoftUpdate
               Set Microsoft Update Server as source. Default update config are taken from computer policy.
               
          .PARAMETER ListOnly
               Show list of updates only without downloading and installing.
          
          .PARAMETER DownloadOnly
               Show list and download approved updates but do not install it. 
          
          .PARAMETER AcceptAll
               Do not ask for confirmation updates. Install all available updates.
          
          .PARAMETER AutoReboot
               Do not ask for rebbot if it needed.
          
          .PARAMETER IgnoreReboot
               Do not ask for reboot if it needed, but do not reboot automaticaly. 
          
          .PARAMETER AutoSelectOnly  
               Install only the updates that have status AutoSelectOnWebsites on true.
               
          .PARAMETER Debuger	
          Debug mode.
          .EXAMPLE
               Get all updates available and install. User intervention are required
               Get-WindowsUpdatesInstall

          .EXAMPLE
               Get info about updates and show only title. Not download and not install
               Get-WindowsUpdatesInstall -ListOnly | Select-Object Title
               Output:
                    Title                                                                                                                          
                    -----                                                                                                                          
                    2022-02 Vista previa de actualización acumulativa de .NET Framework 3.5 y 4.8 para Windows 10 Version 20H2 para x64 (KB5010472)
                    VMware, Inc. - Display - 8.17.2.14                                                                                             
                    2022-03 Actualización de Windows 10 Version 20H2 para x64 sistemas basados en (KB4023057)     
          
          .EXAMPLE
               Get Updates type software (no drivers) , install updates without user intervention and without reboot. 
               Get-WindowsUpdatesInstall -AcceptAll -WindowsUpdate -IgnoreReboot -UpdateType Software
               Output:
               "Block1"
                    Title  : 2022-03 Actualización de Windows 10 Version 20H2 para x64 sistemas basados en (KB4023057)
                    X      : 2
                    Status : Accepted
                    Size   : 3 MB
                    KB     : KB4023057
               "Block1" repeat changed status to "Downloaded" and "Installed"
                    
                    Reboot is required, but do it manually.

          #>
          [OutputType('PSWindowsUpdate.WUInstall')]
          [CmdletBinding(
               SupportsShouldProcess=$True,
               ConfirmImpact="High"
          )]	
          Param
          (
               #Pre search criteria
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [ValidateSet("Driver", "Software")]
               [String]$UpdateType="",
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [String[]]$UpdateID,
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [Int]$RevisionNumber,
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [String[]]$CategoryIDs,
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [Switch]$IsInstalled,
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [Switch]$IsHidden,
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [Switch]$WithHidden,
               [String]$Criteria,
               [Switch]$ShowSearchCriteria,

               #Post search criteria
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [String[]]$Category="",
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [String[]]$KBArticleID,
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [String]$Title,

               [parameter(ValueFromPipelineByPropertyName=$true)]
               [String[]]$NotCategory="",
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [String[]]$NotKBArticleID,
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [String]$NotTitle,

               [parameter(ValueFromPipelineByPropertyName=$true)]
               [Alias("Silent")]
               [Switch]$IgnoreUserInput,
               [parameter(ValueFromPipelineByPropertyName=$true)]
               [Switch]$IgnoreRebootRequired,

               #Connection options
               [String]$ServiceID,
               [Switch]$WindowsUpdate,
               [Switch]$MicrosoftUpdate,

               #Mode options
               [Switch]$ListOnly,
               [Switch]$DownloadOnly,
               [Alias("All")]
               [Switch]$AcceptAll,
               [Switch]$AutoReboot,
               [Switch]$IgnoreReboot,
               [Switch]$AutoSelectOnly,
               [Switch]$Debuger
          )

          Begin
          {
               If($PSBoundParameters['Debuger'])
               {
                    $DebugPreference = "Continue"
               } 

               $User = [Security.Principal.WindowsIdentity]::GetCurrent()
               $Role = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

               if(!$Role)
               {
                    Write-Warning "To perform some operations you must run an elevated Windows PowerShell console."	
               } 
          }

          Process
          {
               

               Write-Debug "STAGE 0: Prepare environment"
               If($IsInstalled)
               {
                    $ListOnly = $true
                    Write-Debug "Change to ListOnly mode"
               } 

               Write-Debug "Check reboot status only for local instance"
               Try
               {
                    $objSystemInfo = New-Object -ComObject "Microsoft.Update.SystemInfo"	
                    If($objSystemInfo.RebootRequired)
                    {
                         Write-Warning "Reboot is required to continue"
                         If($AutoReboot)
                         {
                              Restart-Computer -Force
                         } 

                         If(!$ListOnly)
                         {
                              Return
                         } 

                    } 
               } 
               Catch
               {
                    Write-Warning "Support local instance only, Continue..."
               } 

               Write-Debug "Set number of stage"
               If($ListOnly)
               {
                    $NumberOfStage = 2
               } 
               ElseIf($DownloadOnly)
               {
                    $NumberOfStage = 3
               } 
               Else
               {
                    $NumberOfStage = 4
               } 

                         

               Write-Debug "STAGE 1: Get updates list"
               Write-Debug "Create Microsoft.Update.ServiceManager object"
               $objServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager" 

               Write-Debug "Create Microsoft.Update.Session object"
               $objSession = New-Object -ComObject "Microsoft.Update.Session" 

               Write-Debug "Create Microsoft.Update.Session.Searcher object"
               $objSearcher = $objSession.CreateUpdateSearcher()

               If($WindowsUpdate)
               {
                    Write-Debug "Set source of updates to Windows Update"
                    $objSearcher.ServerSelection = 2
                    $serviceName = "Windows Update"
               } 
               ElseIf($MicrosoftUpdate)
               {
                    Write-Debug "Set source of updates to Microsoft Update"
                    $serviceName = $null
                    Foreach ($objService in $objServiceManager.Services) 
                    {
                         If($objService.Name -eq "Microsoft Update")
                         {
                              $objSearcher.ServerSelection = 3
                              $objSearcher.ServiceID = $objService.ServiceID
                              $serviceName = $objService.Name
                              Break
                         }
                    }

                    If(-not $serviceName)
                    {
                         Write-Warning "Can't find registered service Microsoft Update. Use Get-WUServiceManager to get registered service."
                         Return
                    }
               } 
               Else
               {
                    Foreach ($objService in $objServiceManager.Services) 
                    {
                         If($ServiceID)
                         {
                              If($objService.ServiceID -eq $ServiceID)
                              {
                                   $objSearcher.ServiceID = $ServiceID
                                   $objSearcher.ServerSelection = 3
                                   $serviceName = $objService.Name
                                   Break
                              } 
                         } 
                         Else
                         {
                              If($objService.IsDefaultAUService -eq $True)
                              {
                                   $serviceName = $objService.Name
                                   Break
                              } 
                         } 
                    } 
               } 
               Write-Debug "Set source of updates to $serviceName"

               Write-Verbose "Connecting to $serviceName server. Please wait..."
               Try
               {
                    $search = ""

                    If($Criteria)
                    {
                         $search = $Criteria
                    } 
                    Else
                    {
                         If($IsInstalled) 
                         {
                              $search = "IsInstalled = 1"
                              Write-Debug "Set pre search criteria: IsInstalled = 1"
                         } 
                         Else
                         {
                              $search = "IsInstalled = 0"	
                              Write-Debug "Set pre search criteria: IsInstalled = 0"
                         } 

                         If($UpdateType -ne "")
                         {
                              Write-Debug "Set pre search criteria: Type = $UpdateType"
                              $search += " and Type = '$UpdateType'"
                         } 					

                         If($UpdateID)
                         {
                              Write-Debug "Set pre search criteria: UpdateID = '$([string]::join(", ", $UpdateID))'"
                              $tmp = $search
                              $search = ""
                              $LoopCount = 0
                              Foreach($ID in $UpdateID)
                              {
                                   If($LoopCount -gt 0)
                                   {
                                        $search += " or "
                                   } 
                                   If($RevisionNumber)
                                   {
                                        Write-Debug "Set pre search criteria: RevisionNumber = '$RevisionNumber'"	
                                        $search += "($tmp and UpdateID = '$ID' and RevisionNumber = $RevisionNumber)"
                                   } 
                                   Else
                                   {
                                        $search += "($tmp and UpdateID = '$ID')"
                                   } 
                                   $LoopCount++
                              } 
                         } 

                         If($CategoryIDs)
                         {
                              Write-Debug "Set pre search criteria: CategoryIDs = '$([string]::join(", ", $CategoryIDs))'"
                              $tmp = $search
                              $search = ""
                              $LoopCount =0
                              Foreach($ID in $CategoryIDs)
                              {
                                   If($LoopCount -gt 0)
                                   {
                                        $search += " or "
                                   } 
                                   $search += "($tmp and CategoryIDs contains '$ID')"
                                   $LoopCount++
                              } 
                         } 

                         If($IsHidden) 
                         {
                              Write-Debug "Set pre search criteria: IsHidden = 1"
                              $search += " and IsHidden = 1"	
                         } 
                         ElseIf($WithHidden) 
                         {
                              Write-Debug "Set pre search criteria: IsHidden = 1 and IsHidden = 0"
                         } 
                         Else
                         {
                              Write-Debug "Set pre search criteria: IsHidden = 0"
                              $search += " and IsHidden = 0"	
                         } 

                         
                         If($IgnoreRebootRequired) 
                         {
                              Write-Debug "Set pre search criteria: RebootRequired = 0"
                              $search += " and RebootRequired = 0"	
                         } 
                    } 

                    Write-Debug "Search criteria is: $search"

                    If($ShowSearchCriteria)
                    {
                         Write-Output $search
                    } 

                    $objResults = $objSearcher.Search($search)
               } 
               Catch
               {
                    If($_ -match "HRESULT: 0x80072EE2")
                    {
                         Write-Warning "Probably you don't have connection to Windows Update server"
                    } 
                    Return
               } 

               $objCollectionUpdate = New-Object -ComObject "Microsoft.Update.UpdateColl" 

               $NumberOfUpdate = 1
               $UpdateCollection = @()
               $UpdatesExtraDataCollection = @{}
               $PreFoundUpdatesToDownload = $objResults.Updates.count
               Write-Verbose "Found [$PreFoundUpdatesToDownload] Updates in pre search criteria"				

               Foreach($Update in $objResults.Updates)
               {	
                    $UpdateAccess = $true
                    Write-Progress -Activity "Post search updates for $Computer" -Status "[$NumberOfUpdate/$PreFoundUpdatesToDownload] $($Update.Title) $size" -PercentComplete ([int]($NumberOfUpdate/$PreFoundUpdatesToDownload * 100))
                    Write-Debug "Set post search criteria: $($Update.Title)"

                    If($Category -ne "")
                    {
                         $UpdateCategories = $Update.Categories | Select-Object Name
                         Write-Debug "Set post search criteria: Categories = '$([string]::join(", ", $Category))'"	
                         Foreach($Cat in $Category)
                         {
                              If(!($UpdateCategories -match $Cat))
                              {
                                   Write-Debug "UpdateAccess: false"
                                   $UpdateAccess = $false
                              } 
                              Else
                              {
                                   $UpdateAccess = $true
                                   Break
                              } 
                         } 	
                    } 

                    If($NotCategory -ne "" -and $UpdateAccess -eq $true)
                    {
                         $UpdateCategories = $Update.Categories | Select-Object Name
                         Write-Debug "Set post search criteria: NotCategories = '$([string]::join(", ", $NotCategory))'"	
                         Foreach($Cat in $NotCategory)
                         {
                              If($UpdateCategories -match $Cat)
                              {
                                   Write-Debug "UpdateAccess: false"
                                   $UpdateAccess = $false
                                   Break
                              } 
                         } 	
                    } 					

                    If($null -ne $KBArticleID -and $UpdateAccess -eq $true)
                    {
                         Write-Debug "Set post search criteria: KBArticleIDs = '$([string]::join(", ", $KBArticleID))'"
                         If(!($KBArticleID -match $Update.KBArticleIDs -and "" -ne $Update.KBArticleIDs))
                         {
                              Write-Debug "UpdateAccess: false"
                              $UpdateAccess = $false
                         } 								
                    } 
                    If($null -ne $NotKBArticleID -and $UpdateAccess -eq $true)
                    {
                         Write-Debug "Set post search criteria: NotKBArticleIDs = '$([string]::join(", ", $NotKBArticleID))'"
                         If($NotKBArticleID -match $Update.KBArticleIDs -and "" -ne $Update.KBArticleIDs)
                         {
                              Write-Debug "UpdateAccess: false"
                              $UpdateAccess = $false
                         } 				
                    } 

                    If($Title -and $UpdateAccess -eq $true)
                    {
                         Write-Debug "Set post search criteria: Title = '$Title'"
                         If($Update.Title -notmatch $Title)
                         {
                              Write-Debug "UpdateAccess: false"
                              $UpdateAccess = $false
                         } 
                    } 

                    If($NotTitle -and $UpdateAccess -eq $true)
                    {
                         Write-Debug "Set post search criteria: NotTitle = '$NotTitle'"
                         If($Update.Title -match $NotTitle)
                         {
                              Write-Debug "UpdateAccess: false"
                              $UpdateAccess = $false
                         } 
                    } 

                    If($IgnoreUserInput -and $UpdateAccess -eq $true)
                    {
                         Write-Debug "Set post search criteria: CanRequestUserInput"
                         If($Update.InstallationBehavior.CanRequestUserInput -eq $true)
                         {
                              Write-Debug "UpdateAccess: false"
                              $UpdateAccess = $false
                         } 
                    } 

                    If($IgnoreRebootRequired -and $UpdateAccess -eq $true) 
                    {
                         Write-Debug "Set post search criteria: RebootBehavior"
                         If($Update.InstallationBehavior.RebootBehavior -ne 0)
                         {
                              Write-Debug "UpdateAccess: false"
                              $UpdateAccess = $false
                         } 
                    } 

                    If($UpdateAccess -eq $true)
                    {
                         Write-Debug "Convert size"
                         Switch($Update.MaxDownloadSize)
                         {
                              {[System.Math]::Round($_/1KB,0) -lt 1024} { $size = [String]([System.Math]::Round($_/1KB,0))+" KB"; break }
                              {[System.Math]::Round($_/1MB,0) -lt 1024} { $size = [String]([System.Math]::Round($_/1MB,0))+" MB"; break }  
                              {[System.Math]::Round($_/1GB,0) -lt 1024} { $size = [String]([System.Math]::Round($_/1GB,0))+" GB"; break }    
                              {[System.Math]::Round($_/1TB,0) -lt 1024} { $size = [String]([System.Math]::Round($_/1TB,0))+" TB"; break }
                              default { $size = $_+"B" }
                         } 

                         Write-Debug "Convert KBArticleIDs"
                         If($Update.KBArticleIDs -ne "")    
                         {
                              $KB = "KB"+$Update.KBArticleIDs
                         } 
                         Else 
                         {
                              $KB = ""
                         } 

                         If($ListOnly)
                         {
                              $Status = ""
                              If($Update.IsDownloaded)    {$Status += "D"} else {$status += "-"}
                              If($Update.IsInstalled)     {$Status += "I"} else {$status += "-"}
                              If($Update.IsMandatory)     {$Status += "M"} else {$status += "-"}
                              If($Update.IsHidden)        {$Status += "H"} else {$status += "-"}
                              If($Update.IsUninstallable) {$Status += "U"} else {$status += "-"}
                              If($Update.IsBeta)          {$Status += "B"} else {$status += "-"} 

                              Add-Member -InputObject $Update -MemberType NoteProperty -Name ComputerName -Value $env:COMPUTERNAME
                              Add-Member -InputObject $Update -MemberType NoteProperty -Name KB -Value $KB
                              Add-Member -InputObject $Update -MemberType NoteProperty -Name Size -Value $size
                              Add-Member -InputObject $Update -MemberType NoteProperty -Name Status -Value $Status
                              Add-Member -InputObject $Update -MemberType NoteProperty -Name X -Value 1

                              $Update.PSTypeNames.Clear()
                              $Update.PSTypeNames.Add('PSWindowsUpdate.WUInstall')
                              $UpdateCollection += $Update
                         } 
                         Else
                         {
                              $objCollectionUpdate.Add($Update) | Out-Null
                              $UpdatesExtraDataCollection.Add($Update.Identity.UpdateID,@{KB = $KB; Size = $size})
                         } 
                    } 

                    $NumberOfUpdate++
               } 				
               Write-Progress -Activity "[1/$NumberOfStage] Post search updates" -Status "Completed" -Completed

               If($ListOnly)
               {
                    $FoundUpdatesToDownload = $UpdateCollection.count
               } 
               Else
               {
                    $FoundUpdatesToDownload = $objCollectionUpdate.count				
               } 
               Write-Verbose "Found [$FoundUpdatesToDownload] Updates in post search criteria"

               If($FoundUpdatesToDownload -eq 0)
               {
                    Return
               } 

               If($ListOnly)
               {
                    Write-Debug "Return only list of updates"
                    Return $UpdateCollection				
               } 

               If(!$ListOnly) 
               {
               

                    Write-Debug "STAGE 2: Choose updates"			
                    $NumberOfUpdate = 1
                    $logCollection = @()

                    $objCollectionChoose = New-Object -ComObject "Microsoft.Update.UpdateColl"

                    Foreach($Update in $objCollectionUpdate)
                    {	
                         $size = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].Size
                         Write-Progress -Activity "[2/$NumberOfStage] Choose updates" -Status "[$NumberOfUpdate/$FoundUpdatesToDownload] $($Update.Title) $size" -PercentComplete ([int]($NumberOfUpdate/$FoundUpdatesToDownload * 100))
                         Write-Debug "Show update to accept: $($Update.Title)"

                         If($AcceptAll)
                         {
                              $Status = "Accepted"

                              If($Update.EulaAccepted -eq 0)
                              { 
                                   Write-Debug "Accept Eula"
                                   $Update.AcceptEula() 
                              } 

                              Write-Debug "Add update to collection"
                              $objCollectionChoose.Add($Update) | Out-Null
                         } 
                         ElseIf($AutoSelectOnly)  
                         {  
                              If($Update.AutoSelectOnWebsites)  
                              {  
                                   $Status = "Accepted"  
                                   If($Update.EulaAccepted -eq 0)  
                                   {  
                                        Write-Debug "Accept Eula"  
                                        $Update.AcceptEula()  
                                   } 

                                   Write-Debug "Add update to collection"  
                                   $objCollectionChoose.Add($Update) | Out-Null  
                              }  
                              Else  
                              {  
                                   $Status = "Rejected"  
                              } 
                         } 
                         Else
                         {
                              If($pscmdlet.ShouldProcess($Env:COMPUTERNAME,"$($Update.Title)[$size]?")) 
                              {
                                   $Status = "Accepted"

                                   If($Update.EulaAccepted -eq 0)
                                   { 
                                        Write-Debug "Accept Eula"
                                        $Update.AcceptEula() 
                                   } 
                                   Write-Debug "Add update to collection"
                                   $objCollectionChoose.Add($Update) | Out-Null 
                              } 
                              Else
                              {
                                   $Status = "Rejected"
                              } 
                         } 

                         Write-Debug "Add to log collection"
                         $log = New-Object PSObject -Property @{
                              Title = $Update.Title
                              KB = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].KB
                              Size = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].Size
                              Status = $Status
                              X = 2
                         } 

                         $log.PSTypeNames.Clear()
                         $log.PSTypeNames.Add('PSWindowsUpdate.WUInstall')

                         $logCollection += $log

                         $NumberOfUpdate++
                    } 
                    Write-Progress -Activity "[2/$NumberOfStage] Choose updates" -Status "Completed" -Completed

                    Write-Debug "Show log collection"
                    $logCollection


                    $AcceptUpdatesToDownload = $objCollectionChoose.count
                    Write-Verbose "Accept [$AcceptUpdatesToDownload] Updates to Download"

                    If($AcceptUpdatesToDownload -eq 0)
                    {
                         Return
                    } 	

          

                    Write-Debug "STAGE 3: Download updates"
                    $NumberOfUpdate = 1
                    $objCollectionDownload = New-Object -ComObject "Microsoft.Update.UpdateColl" 

                    Foreach($Update in $objCollectionChoose)
                    {
                         Write-Progress -Activity "[3/$NumberOfStage] Downloading updates" -Status "[$NumberOfUpdate/$AcceptUpdatesToDownload] $($Update.Title) $size" -PercentComplete ([int]($NumberOfUpdate/$AcceptUpdatesToDownload * 100))
                         Write-Debug "Show update to download: $($Update.Title)"

                         Write-Debug "Send update to download collection"
                         $objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
                         $objCollectionTmp.Add($Update) | Out-Null

                         $Downloader = $objSession.CreateUpdateDownloader() 
                         $Downloader.Updates = $objCollectionTmp
                         Try
                         {
                              Write-Debug "Try download update"
                              $DownloadResult = $Downloader.Download()
                         } 
                         Catch
                         {
                              If($_ -match "HRESULT: 0x80240044")
                              {
                                   Write-Warning "Your security policy don't allow a non-administator identity to perform this task"
                              } 

                              Return
                         } 

                         Write-Debug "Check ResultCode"
                         Switch -exact ($DownloadResult.ResultCode)
                         {
                              0   { $Status = "NotStarted" }
                              1   { $Status = "InProgress" }
                              2   { $Status = "Downloaded" }
                              3   { $Status = "DownloadedWithErrors" }
                              4   { $Status = "Failed" }
                              5   { $Status = "Aborted" }
                         } 
                         Write-Debug "Add to log collection"
                         $log = New-Object PSObject -Property @{
                              Title = $Update.Title
                              KB = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].KB
                              Size = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].Size
                              Status = $Status
                              X = 3
                         } 

                         $log.PSTypeNames.Clear()
                         $log.PSTypeNames.Add('PSWindowsUpdate.WUInstall')

                         $log

                         If($DownloadResult.ResultCode -eq 2)
                         {
                              Write-Debug "Downloaded then send update to next stage"
                              $objCollectionDownload.Add($Update) | Out-Null
                         } 

                         $NumberOfUpdate++

                    } 
                    Write-Progress -Activity "[3/$NumberOfStage] Downloading updates" -Status "Completed" -Completed

                    $ReadyUpdatesToInstall = $objCollectionDownload.count
                    Write-Verbose "Downloaded [$ReadyUpdatesToInstall] Updates to Install"

                    If($ReadyUpdatesToInstall -eq 0)
                    {
                         Return
                    } 


                    If(!$DownloadOnly)
                    {
                         

                         Write-Debug "STAGE 4: Install updates"
                         $NeedsReboot = $false
                         $NumberOfUpdate = 1

                         #install updates	
                         Foreach($Update in $objCollectionDownload)
                         {   
                              Write-Progress -Activity "[4/$NumberOfStage] Installing updates" -Status "[$NumberOfUpdate/$ReadyUpdatesToInstall] $($Update.Title)" -PercentComplete ([int]($NumberOfUpdate/$ReadyUpdatesToInstall * 100))
                              Write-Debug "Show update to install: $($Update.Title)"

                              Write-Debug "Send update to install collection"
                              $objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
                              $objCollectionTmp.Add($Update) | Out-Null

                              $objInstaller = $objSession.CreateUpdateInstaller()
                              $objInstaller.Updates = $objCollectionTmp

                              Try
                              {
                                   Write-Debug "Try install update"
                                   $InstallResult = $objInstaller.Install()
                              } 
                              Catch
                              {
                                   If($_ -match "HRESULT: 0x80240044")
                                   {
                                        Write-Warning "Your security policy don't allow a non-administator identity to perform this task"
                                   } 

                                   Return
                              } 

                              If(!$NeedsReboot) 
                              { 
                                   Write-Debug "Set instalation status RebootRequired"
                                   $NeedsReboot = $installResult.RebootRequired 
                              } 

                              Switch -exact ($InstallResult.ResultCode)
                              {
                                   0   { $Status = "NotStarted"}
                                   1   { $Status = "InProgress"}
                                   2   { $Status = "Installed"}
                                   3   { $Status = "InstalledWithErrors"}
                                   4   { $Status = "Failed"}
                                   5   { $Status = "Aborted"}
                              } 

                              Write-Debug "Add to log collection"
                              $log = New-Object PSObject -Property @{
                                   Title = $Update.Title
                                   KB = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].KB
                                   Size = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].Size
                                   Status = $Status
                                   X = 4
                              } 

                              $log.PSTypeNames.Clear()
                              $log.PSTypeNames.Add('PSWindowsUpdate.WUInstall')

                              $log

                              $NumberOfUpdate++
                         } 
                         Write-Progress -Activity "[4/$NumberOfStage] Installing updates" -Status "Completed" -Completed

                         If($NeedsReboot)
                         {
                              If($AutoReboot)
                              {
                                   Restart-Computer -Force
                              } 
                              ElseIf($IgnoreReboot)
                              {
                                   Return "Reboot is required, but do it manually."
                              } 
                              Else
                              {
                                   $Reboot = Read-Host "Reboot is required. Do it now ? [Y/N]"
                                   If($Reboot -eq "Y")
                                   {
                                        Restart-Computer -Force
                                   } 
                              } 

                         } 

                         
                    } 
               } 
          } 

          End{}		
     }
     
     #Add registry entries
     Set-ItemProperty $RegPath "Repair2" -Value '1' -type String
     Set-ItemProperty $RegPath "Repair2Date" -Value $(get-date) -type String
     try {	
          # Note which energy plan is allocated to you
          $energyPlan = (powercfg /getactivescheme).Split("")[5]

          # Change the energy plan to High Performance
          powercfg.exe -SETACTIVE 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

          # I request available software updates, from the internet silently and without rebooting. 
          $launch = Get-WindowsUpdatesInstall -AcceptAll -IgnoreReboot -UpdateType Software -WindowsUpdate  #To use a WSUS server, change the -WindowsUpdate option to -MicrosoftUpdate
          $msgOut = @()
          foreach ($Item in $launch) {
               if($item.status -eq 'Installed' -and $Item.Title  -notmatch 'Defender'){$msgOut += $item.title}
          }
          if($msgOut){Write-Output $msgOut}else{Write-Output 'Repari2 found 0 downloads'; exit 1}

          #I return to the energy configuration I had at the beginning. 
          powercfg.exe -SETACTIVE $energyPlan
          Write-Output 'Repair2 implemented'
          Exit 0
     }
     Catch {
          Write-Output 'Fail to implemented repair2'
          Exit 1
     }

}

### Repair3 in development