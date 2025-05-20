<#
.SYNOPSIS
    Función para obtener un token de acceso para la API de Microsoft Graph.

.DESCRIPTION
    Esta función obtiene un token de acceso para autenticar las solicitudes a la API de Microsoft Graph.
    Utiliza el flujo de credenciales del cliente (client credentials flow) para obtener el token.
    Se requiere que la aplicación de Azure Active Directory tenga los permisos necesarios para acceder a los recursos de Microsoft Graph requeridos.
    
.PARAMETER tenantId
    El ID del inquilino de Azure Active Directory donde se encuentra el grupo.

.PARAMETER clientId
    El ID del cliente de la aplicación Azure Active Directory.

.PARAMETER clientSecret 
    El secreto del cliente de la aplicación Azure Active Directory.

.EXAMPLE
    PS> Get-AuthenticationToken  -tenantId "tu-tenant-id" -clientId "tu-client-id" -clientSecret "tu-client-secret"
    Obtiene el token de acceso para autenticar las solicitudes a la API de Microsoft Graph.

.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: 15/07/2024
    Última modificación: 15/07/2024
    Versión:  1.0.0
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>

function Get-AuthenticationToken {
    param (
        [string]$tenantId,
        [string]$clientId,
        [string]$clientSecret
    )

    # Obteniendo el token de acceso para Microsoft Graph
$bodyaccessToken = @{
grant_type    = "client_credentials"
scope         = "https://graph.microsoft.com/.default"
client_id     = $clientId
client_secret = $clientSecret
}    
try {
        $responseaccessToken = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $bodyaccessToken
        $accessToken = $responseaccessToken.access_token
        return $accessToken
    } catch { return $($_.Exception.Message)}
}