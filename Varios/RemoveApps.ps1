<#
    .SYNOPSIS
    Este script elimina algunos programas e instalaciones individuales no deseados de un dispositivo.

    .DESCRIPTION
    Este script elimina programas e instalaciones individuales espec�ficos de un dispositivo. Adem�s, tambi�n elimina los archivos de instalaci�n de los programas, si se encuentran en el dispositivo. 
    El programa revisa todos los discos. 
    Los programas que se eliminan son:
    - PortableApps
    - MAME
    - HyperSpin
    - Emule
    - qBittorrent
    - uTorrent

    .PARAMETER 

    .EXAMPLE
    .\Remove-Apps.ps1
    Elimina los programas e instalaciones individuales no deseados del dispositivo.

    .NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: 16-02-2023
    Última modificación: 19-02-2023
    Versión:  1.0.1
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>

$PSDefaultParameterValues['*:Encoding'] = 'utf8'

<#
.SYNOPSIS
    Esta función se utiliza para escribir mensajes de registro en un archivo de registro en PowerShell.

.DESCRIPTION
    Esta función acepta dos parámetros: "Message" y "LogLevel". 
    "Message" es el mensaje que se escribirá en el archivo de registro, mientras que "LogLevel" es el nivel de registro para el mensaje, que puede ser "INFO", "WARNING" o "ERROR". 
    El valor predeterminado para "LogLevel" es "INFO" si no se especifica.

.PARAMETER LogLevel
    El nivel de registro para el mensaje. Los valores permitidos son "INFO", "WARNING" o "ERROR". El valor predeterminado es "INFO".

.PARAMETER Message
    El mensaje que se escribirá en el archivo de registro.

.EXAMPLE
    Write-SimpleLog -Message "This is an INFO message" -LogLevel "INFO"
    Write-SimpleLog -Message "This is a WARNING message" -LogLevel "WARNING"
    Write-SimpleLog -Message "This is an ERROR message" -LogLevel "ERROR"

.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: 17-02-2023
    Última modificación: 19-02-2023
    Versión:  1.0.1
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
    1.0.1: Se ha añadido la posibilidad de que el nombre del archivo de registro sea el nombre del equipo más el del script que lo llama.
#>
#Saco fuera la generacion del archivo de log para que este accesible luego en el output
# Generate log file name using script name and current date
$ScriptName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$HostName = ($env:COMPUTERNAME)
$HostName = $HostName.SubString(0,1).ToUpper()+$HostName.SubString(1).ToLower()
$LogFileName = $HostName+$ScriptName+"_"+$(Get-Date -Format 'yyyyMMdd')+".log"
$LogPath = "C:\ProgramData\RemoveappsLogs\$LogFileName"

function Write-SimpleLog([string]$Message, [ValidateSet("INFO", "WARNING", "ERROR")] [string]$LogLevel = "INFO") {
    

    # Create logs folder if it doesn't exist
    if (-not (Test-Path -Path "C:\ProgramData\RemoveappsLogs")) {
        New-Item -ItemType Directory -Path "C:\ProgramData\RemoveappsLogs" | Out-Null
    }

    # Format log message
    $CurrentTime = Get-Date -Format "HH:mm:ss.fff"
    $CurrentDate = Get-Date -Format "yyyy/MM/dd"
    $LogEntry = "[$LogLevel][$CurrentTime][$CurrentDate] $Message"

    # Append log message to log file
    Add-Content $LogPath -Value $LogEntry
}

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

Write-SimpleLog -Message "Iniciando el proceso de limpieza de aplicaciones" -LogLevel "INFO"
Write-SimpleLog -Message "Deteniendo todos los procesos de las aplicaciones a eliminar" -LogLevel "INFO"
#Matamos todos los procesos de las aplicaciones para que permita borrar despues las carpetas.
$ListProcess = "PortableAppsPlatform", "GIMP*", "ink*", "pidgin*", "qbitt*", "thunder*", "utorr*", "avide*", "libreca*", "Hyper*", "emule", "qbittorrent", "uto*"
$ListProcess.foreach({Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object{Stop-Process -Name $_.ProcessName -Force -ErrorAction SilentlyContinue}})

