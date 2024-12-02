# Nombre del servicio a comprobar
$ServiceName = "Sap Cloud Print Service for Pull Integration"

# Comprobar si el servicio existe
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if (-not $service) {
    # El servicio no está instalado
    Write-Output "El servicio $ServiceName no está instalado."
    exit 0
}

# Comprobar si el servicio está configurado para ejecutarse como "System"
$serviceConfig = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
if  ($serviceConfig.StartName -eq "LocalSystem" -or $serviceConfig.StartName -eq ".\Administrador") {
    # El servicio no está configurado como "System"
    Write-Output "El servicio $ServiceName no está configurado para ejecutarse como LocalSystem."
    exit 1
}

# Todo está correcto
Write-Output "El servicio $ServiceName está configurado correctamente."
exit 0