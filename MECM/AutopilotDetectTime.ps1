$AppInstallDelay = New-TimeSpan -Days 0 -Hours 1 -Minutes 0

$ime = Get-Item "C:\Program Files (x86)\Microsoft Intune Management Extension" -ErrorAction SilentlyContinue | Select-Object Name, CreationTime 
$EnrolmentDate = $ime.creationtime
$futuredate = $EnrolmentDate + $AppInstallDelay
$outcome = $false
#checking date and futuredate
if($ime){
    $outcome = ((Get-Date) -ge ($futuredate))  
    
}
$outcome