##Inicio la eliminación del software instalado
$Arguments = "/S"
#Eliminando Emule
$UninstallEmule = (Get-InstalledApplications | Where-Object Displayname -Like "*emule*").UninstallString
if($UninstallEmule){Start-Process $UninstallEmule $Arguments; Write-SimpleLog -Message "Se ha eliminado Emule" -LogLevel "INFO"}

#Eliminando qBittorent
$UninstallqBittorent = (Get-InstalledApplications | Where-Object Displayname -Like "*qBittorrent*").UninstallString
if($UninstallqBittorent){Start-Process $UninstallqBittorent $Arguments; Write-SimpleLog -Message "Se ha eliminado qBittorent" -LogLevel "INFO"}

#Eliminando uTorrent
$UninstallUtorrent = ((Get-InstalledApplications | Where-Object Displayname -Like "*µTorrent*").UninstallString)
if($UninstallUtorrent){$UninstallUtorrent = (($UninstallUtorrent.split("/")[0]).trim())}
$Arguments = "/UNINSTALL /S"
if($UninstallUtorrent){Start-Process $UninstallUtorrent.split("/")[0] $Arguments; Write-SimpleLog -Message "Se ha eliminado uTorrent" -LogLevel "INFO"}


#Bloque para eliminar todas las Apps de PortableApps.
#Cargamos el listado de unidades de almacenamiento disponibles.
$ListDriveLetter = @()
$((Get-Volume).DriveLetter).foreach({if($_ -ne $null){$ListDriveLetter += "$_"+":\"}})

Write-SimpleLog -Message "Escanenando archivos y directorios en todas las unicades conectadas" -LogLevel "INFO"
#Cargo un listado de todos los archivos y carpetas, en todos los discos para poder elminarlos. Este proceso se puede demorar dependiendo del rendimiento del dispositivo.
$DeviceContent = New-Object -TypeName "System.Collections.ArrayList"
$ListDriveLetter.ForEach({(Get-ChildItem -Path $_ -Recurse -ErrorAction SilentlyContinue).foreach({$DeviceContent.Add($_)})}) | Out-Null
Write-SimpleLog -Message "Se han encontrado $($DeviceContent.Count) archivos y directorios en todas las unidades conectadas" -LogLevel "INFO"

Write-SimpleLog -Message "Eliminando aplicaciones portatiles" -LogLevel "INFO"
#Inicio la eliminación del software portatil.
#Localizamos "PortableApps" y la borramos. "PortableApps" es la aplicación desde donde se pueden instalar el resto de aplicaciones portatiles.
$PortableAppsPath = $DeviceContent.Where({$_.name -eq "PortableApps"})
If($PortableAppsPath){
    Remove-Item -Path $PortableAppsPath.fullname -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path ($PortableAppsPath.root.name+"Documents") -Recurse -Force -ErrorAction SilentlyContinue
    Write-SimpleLog -Message "Se ha eliminado la carpeta de PortableApps" -LogLevel "INFO"}
#Borrando los archivos de instalación de todas las aplicaciones de "PortableApps".
$PortableAppsInstallPath = $DeviceContent.Where({$_.name -like "*.paf.exe"})
If($PortableAppsInstallPath){$PortableAppsInstallPath.foreach({Remove-Item -Path $_.fullname -Recurse -Force -ErrorAction SilentlyContinue; Write-SimpleLog -Message "Se ha eliminado el archivo de instalación de $($_.name)" -LogLevel "INFO"})}
#Borrando el lanzador de "PortableApps", el archivo "start.exe".
$PortableAppsStartPath = $DeviceContent.Where({$_.name -eq "Start.exe"})
If($PortableAppsStartPath){Remove-Item -Path $PortableAppsStartPath.fullname -Recurse -Force -ErrorAction SilentlyContinue; Write-SimpleLog -Message "Se ha eliminado el lanzador de PortableApps" -LogLevel "INFO"}
#Reviso que no queden instalaciones individuales y las elimino.
<#
$PortableAppsAloneInstallPath = $DeviceContent.Where({$_.name -like "*Portable"})
If($PortableAppsAloneInstallPath){$PortableAppsAloneInstallPath.foreach({Remove-Item -Path $_.fullname -Recurse -Force -ErrorAction SilentlyContinue; Write-SimpleLog -Message "Se ha eliminado la instalación de $($_.name)" -LogLevel "INFO"})}
#>
#Eliminando MAME, tanto carpetas, como archivos de instalación. !!Aviso¡¡ en esta busqueda pueden eliminarse archivos no relacionados con el juego MAME, pero en ningun caso archivos de Windows. 
$MameFilesPath = $DeviceContent.Where({$_.name -like "*mame*"})
If($MameFilesPath){$MameFilesPath.foreach({Remove-Item -Path $_.fullname -Recurse -Force -ErrorAction SilentlyContinue; Write-SimpleLog -Message "Se ha eliminado el archivo de instalación de $($_.name)" -LogLevel "INFO"})}
#Localizando y borrando la carpeta de ROMS de MAME por si ha cambiado el nombre de la carpeta root. La carpeta roms no se le puede cambiar el nombre o el juego no funciona.
$MameRomsPath = $DeviceContent.Where({$_.name -eq "roms"})
If($MameRomsPath){$MameRomsPath.foreach({Remove-Item -Path $_.parent.fullname -Recurse -Force -ErrorAction SilentlyContinue; Write-SimpleLog -Message "Se ha eliminado la carpeta de ROMS de MAME" -LogLevel "INFO"})}

#Localizando y borrando la carpeta de HyperSpin.
$HyperSpinPath = $DeviceContent.Where({$_.name -eq "HyperSpin.exe"})
If($HyperSpinPath){$HyperSpinPath.foreach({Remove-Item -Path $_.directory -Recurse -Force -ErrorAction SilentlyContinue; Write-SimpleLog -Message "Se ha eliminado la carpeta de HyperSpin" -LogLevel "INFO"})}
#Localizando y elimiando los archivos de instalacion de HyperSpin. 
$HyperSpinInstallFiles = $DeviceContent.Where({$_.name -like "*HyperSpin*"})
If($HyperSpinInstallFiles){$HyperSpinInstallFiles.foreach({Remove-Item -Path $_.fullname -Recurse -Force -ErrorAction SilentlyContinue; Write-SimpleLog -Message "Se ha eliminado el archivo de instalación de $($_.name)" -LogLevel "INFO"})}

#Localizando y borrando la carpeta de Emule.
$EmulePath = $DeviceContent.Where({$_.name -eq "server.met"})
If($EmulePath){$EmulePath.foreach({Remove-Item -Path $_.directory -Recurse -Force -ErrorAction SilentlyContinue; Write-SimpleLog -Message "Se ha eliminado la carpeta de Emule" -LogLevel "INFO"})}
#Localizando y elimiando los archivos de instalacion de Emule. 
$EmuleInstallFiles = $DeviceContent.Where({$_.name -like "*Emule*"})
If($EmuleInstallFiles){$EmuleInstallFiles.foreach({if(Test-Path $_.fullname){Remove-Item -Path $_.fullname -Recurse -Force -ErrorAction SilentlyContinue; Write-SimpleLog -Message "Se ha eliminado el archivo de instalación de $($_.name)" -LogLevel "INFO"}})}

#Localizando y elimiando los archivos de instalacion de torrents. 
$TorrentsInstallFiles = $DeviceContent.Where({$_.name -like "*torrent*"})
If($TorrentsInstallFiles){$TorrentsInstallFiles.foreach({if(Test-Path $_.fullname){Remove-Item -Path $_.fullname -Recurse -Force -ErrorAction SilentlyContinue; Write-SimpleLog -Message "Se ha eliminado el archivo de instalación de $($_.name)" -LogLevel "INFO"}})}



#Bloque Error y Warning
Write-SimpleLog -message "Se han producido $($warning.count) advertencias durante la ejecución del script " -loglevel "INFO"
Write-SimpleLog -message "Se han producido $($error.count) errores durante la ejecución del script " -loglevel "INFO"
if($error.count -gt 0){Write-SimpleLog -message "Listando errores" -loglevel "ERROR";$error | foreach-object {Write-SimpleLog -message $_.Exception.Message -loglevel "ERROR"}}
if($warning.count -gt 0){Write-SimpleLog -message "Listando advertencias" -loglevel "WARNING";$warning | foreach-object {Write-SimpleLog -message $_.Exception.Message -loglevel "WARNING"}}
Write-SimpleLog -Message "Proceso de limpieza finalizado" -LogLevel "INFO"