<#
.SYNOPSIS
    Crea una nueva política de protección de cuentas en Intune.
.DESCRIPTION
    Esta función crea una política en Intune para agregar un usuario específico al grupo de administradores locales en los dispositivos Windows de los que es propietario. La política se crea usando la API de Microsoft Graph (versión beta) y luego se asigna a un grupo de dispositivos especificado. Requiere el nombre de usuario, un token de acceso, y el ID del grupo interno al que se debe asignar la política.

.PARAMETER Usuario
    El nombre del usuario que se desea agregar al grupo de administradores locales. Este parámetro es una cadena de texto en formato de dirección de correo electrónico.

.PARAMETER AccessToken
    El token de acceso necesario para autenticar las solicitudes a la API de Microsoft Graph. Este token debe tener los permisos adecuados para crear y asignar políticas en Intune.

.PARAMETER InternalGroupId
    El ID del grupo interno de dispositivos al que se desea asignar la política. Este parámetro es una cadena de texto que representa el identificador único del grupo en Intune.

.EXAMPLE
    PS> New-PolicyLocalAdmins -Usuario "usuario@dominio.com" -AccessToken "eyJ0eXAiOiJKV1QiLCJhbGciOi..." -InternalGroupId "12345"
    Este comando crea una política en Intune para agregar al usuario "usuario@dominio.com" al grupo de administradores locales en dispositivos Windows y asigna la política al grupo de dispositivos con ID "12345".

.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: 15/07/2024
    Última modificación: 15/07/2024
    Versión:  1.0.0
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>

function New-PolicyLocalAdmins {
    param (
        [string]$Usuario,
        [string]$AccessToken,
        [string]$InternalGroupId
    )

    $policyCreation = $false
    $AssignPolicy = $false
    # Definir los detalles de la política de configuración
    $userName = $Usuario.Split('@')[0]
    $AzureUser = "AzureAD\$Usuario"
    $policyName = "Intune - Devices - Windows - Settings Catalog - Endpoint Security - Account protection - Local Admins $userName"
    $policyDescription = "Policy to add a user to the local administrators group"

    # Definir el cuerpo de la política JSON para la política de configuración  
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
        $response = Invoke-RestMethod -Method Post -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies" -Headers @{Authorization = "Bearer $AccessToken"} -Body $jsonBodyString -ContentType "application/json"
        $policy = $response
        Write-Output "Política de protección de cuentas creada con exito: $policyName"
        $policyCreation = $true
    } catch { Write-Output "Error creando la política de protección de cuentas: $policyName. Error: $($_.Exception.Message)"  }

    # Crear la asignación de la política
    $assignmentBody = @{
        assignments = @(
            @{
                target = @{
                    "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                    groupId = $InternalGroupId
                }
            }
        )
    }

    # Convertir el cuerpo a JSON
    $assignmentBodyString = $assignmentBody | ConvertTo-Json -Depth 10

    # Asignar la política al grupo de dispositivos
    try {
        $response = Invoke-RestMethod -Method Post -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($policy.id)/assign" -Headers @{Authorization = "Bearer $AccessToken"} -Body $assignmentBodyString -ContentType "application/json"
        Write-Output "Política asignada  al grupo de dispositivos con exito."
        $AssignPolicy = $true
    } catch { Write-Output "Error asignando la política al grupo de dispositivos: $($_.Exception.Message)"  }

    if ($AssignPolicy -eq $true -AND $policyCreation -eq $true) { return $true } else { return $false }
}
