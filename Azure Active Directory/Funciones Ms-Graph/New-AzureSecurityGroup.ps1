<#
.SYNOPSIS
    Crea un nuevo grupo de seguridad en Azure AD usando la API de Microsoft Graph.

.DESCRIPTION
    Esta función permite crear un nuevo grupo de seguridad en Azure Active Directory utilizando la API de Microsoft Graph. Requiere el nombre del grupo, un token de acceso, una descripción y un alias para el correo. La función define el cuerpo de la solicitud en formato JSON, realiza la solicitud POST para crear el grupo y devuelve la respuesta de la API.

.PARAMETER GroupName
    El nombre del grupo de seguridad que se desea crear. Este parámetro es una cadena de texto que representa el nombre de visualización del grupo en Azure AD.

.PARAMETER AccessToken
    El token de acceso necesario para autenticar las solicitudes a la API de Microsoft Graph. Este token debe tener los permisos adecuados para crear grupos.

.PARAMETER Description
    Una descripción del grupo de seguridad. Este parámetro es una cadena de texto que proporciona información adicional sobre el propósito del grupo.

.PARAMETER MailNickname
    El alias de correo del grupo. Aunque el grupo no estará habilitado para correo, este alias es necesario para su creación.

.EXAMPLE
    PS> New-AzureSecurityGroup -GroupName "GrupoDeSeguridad" -AccessToken "eyJ0eXAiOiJKV1QiLCJhbGciOi..." -Description "Grupo para control de acceso" -MailNickname "GrupoSeguridad"
    Este comando crea un nuevo grupo de seguridad en Azure AD con el nombre "GrupoDeSeguridad", una descripción "Grupo para control de acceso" y un alias "GrupoSeguridad".

.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: 15/07/2024
    Última modificación: 15/07/2024
    Versión:  1.0.0
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>

function New-AzureSecurityGroup {
    param (
        [string]$GroupName,
        [string]$AccessToken,
        [string]$Description,
        [string]$MailNickname
    )
    try {
        # Definir el cuerpo de la solicitud JSON para crear el grupo de seguridad
        Write-Output "Definiendo el cuerpo de la solicitud JSON para crear el grupo de seguridad con nombre $GroupName"
        $groupBody = @{
            "description" = $Description
            "displayName" = $GroupName
            "mailEnabled" = $false
            "mailNickname" = $MailNickname
            "securityEnabled" = $true
        }
        # Convertir el cuerpo a JSON
        $groupBodyString = $groupBody | ConvertTo-Json
    
        # URI para crear un nuevo grupo
        $uri = "https://graph.microsoft.com/v1.0/groups"

        # Realizar la solicitud a la API de Microsoft Graph para crear el grupo
        Write-Output "Realizando la solicitud a la API de Microsoft Graph para crear el grupo"
        $groupResponse = Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = "Bearer $AccessToken"; "Content-Type" = "application/json" } -Body $groupBodyString
        Write-Output "Grupo de seguridad creado con exito con ID: $($groupResponse.id)"
        return $groupResponse
    } catch {
        Write-Output "Error al crear el grupo de seguridad: $GroupName. Error: $($_.Exception.Message)"
        return $null
    }
}
