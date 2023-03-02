<#
.SYNOPSIS
    This PowerShell function adds a registry entry to the specified path.

.DESCRIPTION
    This function creates a new registry entry at the specified path with the specified name and value. It also allows you to specify the type of registry entry. If the path does not exist, it is created.

.PARAMETER Path
    The path of the registry entry.

.PARAMETER RegistryName
    The name of the registry entry.

.PARAMETER Value
    The value of the registry entry.

.PARAMETER ValueType
    The type of the registry entry. Valid values are "String", "Binary", "DWord", "MultiString", "ExpandString", "QWord", and "unknown".

.EXAMPLE
    Add-RegistryEntry -Path "HKCU:\Software\MyApp" -RegistryName "MyEntry" -Value "MyValue" -ValueType "String"
    This command adds a new registry entry named "MyEntry" with the value "MyValue" to the path "HKCU:\Software\MyApp".

.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: 01-03-2023   
    Última modificación: 01-03-2023
    Versión:  1.0.0
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>
function Add-RegistryEntry {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$RegistryName,
        [string]$Value,
        [ValidateSet("String", "Binary", "DWord", "MultiString", "ExpandString", "QWord", "unknown")]
        [string]$ValueType
    )

    if (-not (Test-Path $Path)) {
        try{New-Item -Path $Path -Force | Out-Null} catch {return "Unable to create registry key $Path"}
    }

    try{New-ItemProperty -Path $Path -Name $RegistryName -Value $Value -PropertyType $ValueType -Force | Out-Null} catch {return "Unable to create registry entry $RegistryName"}
}
