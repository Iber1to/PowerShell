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
    The type of the registry entry. Valid values are "String" (REG_SZ), "Binary" (REG_BINARY), "DWord" (REG_DWORD), "MultiString" (REG_MULTI_SZ), "ExpandString" (REG_EXPAND_SZ), "QWord" (REG_QWORd), and "unknown" (REG_SZ).

.EXAMPLE
    Add-RegistryEntry -Path "HKCU:\Software\MyApp" -RegistryName "MyEntry" -Value "MyValue" -ValueType "String"
    This command adds a new registry entry named "MyEntry" with the value "MyValue" to the path "HKCU:\Software\MyApp".

.VERSION
    1.0.1 15-03-2023
        - Modify the function to overwrite the value if the registry entry already exists.
        - Modify comments "ValueType" to show the name values of the registry entry types as they appear in the registry editor.
    1.0.2 21-03-2023
        - Fix the function to create the registry entry if the value is "Binary".
        - Fixed a bug that function continued execution if try-catching failed.
        

.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: 01-03-2023   
    Última modificación: 01-03-2023
    Versión:  1.0.1
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>
function Add-RegistryEntry {
    param (
        [ValidateSet("HKLM:\", "HKCU:\", "HKCR:\", "HKU:\", "HKCC:\")]
        [string]$hive,
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$RegistryName,
        [ValidateSet("String", "Binary", "DWord", "MultiString", "ExpandString", "QWord", "unknown")]
        [string]$ValueType,
        [string]$Value
    )
    $pathFull = $hive + $path
    if(($value)-and (-not $ValueType)){ throw "You must specify the ValueType parameter." }
    if (-not (Test-Path $pathFull)) {
        try{
            New-Item -Path $pathFull -Force -ErrorAction Stop | Out-Null
        } catch {
            return Write-Output "Unable to create registry key $pathFull"
        }
    }
    if($ValueType -eq "Binary"){ 
        $ValueBinary = [System.Text.Encoding]::ASCII.GetBytes($Value)
        try{
            New-ItemProperty -Path $pathFull -Name $RegistryName -Value $ValueBinary -PropertyType $ValueType -Force -ErrorAction Stop | Out-Null
            return $true
        } catch {return Write-Output "Unable to create registry entry $RegistryName"}
    }
    else{
        try{
            New-ItemProperty -Path $pathFull -Name $RegistryName -Value $Value -PropertyType $ValueType -Force -ErrorAction Stop | Out-Null
            return $true
        } catch { return Write-Output "Unable to create registry entry $RegistryName" }
    }
}