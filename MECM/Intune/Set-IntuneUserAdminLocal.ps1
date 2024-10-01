<#
.SYNOPSIS
    Script para otorgar permisos de administrador local a un usuario en los dispositivos de los que es propietario en Intune.
 
.DESCRIPTION
    Este script genera un grupo de seguridad para el usuario en el que incluye todos los dispositivos de los que es propietario en Intune. Despues genera una politica de "Account Protection" en Intune agregando como administrador local al usuario y la asgina al grupo que creo en el paso anterior.    
 
.PARAMETER Usuario
    El nombre del usuario que se desea procesar. Este parámetro es una cadena de texto en formato de dirección de correo electrónico o un archivo de texto con la lista de correos electronicos a procesar.
 
.PARAMETER TenantId
    El ID del inquilino de Azure AD. Este parámetro es una cadena de texto que representa el identificador único del inquilino.
 
.PARAMETER ClientId
    El ID del cliente de la aplicación Azure AD. Este parámetro es una cadena de texto que representa el identificador único del cliente.
    La App tiene que tener minimo los siguiente permisos asignados:
     - Device.ReadWrite.All
     - Group.ReadWrite.All
     - User.Read.All
     - DeviceManagementConfiguration.ReadWrite.All
     - GroupMember.ReadWrite.All
 
.PARAMETER ClientSecret
    El secreto del cliente de la aplicación Azure AD. Este parámetro es una cadena de texto que representa el secreto del cliente.
 
.PARAMETER LogFile
    La ruta del archivo de log. Este parámetro es una cadena de texto que representa la ubicación del archivo de log.
 
.EXAMPLE
    PS> .\Manage-DevicesAndGroups.ps1
    Este script iterará sobre una lista de usuarios, gestionará sus dispositivos y grupos en Azure AD, y creará políticas de protección de cuentas en Intune.

.VERSION HISTORY
    - v1.0.0 (15/07/2024): Versión inicial del script.
    - v1.0.1 (30/09/2024): - Se corrige la función Get-UserOwnedDevices para que devuelva solo dispositivos "Windows".
                           - Se corrige el main del script para que trabaje tambien con grupos existentes y no solo con los grupos nuevos.                      
.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: 15/07/2024
    Última modificación: 15/07/2024
    Versión:  1.0.0
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>
 
# Array de usuarios a procesar
# Descomentar y usar esta linea cuando queramos cargarlo desde un archivo para multiples usuarios
# $usuarios = get-content C:\temp\contosolocaladmins.txt
# Cuando hay pocos usuarios
$usuarios = "matarife.riz@contoso.es" #  si es un unico usuario, si son varios separados por coma. Ejemplo: $usuarios = "matarife.riz@contoso.es", "mauriz@contoso.es", "ben.gulo@contoso.es"
 
#region Log
# Ruta del Archivo de log
$logFile = "C:\temp\contoso.log"
 
# Función para registrar logs
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logMessage -Encoding UTF8
}
#endregion Log
 
Write-Log "------------------------------------------------------------------  INICIANDO SCRIPT  ------------------------------------------------------------------"
#region Credenciales
# Configuración de la aplicación Azure
$tenantId = "JHHAec434-187e-0000-957c-d7165cc56d16"
$clientId = "1548acfe-95d9-480d-acd3-00000e60567f"
$clientSecret = "h2k8Q~meE00000c6pSPJlHcoidF-I_KXYz8Ye0000"
 
# Obteniendo el token de acceso para Microsoft Graph
Write-Log "Obteniendo el token de acceso para Microsoft Graph"
$bodyaccessToken = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $clientId
    client_secret = $clientSecret
}
try {
    $responseaccessToken = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $bodyaccessToken
    $accessToken = $responseaccessToken.access_token
    Write-Log "Token de acceso generado con exito"
} catch { Write-Log "Error al generar el token de acceso. Error: $($_.Exception.Message)"}
 
#endregion Credenciales
 
#region Funciones
 
