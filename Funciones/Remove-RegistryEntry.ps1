<#
.SYNOPSIS
    This PowerShell function delete a registry entry to the specified path.

.DESCRIPTION
    This function delete an existing registry entry at the specified path with the specified name and value.

.PARAMETER Path
    The path of the registry entry.

.PARAMETER RegistryName
    The name of the registry entry.

.EXAMPLE
    Delete-RegistryEntry -Path "HKCU:\Software\MyApp" -RegistryName "MyEntry" 
    This command delete a registry entry named "MyEntry" to the path "HKCU:\Software\MyApp".

.VERSION
    1.0.0 21-03-2023

.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: 01-03-2023   
    Última modificación: 01-03-2023
    Versión:  1.0.1
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>
function Remove-RegistryEntry {
    param (
        [ValidateSet("HKLM:\", "HKCU:\", "HKCR:\", "HKU:\", "HKCC:\")]
        [string]$hive,
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter()]
        [string]$RegistryName
    )
    $pathFull = $hive + $path
    if (-not (Test-Path $pathFull)) {
        return Write-Output "Unable to localized registry key $pathFull"
    }
    If($RegistryName){
        try{
        Remove-ItemProperty -Path $pathFull -Name $RegistryName -Force -ErrorAction Stop | Out-Null
        return $true
        } catch {
        return Write-Output "Unable to remove registry entry $RegistryName"
        }
    } else {
        try{
        Remove-Item -Path $pathFull -Force -ErrorAction Stop | Out-Null
        return $true
        } catch {
        return Write-Output "Unable to remove registry key $pathFull"
        }
    }
}