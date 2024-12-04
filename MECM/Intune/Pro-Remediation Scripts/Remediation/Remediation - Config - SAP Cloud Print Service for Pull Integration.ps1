#region log

#region "log parameters"
$logpath  = 'C:\Windows\Logs\Intune-Remediation\'
$username   = $env:USERNAME
$hostname   = hostname
$datetime   = Get-Date -f 'yyyyMMddHHmmss'
$scriptname = "Remediation - Config - SAP Cloud Print Service for Pull Integration"
$filename   = "${scriptname}-${username}-${hostname}-${datetime}.log"
$logfilename = Join-Path -Path $logpath -ChildPath $filename
$PathCMTracelog = $logfilename
$ComponentSource = $MyInvocation.MyCommand.Name
#endregion "log parameters"
# Test logpath
if(-not (Test-Path $logpath)){
	New-Item -ItemType Directory -Path $logpath -Force |Out-Null
}
#endregion log
#region Configuraciones
# ================================================
$serviceName = 'Sap Cloud Print Service for Pull Integration' # Nombre del servicio

# Generar datos aleatorios
$usernameRandom = "RandoMUser_" + [guid]::NewGuid().ToString().Substring(0, 8)
$password = -join ((33..126) | Get-Random -Count 16 | ForEach-Object {[char]$_})
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
#endregion

#region Funciones
# ================================================
function Write-CMTracelog {
    [CmdletBinding()]
    Param(

          [Parameter(Mandatory=$true)]
          [String]$Message,
            
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]$Path,
                  
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]$Component,

          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [ValidateSet("Information", "Warning", "Error")]
          [String]$Type = 'Information'
    )

    if(!$Path){
        $Path= $PathCMTracelog
        }
    if(!$Component){
        $Component= $ComponentSource
        }
        
    switch ($Type) {
        "Info" { [int]$Type = 1 }
        "Warning" { [int]$Type = 2 }
        "Error" { [int]$Type = 3 }
    }

    # Create a CMTrace formatted entry
    $Content = "<![LOG[$Message]LOG]!>" +`
        "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
        "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
        "component=`"$Component`" " +`
        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
        "type=`"$Type`" " +`
        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
        "file=`"`">"

    # Add the line to the log file   
    Add-Content -Path $Path -Value $Content
}
function Add-LocalUser {
    param([string]$Username, [SecureString]$Password)
    if (-not (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $Username -Password $Password -PasswordNeverExpires -UserMayNotChangePassword |Out-Null
        Write-CMTracelog "User $Username created successfully." 
    } else {
        Write-CMTracelog "The user $Username already exists." 
    }
}

function Add-ToAdministrators {
    param([string]$Username, [string]$LogFile)
    Add-LocalGroupMember -Group "Administradores" -Member $Username
    Write-CMTracelog "User $Username added to Administrators group."
}

function Update-Service {
    param(
        [string]$ServiceName,
        [string]$Username,
        [string]$Password,
        [string]$LogFile
    )

    # Paso 1: Configurar las credenciales para el servicio
    try {
        Write-CMTracelog "Step 4.1: Configuring credentials for service $ServiceName." 
        sc.exe config $ServiceName obj= $Username password= $Password | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "Fail to configure credentials for service $ServiceName with user $Username."
        }

        Write-CMTracelog "Credentials configured successfully for service $ServiceName."
    } catch {
        Write-CMTracelog "Error in Step 4.1 (Configure credentials): $_"
        throw
    }

    # Paso 2: Configurar el inicio automático del servicio
    try {
        Write-CMTracelog "Step 4.2: Configuring automatic startup for service $ServiceName."
        Set-Service -Name $ServiceName -StartupType Automatic

        Write-CMTracelog "Automatic startup configured successfully for service $ServiceName." 
    } catch {
        Write-CMTracelog "Error in Step 4.2 (Configure automatic startup): $_"
        throw
    }

    # Paso 3: Iniciar el servicio
    try {
        Write-CMTracelog "Step 4.3: Starting service $ServiceName." 
        Start-Service -Name $ServiceName | Out-Null

        Write-CMTracelog "Service $ServiceName started successfully."
    } catch {
        Write-CMTracelog "Error in Step 4.3 (Start service): $_" 
        throw
    }
}

function Grant-ServiceLogonRight {
    param([string]$Username)

    try {
        # Exportar la configuración actual
        Write-CMTracelog "Export current configuration to file..."
        $configFile = "C:\Windows\logs\ServiceLogonRights.cfg"
        secedit /export /cfg $configFile |Out-Null

        # Leer el archivo de configuración y modificar el derecho SeServiceLogonRight
        Write-CMTracelog "Modifying SeServiceLogonRight File..."
        $content = Get-Content $configFile
        $updatedContent = $content -replace "(?<=SeServiceLogonRight\s=\s).*", "`"$Username`""
        Set-Content -Path $configFile -Value $updatedContent

        # Aplicar los cambios
        Write-CMTracelog "Applying changes..."
        secedit /configure /db secedit.sdb /cfg $configFile /areas USER_RIGHTS | Out-Null

        # Eliminar el archivo de configuración
        Write-CMTracelog "Removing temporary file..."
        Remove-Item $configFile

        Write-CMTracelog "Set the right 'Logon as a service' for $Username with success."
    } catch {
        Write-CMTracelog "Error in Set the right 'Logon as a service': $_"
    }
}
#endregion

Write-CMTracelog "Start execution Script: ${scriptname}"

#region Main
# ================================================
# Step 1: create user
try {
    Write-CMTracelog "Step 1: create user." 
    Add-LocalUser -Username $usernameRandom -Password $securePassword 
} catch {
    Write-CMTracelog "Error to create user: $_" 
    exit 1
}

# Step 2: Add user to administrators group
try {
    Write-CMTracelog "Step 2: Add user to Administrators group."
    Add-ToAdministrators -Username $usernameRandom
} catch {
    Write-CMTracelog "Error to add user to Administrators groups: $_" 
    exit 1
}

# Step 3: Grant user permissions to logon as a service
try {
    Write-CMTracelog "Step 3: Add user permissions to logon as a service." 
    Grant-ServiceLogonRight -Username $usernameRandom 

} catch {
    Write-CMTracelog "Error to add user permissions to logon as a service: $_" 
    exit 1
}

# Step 4: Configure the service
try {
    Write-CMTracelog "Step 4: Configure the service." 
    Update-Service -ServiceName $serviceName -Username ".\$usernameRandom" -Password $password 
} catch {
    Write-CMTracelog "Error to configure the service: $_" 
}

Write-CMTracelog "Script ${scriptname} executed with success."
Write-CMTracelog "End execution Script: ${scriptname}"
exit 0
#endregion 