# Trae el listado de dispositivos de los que un usuario es propietario
function Get-UserOwnedDevices {
    param (
        [string]$Usuario,
        [string]$AccessToken
    )
 
    try {
        # Obtener el ID del usuario
        Write-Log "Obteniendo ID del usuario para $Usuario"
        $userIdResponse = Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/users/$Usuario" -Headers @{ Authorization = "Bearer $AccessToken" }
        $userId = $userIdResponse.id
        Write-Log "ID del usuario obtenido: $userId"
    } catch {
        Write-Log "Error obteniendo el ID del usuario: $Usuario. Error: $($_.Exception.Message)"
        return
    }
 
    try {
        # Obtener los dispositivos del usuario
        Write-Log "Obteniendo dispositivos para el usuario con ID $userId"
        $devicesResponse = Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/users/$userId/ownedDevices" -Headers @{ Authorization = "Bearer $AccessToken" }
        Write-Log "Dispositivos obtenidos con exito"

        # Filtrar dispositivos con sistema operativo Windows
        $windowsDevices = $devicesResponse.value | Where-Object { $_.operatingSystem -eq "Windows" }

        # Retornar solo los dispositivos con sistema operativo Windows
        return $windowsDevices

    } catch {
        Write-Log "Error obteniendo los dispositivos del usuario: $Usuario. Error: $($_.Exception.Message)"
        return
    }
}
 
# Comprueba si existe un nombre de grupo de azure
function Get-GroupByName {
    param (
        [string]$GroupName,
        [string]$AccessToken
    )
 
    try {
        # Obtener información del grupo por nombre
        Write-Log "Obteniendo información del grupo con nombre $GroupName"
        $uri =  "https://graph.microsoft.com/v1.0/groups?$('$filter')=displayName eq '$GroupName'"
        $groupResponse = Invoke-RestMethod -Method Get -Uri $uri -Headers @{ Authorization = "Bearer $AccessToken" }
        Write-Log "Información del grupo obtenida con exito"
    } catch {
        Write-Log "Error obteniendo información del grupo: $GroupName. Error: $($_.Exception.Message)"
        return $null
    }
    if ($groupResponse.value.Count -eq 0) {
        Write-Log "No se encontró ningún grupo con el nombre $GroupName"
        return $null
    }
    Write-Log "Grupo encontrado: $($groupResponse.value[0].id)"
    return $groupResponse.value[0]
}
 
# Crea un security group en Azure
function New-AzureSecurityGroup {
    param (
        [string]$GroupName,
        [string]$AccessToken,
        [string]$Description,
        [string]$MailNickname
    )
    try {
        # Definir el cuerpo de la solicitud JSON para crear el grupo de seguridad
        Write-Log "Definiendo el cuerpo de la solicitud JSON para crear el grupo de seguridad con nombre $GroupName"
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
        Write-Log "Realizando la solicitud a la API de Microsoft Graph para crear el grupo"
        $groupResponse = Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = "Bearer $AccessToken"; "Content-Type" = "application/json" } -Body $groupBodyString
        Write-Log "Grupo de seguridad creado con exito con ID: $($groupResponse.id)"
        return $groupResponse
    } catch {
        Write-Log "Error al crear el grupo de seguridad: $groupName. Error: $($_.Exception.Message)"
        return $null
    }
}
 
# Agrega un dispositivo a un grupo de azure
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
        Write-Log "Dispositivo: $deviceId agregado con exito al grupo."
    } catch {
        Write-Log "Error agregando el dispositivo: $deviceId al grupo. Es probable que el dispositivo ya se encuentre en el grupo. Error: $($_.Exception.Message)"
    }
}
 
