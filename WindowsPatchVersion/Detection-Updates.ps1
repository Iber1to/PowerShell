#Declare Functions
function Get-WindowsVersion{
    [CmdletBinding()]
    
    Param
    (
        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromPipeline=$true
                    )]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )
    
    
    Begin
    {
        $Table = New-Object System.Data.DataTable
        $Table.Columns.AddRange(@("ComputerName","Windows Edition","Version","OS Build","CurrentBuild","Update"))
    }
    Process
    {
        Foreach ($Computer in $ComputerName)
        {
            $Code = {
                $ProductName = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ProductName).ProductName
                Try
                {
                    $Version = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID -ErrorAction Stop).ReleaseID
                }
                Catch
                {
                    $Version = "N/A"
                }
                $CurrentBuild = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuild).CurrentBuild
                $UBR = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name UBR).UBR
                $OSVersion = $CurrentBuild + "." + $UBR
    
                $TempTable = New-Object System.Data.DataTable
                $TempTable.Columns.AddRange(@("ComputerName","Windows Edition","Version","OS Build","CurrentBuild","Update"))
                [void]$TempTable.Rows.Add($env:COMPUTERNAME,$ProductName,$Version,$OSVersion,$CurrentBuild,$UBR)
            
                Return $TempTable
            }
    
            If ($Computer -eq $env:COMPUTERNAME)
            {
                $Result = Invoke-Command -ScriptBlock $Code
                [void]$Table.Rows.Add($Result.Computername,$Result.'Windows Edition',$Result.Version,$Result.'OS Build', $Result.CurrentBuild, $Result.Update)
            }
            Else
            {
                Try
                {
                    $Result = Invoke-Command -ComputerName $Computer -ScriptBlock $Code -ErrorAction Stop
                    [void]$Table.Rows.Add($Result.Computername,$Result.'Windows Edition',$Result.Version,$Result.'OS Build', $Result.CurrentBuild, $Result.Update)
                }
                Catch
                {
                    $_
                }
            }
    
        }
    
    }
    End
    {
        Return $Table
    }
    }
function Get-PatchTuesday{
        [CmdletBinding()]
        Param
        (
          [Parameter(position = 0)]
          [ValidateSet("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")]
          [String]$weekDay = 'Tuesday',
          [ValidateRange(0, 5)]
          [Parameter(position = 1)]
          [int]$findNthDay = 2
        )
        # Get the date and find the first day of the month
        # Find the first instance of the given weekday
        [datetime]$today = [datetime]::NOW
        $todayM = $today.Month.ToString()
        $todayY = $today.Year.ToString()
        [datetime]$strtMonth = $todayM + '/1/' + $todayY
        while ($strtMonth.DayofWeek -ine $weekDay ) { $strtMonth = $StrtMonth.AddDays(1) }
        $firstWeekDay = $strtMonth
      
        # Identify and calculate the day offset
        if ($findNthDay -eq 1) {
          $dayOffset = 0
        }
        else {
          $dayOffset = ($findNthDay - 1) * 7
        }
        
        # Return date of the day/instance specified
        $patchTuesday = $firstWeekDay.AddDays($dayOffset) 
        return $patchTuesday
      }
function Test-Reg {
    $eval = Test-Path -Path $regPath
    return $eval   
}
function msgOutput {
    $msgOutput = $finalState.Mes+' '+ $finalState.Year
    Write-Output $msgOutput     
}

