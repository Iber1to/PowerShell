<# 
.SYNOPSIS
    Script para verificar y habilitar Secure Boot en sistemas Lenovo.

.DESCRIPTION
    Este script comprueba el estado de Secure Boot utilizando la clase WMI 'Lenovo_BiosSetting'.
    Si Secure Boot está deshabilitado, intenta habilitarlo automáticamente.
    Soporta diferentes variaciones en el nombre y estado de Secure Boot.

.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: [Fecha de creación del script]
    Última modificación: [Fecha de última modificación]
    Versión: 1.0.2
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github: https://github.com/Iber1to
    Twitter: @Alejand94399487
#>

# Comprobar el estado de Secure Boot usando Lenovo_BiosSetting y Lenovo_SaveBiosSettings
$currentSecureBootSetting01 = (Get-WmiObject -Namespace "root\wmi" -Class "Lenovo_BiosSetting" | Where-Object { $_.CurrentSetting -like "SecureBoot,*" }).CurrentSetting
$currentSecureBootSetting02 = (Get-WmiObject -Namespace "root\wmi" -Class "Lenovo_BiosSetting" | Where-Object { $_.CurrentSetting -like "Secure Boot,*" }).CurrentSetting

# Option Bios 1 Disable
if ($currentSecureBootSetting01 -like "SecureBoot,Disable") {
    Write-Output "Secure Boot no está habilitado. Intentando habilitarlo..."
 
    # Habilitar Secure Boot
    $result = (Get-WmiObject -Namespace "root\wmi" -Class "Lenovo_SetBiosSetting").SetBiosSetting("SecureBoot,Enable")
    (Get-WmiObject -Namespace "root\wmi" -Class "Lenovo_SaveBiosSettings").SaveBiosSettings()
 
    if ($result.Return -eq "Success") {
        Write-Output "Secure Boot se ha habilitado correctamente."
		Exit 0
    } else {
        Write-Output "Error al habilitar Secure Boot: Código de error $($result.Return)"
		Exit 1
    }
}

# Option Bios 2 Disabled
if ($currentSecureBootSetting02 -like "Secure Boot,Disabled*") {
    Write-Output "Secure Boot no está habilitado. Intentando habilitarlo..."
 
    # Habilitar Secure Boot
    $result = (Get-WmiObject -Namespace "root\wmi" -Class "Lenovo_SetBiosSetting").SetBiosSetting("Secure Boot,Enabled")
    (Get-WmiObject -Namespace "root\wmi" -Class "Lenovo_SaveBiosSettings").SaveBiosSettings()
 
    if ($result.Return -eq "Success") {
        Write-Output "Secure Boot se ha habilitado correctamente."
		Exit 0
    } else {
        Write-Output "Error al habilitar Secure Boot: Código de error $($result.Return)"
		Exit 1
    }
}

# Option Bios 3 Enable
if ($currentSecureBootSetting01 -like "SecureBoot,Enable") {
    Write-Output "Secure Boot está habilitado."
    Exit 0
}

# Option Bios 4 Enabled
if ($currentSecureBootSetting02 -like "Secure Boot,Enabled*") {
    Write-Output "Secure Boot está habilitado."
    Exit 0
}
Write-Output "No se pudo determinar el estado de Secure Boot."
Exit 0