# Crea una política de protección de cuentas y se asigna a un grupo de dispositivos
function New-PolicyLocalAdmins {
    param (
        [string]$Usuario,
        [string]$AccessToken,
        [string]$InternalGroupId
    )
 
    $policyCreation = $false
    $AssignPolicy = $false
    # Definir los detalles de la política de configuración
    $userName = $usuario.Split('@')[0]
    $AzureUser = "AzureAD\$usuario"
    $policyName = "Intune - Devices - Windows - Settings Catalog - Endpoint Security - Account protection - Local Admins $userName"
    $policyDescription = "Policy to add a user to the local administrators group"
 
    # Definir el cuerpo de la política JSON para la politica de configuracion  
    $jsonBody = @{
        name = $policyName
        description = $policyDescription
        platforms = "windows10"
        technologies = "mdm"
        roleScopeTagIds = @("0")
        settings = @(
            @{
                "@odata.type" = "#microsoft.graph.deviceManagementConfigurationSetting"
                settingInstance = @{
                    "@odata.type" = "#microsoft.graph.deviceManagementConfigurationGroupSettingCollectionInstance"
                    settingDefinitionId = "device_vendor_msft_policy_config_localusersandgroups_configure"
                    groupSettingCollectionValue = @(
                        @{
                            children = @(
                                @{
                                    "@odata.type" = "#microsoft.graph.deviceManagementConfigurationGroupSettingCollectionInstance"
                                    settingDefinitionId = "device_vendor_msft_policy_config_localusersandgroups_configure_groupconfiguration_accessgroup"
                                    groupSettingCollectionValue = @(
                                        @{
                                            children = @(
                                                @{
                                                    "@odata.type" = "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance"
                                                    settingDefinitionId = "device_vendor_msft_policy_config_localusersandgroups_configure_groupconfiguration_accessgroup_userselectiontype"
                                                    choiceSettingValue = @{
                                                        "@odata.type" = "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue"
                                                        value = "device_vendor_msft_policy_config_localusersandgroups_configure_groupconfiguration_accessgroup_userselectiontype_users"
                                                        children = @(
                                                            @{
                                                                "@odata.type" = "#microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance"
                                                                settingDefinitionId = "device_vendor_msft_policy_config_localusersandgroups_configure_groupconfiguration_accessgroup_users"
                                                                simpleSettingCollectionValue = @(
                                                                    @{
                                                                        value = $AzureUser
                                                                        "@odata.type" = "#microsoft.graph.deviceManagementConfigurationStringSettingValue"
                                                                    }
                                                                )
                                                            }
                                                        )
                                                    }
                                                },
                                                @{
                                                    "@odata.type" = "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance"
                                                    settingDefinitionId = "device_vendor_msft_policy_config_localusersandgroups_configure_groupconfiguration_accessgroup_action"
                                                    choiceSettingValue = @{
                                                        "@odata.type" = "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue"
                                                        value = "device_vendor_msft_policy_config_localusersandgroups_configure_groupconfiguration_accessgroup_action_add_update"
                                                        children = @()
                                                    }
                                                },
                                                @{
                                                    "@odata.type" = "#microsoft.graph.deviceManagementConfigurationChoiceSettingCollectionInstance"
                                                    settingDefinitionId = "device_vendor_msft_policy_config_localusersandgroups_configure_groupconfiguration_accessgroup_desc"
                                                    choiceSettingCollectionValue = @(
                                                        @{
                                                            "@odata.type" = "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue"
                                                            value = "device_vendor_msft_policy_config_localusersandgroups_configure_groupconfiguration_accessgroup_desc_administrators"
                                                            children = @()
                                                        }
                                                    )
                                                }
                                            )
                                        }
                                    )
                                }
                            )
                        }
                    )
                    settingInstanceTemplateReference = @{
                        settingInstanceTemplateId = "de06bec1-4852-48a0-9799-cf7b85992d45"
                    }
                }
            }
        )
        templateReference = @{
            templateId = "22968f54-45fa-486c-848e-f8224aa69772_1"
        }
    }
 
    # Convertir el cuerpo a JSON
    $jsonBodyString = $jsonBody | ConvertTo-Json -Depth 100
 
    # Crear la política usando la API de Microsoft Graph (versión beta)
    try {
        $response = Invoke-RestMethod -Method Post -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies" -Headers @{Authorization = "Bearer $accessToken"} -Body $jsonBodyString -ContentType "application/json"
        $policy = $response
        Write-Log "Política de protección de cuentas creada con exito: $policyName"
        $policyCreation = $true
    } catch {Write-Log "Error creando la política de protección de cuentas: $policyName. Error: $($_.Exception.Message)"}
 
    # Crear la asignación de la política
    $assignmentBody = @{
        assignments = @(
            @{
                target = @{
                    "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                    groupId = $InternalgroupId
                }
            }
        )
    }
 
    # Convertir el cuerpo a JSON
    $assignmentBodyString = $assignmentBody | ConvertTo-Json -Depth 10
 
    # Asignar la política al grupo de dispositivos
    try {
        $response = Invoke-RestMethod -Method Post -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($policy.id)/assign" -Headers @{Authorization = "Bearer $accessToken"} -Body $assignmentBodyString -ContentType "application/json"
        Write-Log "Política asignada  al grupo de dispositivos con exito."
        $AssignPolicy = $true
    } catch {Write-Log "Error asignando la política al grupo de dispositivos. Error: $($_.Exception.Message)"}
 
    if ($AssignPolicy -eq $true -AND $policyCreation -eq $true){return $true} else {return $false}
}
#endregion Funciones
 
