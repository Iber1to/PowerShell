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
    Fecha de creación: [Fecha de creación del script]
    Última modificación: [Fecha de última modificación]
    Versión:  1.0.0
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>
function Write-SimpleLog([string]$Message, [ValidateSet("INFO", "WARNING", "ERROR")] [string]$LogLevel = "INFO") {
    # Generate log file name using script name and current date
    $ScriptName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
    $HostName = ($env:COMPUTERNAME)
    $HostName = $HostName.SubString(0,1).ToUpper()+$HostName.SubString(1).ToLower()
    $LogFileName = $HostName+$ScriptName+"_"+$(Get-Date -Format 'yyyyMMdd')+".log"
    $LogPath = "C:\InetumLogs\$LogFileName"

    # Create logs folder if it doesn't exist
    if (-not (Test-Path -Path "C:\InetumLogs")) {
        New-Item -ItemType Directory -Path "C:\InetumLogs" | Out-Null
    }

    # Format log message
    $CurrentTime = Get-Date -Format "HH:mm:ss.fff"
    $CurrentDate = Get-Date -Format "yyyy/MM/dd"
    $LogEntry = "[$LogLevel][$CurrentTime][$CurrentDate] $Message"

    # Append log message to log file
    Add-Content $LogPath -Value $LogEntry
}