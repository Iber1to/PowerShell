<#
.SYNOPSIS
    Agrega un dispositivo a un grupo en Azure AD utilizando la API de Microsoft Graph.

.DESCRIPTION
    Esta función permite agregar un dispositivo específico a un grupo de Azure AD utilizando la API de Microsoft Graph. Requiere el ID del grupo, el ID del dispositivo y un token de acceso para autenticar las solicitudes. La función define el cuerpo de la solicitud en formato JSON y realiza la solicitud POST para agregar el dispositivo al grupo.

.PARAMETER GroupId
    El ID del grupo al que se desea agregar el dispositivo. Este parámetro es una cadena de texto que representa el identificador único del grupo en Azure AD.

.PARAMETER DeviceId
    El ID del dispositivo que se desea agregar al grupo. Este parámetro es una cadena de texto que representa el identificador único del dispositivo en Azure AD.

.PARAMETER AccessToken
    El token de acceso necesario para autenticar las solicitudes a la API de Microsoft Graph. Este token debe tener los permisos adecuados para modificar miembros de grupos.

.EXAMPLE
    PS> Add-DeviceToAzureGroup -GroupId "12345" -DeviceId "67890" -AccessToken "eyJ0eXAiOiJKV1QiLCJhbGciOi..."
    Este comando agrega el dispositivo con ID "67890" al grupo con ID "12345" en Azure AD.

.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: 15/07/2024
    Última modificación: 15/07/2024
    Versión:  1.0.0
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>

function Add-DeviceToAzureGroup {
    param (
        [string]$GroupId,
        [string]$DeviceId,
        [string]$AccessToken
    )

    # Definir el cuerpo de la solicitud JSON para agregar un dispositivo al grupo
    $memberBody = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/devices/$DeviceId"
    }

    # Convertir el cuerpo a JSON
    $memberBodyString = $memberBody | ConvertTo-Json

    # URI para agregar un dispositivo al grupo
    $uri = "https://graph.microsoft.com/v1.0/groups/$GroupId/members/$('$ref')"

    # Realizar la solicitud a la API de Microsoft Graph para agregar el dispositivo al grupo
    try {
        Invoke-RestMethod -Method Post -Uri $uri -Headers @{Authorization = "Bearer $AccessToken"; "Content-Type" = "application/json"} -Body $memberBodyString
        Write-Output "Dispositivo: $DeviceId agregado con exito al grupo."
        Return $true
    } catch {
        Write-Output "Error agregando el dispositivo: $DeviceId al grupo. Es probable que el dispositivo ya se encuentre en el grupo. Error: $($_.Exception.Message)"
        Return $false
    }
}
