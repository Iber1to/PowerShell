#region Configuraciones
# ================================================
$logFile = "C:\Windows\Logs\ServiceConfig.log" # Ruta del archivo de log
$serviceName = 'Sap Cloud Print Service for Pull Integration' # Nombre del servicio

# Generar datos aleatorios
$usernameRandom = "RandoMUser_" + [guid]::NewGuid().ToString().Substring(0, 8)
$password = -join ((33..126) | Get-Random -Count 16 | ForEach-Object {[char]$_})
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
#endregion

#region Funciones
# ================================================
function Log-Message {
    param(
        [string]$Message,
        [string]$LogFile
    )
    # Obtener el directorio del archivo de log
    $logDirectory = Split-Path -Path $LogFile -Parent

    # Crear el directorio si no existe
    if (-not (Test-Path -Path $logDirectory)) {
        New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
    }

    # Escribir en el archivo de log
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $LogFile -Value "$timestamp - $Message"
    Write-Output "$timestamp - $Message"
}


function Create-LocalUser {
    param([string]$Username, [SecureString]$Password, [string]$LogFile)
    if (-not (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $Username -Password $Password -PasswordNeverExpires -UserMayNotChangePassword |Out-Null
        Log-Message "Usuario $Username creado exitosamente." -LogFile $LogFile
    } else {
        Log-Message "El usuario $Username ya existe. Saltando creación." -LogFile $LogFile
    }
}

function Add-ToAdministrators {
    param([string]$Username, [string]$LogFile)
    Add-LocalGroupMember -Group "Administradores" -Member $Username
    Log-Message "Usuario $Username agregado al grupo Administradores." -LogFile $LogFile
}

function Configure-Service {
    param(
        [string]$ServiceName,
        [string]$Username,
        [string]$Password,
        [string]$LogFile
    )

    # Paso 1: Configurar las credenciales para el servicio
    try {
        Log-Message "Paso 1: Configurando credenciales para el servicio $ServiceName." -LogFile $LogFile
        $result = sc.exe config $ServiceName obj= $Username password= $Password

        if ($LASTEXITCODE -ne 0) {
            throw "Falló la configuración de las credenciales para el servicio $ServiceName con el usuario $Username."
        }

        Log-Message "Credenciales configuradas correctamente para el servicio $ServiceName." -LogFile $LogFile
    } catch {
        Log-Message "Error en el Paso 1 (Configurar credenciales): $_" -LogFile $LogFile
        throw
    }

    # Paso 2: Configurar el inicio automático del servicio
    try {
        Log-Message "Paso 2: Configurando el inicio automático del servicio $ServiceName." -LogFile $LogFile
        Set-Service -Name $ServiceName -StartupType Automatic

        Log-Message "Inicio automático configurado correctamente para el servicio $ServiceName." -LogFile $LogFile
    } catch {
        Log-Message "Error en el Paso 2 (Configurar inicio automático): $_" -LogFile $LogFile
        throw
    }

    # Paso 3: Iniciar el servicio
    try {
        Log-Message "Paso 3: Intentando iniciar el servicio $ServiceName." -LogFile $LogFile
        Start-Service -Name $ServiceName

        Log-Message "Servicio $ServiceName iniciado correctamente." -LogFile $LogFile
    } catch {
        Log-Message "Error en el Paso 3 (Iniciar el servicio): $_" -LogFile $LogFile
        throw
    }
}

function Grant-ServiceLogonRight {
    param([string]$Username, [string]$LogFile)

    try {
        # Exportar la configuración actual
        $configFile = "C:\Temp\ServiceLogonRights.cfg"
        secedit /export /cfg $configFile

        # Leer el archivo de configuración y modificar el derecho SeServiceLogonRight
        $content = Get-Content $configFile
        $updatedContent = $content -replace "(?<=SeServiceLogonRight\s=\s).*", "`"$Username`""
        Set-Content -Path $configFile -Value $updatedContent

        # Aplicar los cambios
        secedit /configure /db secedit.sdb /cfg $configFile /areas USER_RIGHTS | Out-Null

        Log-Message "Se asignó el derecho 'Iniciar sesión como un servicio' al usuario $Username." -LogFile $LogFile
    } catch {
        Log-Message "Error al asignar el derecho 'Iniciar sesión como un servicio': $_" -LogFile $LogFile
        throw
    }
}

#endregion

#region Main
# ================================================
try {
    Log-Message "Paso 1: Creación del usuario." -LogFile $logFile
    Create-LocalUser -Username $usernameRandom -Password $securePassword -LogFile $logFile
} catch {
    Log-Message "Error al crear el usuario: $_" -LogFile $logFile
    exit 1
}

try {
    Log-Message "Paso 2: Asignando permisos de logon como servicio al usuario." -LogFile $logFile
    Grant-ServiceLogonRight -Username $usernameRandom -LogFile $logFile
} catch {
    Log-Message "Error al asignar permisos al usuario: $_" -LogFile $logFile
    exit 1
}

try {
    Log-Message "Paso 3: Agregando al grupo Administradores." -LogFile $logFile
    Add-ToAdministrators -Username $usernameRandom -LogFile $logFile
} catch {
    Log-Message "Error al agregar el usuario al grupo Administradores: $_" -LogFile $logFile
    exit 1
}

try {
    Log-Message "Paso 4: Configuración del servicio." -LogFile $logFile
    Configure-Service -ServiceName $serviceName -Username ".\$usernameRandom" -Password $password -LogFile $logFile
} catch {
    Log-Message "Error al configurar el servicio: $_" -LogFile $logFile
    exit 1
}

Log-Message "Script completado con éxito." -LogFile $logFile
#endregion
