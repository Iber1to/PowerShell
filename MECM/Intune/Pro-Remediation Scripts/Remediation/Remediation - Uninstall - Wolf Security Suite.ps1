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

#region "Procces script"
Start-Transcript -Path $Transcript
 
try{Start-Process -filepath "wmic" -argumentlist 'product where name="HP Wolf Security" call uninstall' -wait -WindowStyle Hidden}
catch{ 
    Write-Host "$($_.Exception.Message)"
    Stop-Transcript
    }
try{Start-Process -filepath "wmic" -argumentlist 'product where name="HP Wolf Security - Console" call uninstall' -Wait -WindowStyle Hidden}
catch{ 
    Write-Host "$($_.Exception.Message)"
    Stop-Transcript
    }
try{Start-Process -filepath "wmic" -argumentlist 'product where name="HP Security Update Service" call uninstall' -Wait -WindowStyle Hidden}
catch{ 
    Write-Host "$($_.Exception.Message)"
    Stop-Transcript
    }
Stop-Transcript
#endregion "Procces"