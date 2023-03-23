<#
.SYNOPSIS
    This PowerShell function adds or modify a registry entry to the specified path.

.DESCRIPTION
    This function creates a new registry entry at the specified path with the specified name and value. It also allows you to specify the type of registry entry. If the path does not exist, it is created. Returns a boolean value.

.PARAMETER Path
    The path of the registry entry.

.PARAMETER RegistryName
    The name of the registry entry.

.PARAMETER Value
    The value of the registry entry.

.PARAMETER ValueType
    The type of the registry entry. Valid values are "String" (REG_SZ), "Binary" (REG_BINARY), "DWord" (REG_DWORD), "ExpandString" (REG_EXPAND_SZ), "QWord" (REG_QWORd).

.EXAMPLE
    Add-RegistryEntry -Path "HKCU:\Software\MyApp" -RegistryName "MyEntry" -Value "MyValue" -ValueType "String"
    This command adds a new registry entry named "MyEntry" with the value "MyValue" to the path "HKCU:\Software\MyApp".

    Add-RegistryEntry -Path "HKCU:\Software\MyApp" -RegistryName "MyEntry" -Value "MyValue2" -ValueType "String"
    This command modify a existing registry entry named "MyEntry" with the value "MyValue2" to the path "HKCU:\Software\MyApp".

    Add-RegistryEntry -Path "HKCU:\Software\MyApp\newbranch"
    This command creates a new branch named "newbranch" in the path "HKCU:\Software\MyApp". 

.VERSION
    1.0.1 15-03-2023
        - Modify the function to overwrite the value if the registry entry already exists.
        - Modify comments "ValueType" to show the name values of the registry entry types as they appear in the registry editor.
    1.0.2 21-03-2023
        - Fix the function to create the registry entry if the value is "Binary".
        - Fixed a bug that function continued execution if try-catching failed.
        - Change the function to return a boolean value.
        - Change the function to show the error message if try-catching failed.
        - Change the function to show a message if the parameters "RegistryName", "ValueType" and "Value" are not specified.
        - Modify return function and add error mesaages to console.        

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
        [string]$RegistryName,
        [ValidateSet("String", "Binary", "DWord", "ExpandString", "QWord")]
        [string]$ValueType,
        [string]$Value
    )
    $pathFull = $hive + $path
    if (-not (Test-Path $pathFull)) {
        try{
            New-Item -Path $pathFull -Force -ErrorAction Stop | Out-Null
        } catch {
            Write-Host $Error[0].exception.message
            return $false
        }
    }
    if((-not ($RegistryName)) -and (-not ($ValueType)) -and (-not ($Value))){return $true}
    if((($RegistryName)) -and (-not ($ValueType)) -and (-not ($Value))){
        try{
            New-ItemProperty -Path $pathFull -Name $RegistryName -Force -ErrorAction Stop | Out-Null
            return $true
        }catch{ 
            Write-Host $Error[0].exception.message
            return $false
        }
    }
    if(($value)-and ($ValueType) -and ($RegistryName))
        {
        if($ValueType -eq "Binary"){ 
            $ValueBinary = [System.Text.Encoding]::ASCII.GetBytes($Value)
            try{
                New-ItemProperty -Path $pathFull -Name $RegistryName -Value $ValueBinary -PropertyType $ValueType -Force -ErrorAction Stop | Out-Null
                return $true
            }catch{
                Write-Host $Error[0].exception.message
                return $false
            }
        }
        else{
            try{
                New-ItemProperty -Path $pathFull -Name $RegistryName -Value $Value -PropertyType $ValueType -Force -ErrorAction Stop | Out-Null
                return $true
            }catch{ 
                Write-Host $Error[0].exception.message
                return $false
            }
        }
    }
    else {
        Write-Host "The parameters 'RegistryName', 'ValueType' and 'Value' are necesary."
        return $false
    }
}