#Declare Vars
$uriW10 = 'https://support.microsoft.com/en-us/topic/windows-10-update-history-857b8ccb-71e4-49e5-b3f6-7073197d98fb' # Url to extract patch W10
$uriW11 = 'https://support.microsoft.com/en-us/topic/windows-11-update-history-a19cd327-b57f-44b9-84e0-26ced7109ba9' # Url to extract patch W11
$computerBuildVersion = get-WindowsVersion
$timeValidUpdates = -2 # Maximum number of months for the patch to be considered as valid
$regPath = 'HKLM:\SOFTWARE\Iber0\UpdateState\' # Record Output last executión
if ($(Test-Reg) -eq $false){try{New-Item -Path 'HKLM:\SOFTWARE\Iber0\UpdateState\' -Force}catch{write-Output 'Fail to modify registry'}}

#calc last month valid
if($(get-date) -gt $(Get-PatchTuesday)){$monthpatch = 1 + $timeValidUpdates}else{$monthpatch = $timeValidUpdates}
#Construct month valid
$monthValidYear = $((get-date).AddMonths($monthpatch)).Year
$monthValidMonth = $((get-date).AddMonths($monthpatch)).Month
$monthValidDate = get-date -Date "$monthValidYear-$monthValidMonth-01"

#Load updates list
$pageW10 = Invoke-WebRequest -Uri $uriW10 -UseBasicParsing
$preOSbuild = $pageW10.Links | Where-Object -FilterScript {($_.outerHTML -match 'OS Build')}
$pageW11 = Invoke-WebRequest -Uri $uriW11 -UseBasicParsing
$preOSbuild += $pageW11.Links | Where-Object -FilterScript {($_.outerHTML -match 'OS Build')}

#Processing the captured data
$listUpdatesWindows = @()
foreach ($item in $preOSbuild) {   
    foreach($char in  $item.outerHTML.Replace(' ','').replace('OSBuild','').replace('s','').replace('and',',').split('('')')[1].split(','))
        {
            if($char){
                try{
                    $date = ($item.outerHTML.split('>'',')[1]) + ' ' + ($item.outerHTML.split(',''&')[1].trim())
                    [datetime]$date | Out-Null
                }
                Catch{
                    $date = ($item.outerHTML.split('>'',')[1]) + ' ' + ($item.outerHTML.split(',''-')[4].trim())
                    try{[datetime]$date | Out-Null}catch{$date = '1 1 1900'}
                }
                $update= New-Object -TypeName PSObject
                $update | Add-Member -MemberType NoteProperty  -Name 'Fecha' -Value $([datetime]$date)
                $update | Add-Member -MemberType NoteProperty  -Name 'OsBuild' -Value $char
                $listUpdatesWindows += $update
            }
        }
}
$listUpdatesWindows = $listUpdatesWindows | Select-Object 'Fecha', 'OsBuild' -Unique

#Search computer Build in list
foreach ($item in $listUpdatesWindows) {
    if($item.OsBuild -eq $computerBuildVersion.'OS Build'){
        $computerBuildVersion | Add-Member -MemberType NoteProperty  -Name 'Fecha' -Value $item.fecha -Force
    }
}

#Check if is valid update
if($computerBuildVersion.Fecha){
    $finalState  = New-Object -TypeName PSObject
    $finalState | Add-Member -MemberType NoteProperty  -Name 'Mes' -Value $((Get-Culture).DateTimeFormat.GetMonthName($computerBuildVersion.Fecha.Month).ToUpper())
    $finalState | Add-Member -MemberType NoteProperty  -Name 'Year' -Value $computerBuildVersion.Fecha.Year
    Set-ItemProperty $RegPath "Year" -Value $($computerBuildVersion.Fecha.Year) -type String
    Set-ItemProperty $RegPath "Month" -Value $($computerBuildVersion.Fecha.Month) -type String
    if($computerBuildVersion.Fecha -gt $monthValidDate){
        $finalState | Add-Member -MemberType NoteProperty  -Name 'UpdateValid' -Value 'OK'
        Set-ItemProperty $RegPath "UpdateValid" -Value 'OK' -type String
        Set-ItemProperty $RegPath "Repair1" -Value '0' -type String
        Set-ItemProperty $RegPath "Repair2" -Value '0' -type String
        Set-ItemProperty $RegPath "Repair3" -Value '0' -type String
        msgOutput
        exit 0
     }
    else{
        $finalState | Add-Member -MemberType NoteProperty  -Name 'UpdateValid' -Value 'FAIL'
        Set-ItemProperty $RegPath "UpdateValid" -Value 'FAIL' -type String
        msgOutput
        exit 1
    }
}
else{
    Write-Output $computerBuildVersion.'OS Build'
    Exit 1
    }