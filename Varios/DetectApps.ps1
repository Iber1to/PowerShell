$PSDefaultParameterValues['*:Encoding'] = 'utf8'

#Funcion para localizar el sofware instalado
function Get-InstalledApplications() {
    [cmdletbinding(DefaultParameterSetName = 'GlobalAndAllUsers')]

    Param (
        [Parameter(ParameterSetName="Global")]
        [switch]$Global,
        [Parameter(ParameterSetName="GlobalAndCurrentUser")]
        [switch]$GlobalAndCurrentUser,
        [Parameter(ParameterSetName="GlobalAndAllUsers")]
        [switch]$GlobalAndAllUsers,
        [Parameter(ParameterSetName="CurrentUser")]
        [switch]$CurrentUser,
        [Parameter(ParameterSetName="AllUsers")]
        [switch]$AllUsers
    )

    # Excplicitly set default param to True if used to allow conditionals to work
    if ($PSCmdlet.ParameterSetName -eq "GlobalAndAllUsers") {
        $GlobalAndAllUsers = $true
    }

    # Check if running with Administrative privileges if required
    if ($GlobalAndAllUsers -or $AllUsers) {
        $RunningAsAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($RunningAsAdmin -eq $false) {
            Write-Error "Finding all user applications requires administrative privileges"
            break
        }
    }

    # Empty array to store applications
    $Apps = @()
    $32BitPath = "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $64BitPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

    # Retreive globally insatlled applications
    if ($Global -or $GlobalAndAllUsers -or $GlobalAndCurrentUser) {
        # Write-Host "Processing global hive"
        $Apps += Get-ItemProperty "HKLM:\$32BitPath"
        $Apps += Get-ItemProperty "HKLM:\$64BitPath"
    }

    if ($CurrentUser -or $GlobalAndCurrentUser) {
        # Write-Host "Processing current user hive"
        $Apps += Get-ItemProperty "Registry::\HKEY_CURRENT_USER\$32BitPath"
        $Apps += Get-ItemProperty "Registry::\HKEY_CURRENT_USER\$64BitPath"
    }

    if ($AllUsers -or $GlobalAndAllUsers) {
        # Write-Host "Collecting hive data for all users"
        $AllProfiles = Get-CimInstance Win32_UserProfile | Select-Object LocalPath, SID, Loaded, Special | Where-Object {$_.SID -like "S-1-5-21-*"}
        $MountedProfiles = $AllProfiles | Where-Object {$_.Loaded -eq $true}
        $UnmountedProfiles = $AllProfiles | Where-Object {$_.Loaded -eq $false}

        # Write-Host "Processing mounted hives"
        $MountedProfiles | ForEach-Object {
            $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($_.SID)\$32BitPath"
            $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($_.SID)\$64BitPath"
        }

        # Write-Host "Processing unmounted hives"
        $UnmountedProfiles | ForEach-Object {

            $Hive = "$($_.LocalPath)\NTUSER.DAT"
            # Write-Host " -> Mounting hive at $Hive"

            if (Test-Path $Hive) {
            
                REG LOAD HKU\temp $Hive

                $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$32BitPath"
                $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$64BitPath"

                # Run manual GC to allow hive to be unmounted
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()
            
                REG UNLOAD HKU\temp

            } else {
                # Write-Warning "Unable to access registry hive at $Hive"
            }
        }
    }

    Write-Output $Apps
}

$OutputString = ""

##Inicio la eliminación del software instalado
#Eliminando Emule
$UninstallEmule = (Get-InstalledApplications | Where-Object Displayname -Like "*emule*").UninstallString
if($UninstallEmule){$OutputString +="Emule;"}

#Eliminando qBittorent
$UninstallqBittorent = (Get-InstalledApplications | Where-Object Displayname -Like "*qBittorrent*").UninstallString
if($UninstallqBittorent){$OutputString +="qBittorrent;"}

