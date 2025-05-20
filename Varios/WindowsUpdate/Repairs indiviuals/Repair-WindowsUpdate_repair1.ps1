# Deteniendo todos los servicios
Get-Service -Name wuauserv,bits,cryptsvc,msiserver,appidsvc | Stop-Service -Force

# Elimina todos los archivos qmgr.dat para limpiar los jobs de Bits atascados
Remove-Item -Path "$env:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\qmgr*.dat"

# Haciendo Backup a las carpetas de Windows Update cache para que genere el almacen de nuevo
Rename-Item -Path "$env:SYSTEMROOT\SoftwareDistribution\DataStore" -NewName 'DataStore.bak'
Rename-Item -Path "$env:SYSTEMROOT\SoftwareDistribution\Download" -NewName 'Download.bak'
Rename-Item -Path "$env:SYSTEMROOT\System32\catroot2" -NewName 'catroot2.bak'

# Reiniciando los descriptores de seguridad para los servicios BITS y Windows Update 
$null = Start-Process -FilePath 'sc.exe' -ArgumentList 'sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)'
$null = Start-Process -FilePath 'sc.exe' -ArgumentList 'sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)'

# Re-registrando las DLLs relacionadas con el Agente de Windows Update.
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

# Removiendo las entradas WSUS del registro de Windows
@('AccountDomainSid','PingID','SusClientId','SusClientIDValidation') | ForEach-Object {
     Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Name $_ -ErrorAction Ignore
}

# Reseteando la configuración de Winsock y WinHTTP
netsh winsock reset 
netsh winhttp reset proxy 

# Borrando trabajos de BITS atascados
$null = bitsadmin.exe /reset /allusers

# Reiniciando la ACL para WUA
$null = wuauclt.exe /resetauthorization

# Vuelvo a arrancar los servicios
Get-Service -Name wuauserv,bits,cryptsvc,appidsvc | Start-Service

# Reparar archivos dañados con DISM
$processOptionsDism = @{
     FilePath = "DISM.exe"
     ArgumentList = "/Online /Cleanup-Image /RestoreHealth"
 }
 Start-Process @processOptionsDism

<# Modulo de gestion para Windows Update
Install-Module PSWindowsUpdate -Force
Import-Module PSWindowsUpdate

Get-WUHistory #Get Windows Update history.
Get-WUHistory -MaxDate (Get-Date).AddDays(-1) # Get Windows Update Agent history for last 24h.
Get-WindowsUpdate #Get windows updates available from default service manager
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -ForceInstall -Verbose #Install all available updates from Microsoft Update 
#>
