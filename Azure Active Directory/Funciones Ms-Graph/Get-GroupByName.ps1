<#
.SYNOPSIS
    Obtiene información de un grupo en Azure Active Directory basado en su nombre.

.DESCRIPTION
    Esta función utiliza la API de Microsoft Graph para obtener información detallada de un grupo específico basado en su nombre. Requiere el nombre del grupo y un token de acceso para autenticar las solicitudes. La función filtra los grupos por su nombre y devuelve la información del grupo encontrado.

.PARAMETER GroupName
    El nombre del grupo que se quiere buscar. Este parámetro es una cadena de texto que representa el nombre del grupo en Microsoft Graph.

.PARAMETER AccessToken
    El token de acceso necesario para autenticar las solicitudes a la API de Microsoft Graph. Este token debe tener los permisos adecuados para leer información de grupos.

.EXAMPLE
    PS> Get-GroupByName -GroupName "NombreDelGrupo" -AccessToken "eyJ0eXAiOiJKV1QiLCJhbGciOi..."
    Este comando obtiene y devuelve la información del grupo con el nombre "NombreDelGrupo".

.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: 15/07/2024
    Última modificación: 15/07/2024
    Versión:  1.0.0
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>

function Get-GroupByName {
    param (
        [string]$GroupName,
        [string]$AccessToken
    )

    try {
        # Obtener información del grupo por nombre
        Write-Output "Obteniendo información del grupo con nombre $GroupName"
        $uri =  "https://graph.microsoft.com/v1.0/groups?$('$filter')=displayName eq '$GroupName'"
        $groupResponse = Invoke-RestMethod -Method Get -Uri $uri -Headers @{ Authorization = "Bearer $AccessToken" }
        Write-Output "Información del grupo obtenida con exito"
    } catch {
        Write-Output "Error obteniendo información del grupo: $GroupName. Error: $($_.Exception.Message)"
        return $null
    }

    # Procesando el resultado de la quest
    if ($groupResponse.value.Count -eq 0) {
        Write-Output "No se encontró ningún grupo con el nombre $GroupName"
        return $null
    } elseif ($groupResponse.value.Count -gt 1) {
        Write-Output "Se encontró más de un grupo con el nombre $GroupName"
        return $groupResponse
    } else {
        Write-Output "Grupo encontrado: $($groupResponse.value)"
        return $groupResponse
    }
}