#Eliminando uTorrent
$UninstallUtorrent = ((Get-InstalledApplications | Where-Object Displayname -Like "*µTorrent*").UninstallString)
if($UninstallUtorrent){$OutputString +="µTorrent;"}


#Bloque para eliminar todas las Apps de PortableApps.
#Cargamos el listado de unidades de almacenamiento disponibles.
$ListDriveLetter = @()
$((Get-Volume).DriveLetter).foreach({if($_ -ne $null){$ListDriveLetter += "$_"+":\"}})

#Cargo un listado de todos los archivos y carpetas, en todos los discos para poder elminarlos. Este proceso se puede demorar dependiendo del rendimiento del dispositivo.
$DeviceContent = New-Object -TypeName "System.Collections.ArrayList"
$ListDriveLetter.ForEach({(Get-ChildItem -Path $_ -Recurse -ErrorAction SilentlyContinue).foreach({$DeviceContent.Add($_)})}) | Out-Null

#Inicio la eliminación del software portatil.
#Localizamos "PortableApps" y la borramos. "PortableApps" es la aplicación desde donde se pueden instalar el resto de aplicaciones portatiles.
$PortableAppsPath = $DeviceContent.Where({$_.name -eq "PortableApps"})
If($PortableAppsPath){$OutputString +="PortableApps;"}
#Borrando los archivos de instalación de todas las aplicaciones de "PortableApps".
$PortableAppsInstallPath = $DeviceContent.Where({$_.name -like "*.paf.exe"})
If($PortableAppsInstallPath){$OutputString +="paf;"}
#Borrando el lanzador de "PortableApps", el archivo "start.exe".
$PortableAppsStartPath = $DeviceContent.Where({$_.name -eq "Start.exe"})
If($PortableAppsStartPath){$OutputString +="Start;"}
#Reviso que no queden instalaciones individuales y las elimino.
<#
$PortableAppsAloneInstallPath = $DeviceContent.Where({$_.name -like "*Portable"})
If($PortableAppsAloneInstallPath){$PortableAppsAloneInstallPath.foreach({Remove-Item -Path $_.fullname -Recurse -Force -ErrorAction SilentlyContinue; Write-SimpleLog -Message "Se ha eliminado la instalación de $($_.name)" -LogLevel "INFO"})}
#>
#Eliminando MAME, tanto carpetas, como archivos de instalación. !!Aviso¡¡ en esta busqueda pueden eliminarse archivos no relacionados con el juego MAME, pero en ningun caso archivos de Windows. 
$MameFilesPath = $DeviceContent.Where({$_.name -like "*mame*"})
If($MameFilesPath){$OutputString +="mame;"}
#Localizando y borrando la carpeta de ROMS de MAME por si ha cambiado el nombre de la carpeta root. La carpeta roms no se le puede cambiar el nombre o el juego no funciona.
$MameRomsPath = $DeviceContent.Where({$_.name -eq "roms"})
If($MameRomsPath){$OutputString +="roms;"}

#Localizando y borrando la carpeta de HyperSpin.
$HyperSpinPath = $DeviceContent.Where({$_.name -eq "HyperSpin.exe"})
If($HyperSpinPath){$OutputString +="HyperSpin;"}


#Localizando y borrando la carpeta de Emule.
$EmulePath = $DeviceContent.Where({$_.name -eq "server.met"})
If($EmulePath){$OutputString +="server;"}
#Localizando y elimiando los archivos de instalacion de Emule. 
$EmuleInstallFiles = $DeviceContent.Where({$_.name -like "*Emule*"})
If($EmuleInstallFiles){$OutputString +="Emule;"}

#Localizando y elimiando los archivos de instalacion de torrents. 
$TorrentsInstallFiles = $DeviceContent.Where({$_.name -like "*torrent*"})
If($TorrentsInstallFiles){$OutputString +="torrent;"}


If($OutputString -ne ""){
    Write-Output $OutputString
    exit 1
}else{exit 0}