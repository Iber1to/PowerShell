<#
.SYNOPSIS
    Obtiene los dispositivos propiedad de un usuario en Intune.

.DESCRIPTION
    Esta función utiliza la API de Microsoft Graph para obtener los dispositivos propiedad de un usuario específico. Requiere el nombre de usuario y un token de acceso para autenticar las solicitudes. La función primero obtiene el ID del usuario y luego utiliza ese ID para recuperar los dispositivos que posee.

.PARAMETER Usuario
    El nombre de usuario del que se quieren obtener los dispositivos. Este parámetro es una cadena de texto que representa el usuario en Microsoft Graph.

.PARAMETER AccessToken
    El token de acceso necesario para autenticar las solicitudes a la API de Microsoft Graph. Este token debe tener los permisos adecuados para leer información de usuario y sus dispositivos.

.EXAMPLE
    PS> Get-UserOwnedDevices -Usuario "usuario@dominio.com" -AccessToken "eyJ0eXAiOiJKV1QiLCJhbGciOi..."
    Este comando obtiene y devuelve una lista de dispositivos que son propiedad del usuario "usuario@dominio.com".

.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: 15/07/2024
    Última modificación: 15/07/2024
    Versión:  1.0.0
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>

function Get-UserOwnedDevices {
    param (
        [string]$Usuario,
        [string]$AccessToken
    )

    try {
        # Obtener el ID del usuario
        Write-Output "Obteniendo ID del usuario para $Usuario"
        $userIdResponse = Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/users/$Usuario" -Headers @{ Authorization = "Bearer $AccessToken" }
        $userId = $userIdResponse.id
        Write-Output "ID del usuario obtenido: $userId"
    } catch {
        Write-Output "Error obteniendo el ID del usuario: $Usuario. Error: $($_.Exception.Message)"
        return $null
    }

    try {
        # Obtener los dispositivos del usuario
        Write-Output "Obteniendo dispositivos para el usuario con ID $userId"
        $devicesResponse = Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/users/$userId/ownedDevices" -Headers @{ Authorization = "Bearer $AccessToken" }
        Write-Output "Dispositivos obtenidos con exito"
        return $devicesResponse
    } catch {
        Write-Output "Error obteniendo los dispositivos del usuario: $Usuario. Error: $($_.Exception.Message)"
        return $null
    }
}