# Iterar sobre los usuarios y realizar las operaciones
foreach ($usuario in $usuarios) {
    try {$AzureObjectDevice = Get-UserOwnedDevices -Usuario $usuario -AccessToken $accessToken} catch { Write-Log "Error al cargar los dispositivos del usuario: $usuario" }
    
    if ($null -ne $AzureObjectDevice){            
        # Consultando si tiene creado el grupo de Azure
        $userName = $usuario.Split('@')[0]
        $groupName = "Azure - Devices - Windows - Managed - Local Admins - $userName"
        $GroupDescription = "Grupo para dar permisos de administrador local a los dispositivos de $username"
        try {$UserGroupAd = Get-GroupByName -GroupName $groupName -AccessToken $accessToken} catch { Write-Log "Error al cargar el grupo $groupName" }
        
        if ($null -eq $UserGroupAd){
            # Creamos el grupo si no existe
            Write-Log "No existe el grupo $groupName"
            try {
                $NewGroupUser = New-AzureSecurityGroup -GroupName $groupName -AccessToken $accessToken -MailNickName $userName -Description $GroupDescription      
                Write-Log "Se ha creado el grupo $groupName para el usuario $usuario"
                $groupId = $NewGroupUser.Id
            } catch { 
                Write-Log "Error al crear el grupo $groupName para el usuario $usuario"
                continue  # Detenemos este ciclo y seguimos con el próximo usuario en caso de error
            }
        } else { 
            Write-Log "Existe el grupo $groupName para el usuario $usuario"
            $groupId = $UserGroupAd.Id
        }
        
        # Procesamos los dispositivos del usuario para agregarlos como miembros al grupo
        foreach ($item in $AzureObjectDevice){
            try {
                Add-DeviceToAzureGroup -GroupId $groupId -DeviceId $item.Id -AccessToken $accessToken
                Write-Log "Dispositivo: $($item.DisplayName) agregado al grupo $groupName"
            } catch { 
                Write-Log "Error al agregar el dispositivo $($item.DisplayName) al grupo $groupName"
            }
        }

        # Creamos la política de protección de cuentas
        try {
            New-PolicyLocalAdmins -Usuario $usuario -AccessToken $accessToken -InternalGroupId $groupId
        } catch { 
            Write-Log "Error al crear la política de protección de Cuentas para el usuario: $usuario"
        }
    } else {
        Write-Log "Error el usuario: $usuario no tiene dispositivo asociado"
    }    
}

 
Write-Log "------------------------------------------------------------------  SCRIPT FINALIZADO  ------------------------------------------------------------------"