#region "Transcript parameters"
$logpath  = 'C:\Windows\Temp'
$username   = $env:USERNAME
$hostname   = hostname
$version    = $PSVersionTable.PSVersion.ToString()
$datetime   = Get-Date -f 'yyyyMMddHHmmss'
$scriptname = $MyInvocation.MyCommand.Name.Replace('.ps1', '') # Get file name without extension .ps1
$filename   = "Transcript-${scriptname}-${username}-${hostname}-${version}-${datetime}.txt"
$Transcript = Join-Path -Path $logpath -ChildPath $filename
#endregion "Transcript parameters"

#region "Procces"
Start-Transcript -Path $Transcript
$App001 = Get-Package | Where-Object {$_.Name -eq 'HP Wolf Security'}
$App002 = Get-Package | Where-Object {$_.Name -eq "HP Wolf Security - Console"}
$App003 = Get-Package | Where-Object {$_.Name -eq "HP Security Update Service"}
if ($App001 -or $App002 -or $App003) {
    Stop-Transcript
    Write-Host "App detected"
    exit 1
}else{
    Stop-Transcript
    Write-Host "Not App detected"
    exit 0
}
#endregion "Procces"