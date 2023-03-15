<#
.SYNOPSIS
    Verifies the existence of a registry key or value on the system.

.DESCRIPTION
    The Test-Registry function checks the existence of a registry key or value on the system, using the registry hive, the key path, and optionally, a specific value.

.PARAMETER hive
    The registry hive location. Accepts one of the following values: "HKLM:\", "HKCU:\", "HKCR:\", "HKU:\" or "HKCC:\".

.PARAMETER path
    The registry key path you want to verify.

.PARAMETER RegistryName
    Optional. The name of the registry value you want to verify within the specified key. If not provided, the function will only check the existence of the registry key.

.EXAMPLE
    Test-Registry -hive "HKLM:\" -path "Software\MyCompany\MyApp" -RegistryName "Version"
    This example verifies the existence of the "Version" value in the registry key "HKLM:\Software\MyCompany\MyApp". It returns $true if the value exists, and $false otherwise.

    Test-Registry -hive HKCU:\ -Path "Software\Policies\Microsoft\Office\16.0\Outlook\Options\Mail"
    This example verifies the existence of the registry key "HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Options\Mail". It returns $true if the key exists, and $false otherwise.

.NOTES
    Author: Alejandro Aguado García
    Creation date: 15-03-2023
    Last modification: 15-03-2023
    Version:  1.0.0
    LinkedIn: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    GitHub:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#>

function Test-Registry {
    param (
        [ValidateSet("HKLM:\", "HKCU:\", "HKCR:\", "HKU:\", "HKCC:\")]
        [string]$hive,
        [string]$path,
        [string]$RegistryName
    )
    $pathFull = $hive + $path
    if($value){
        try{
            $result = get-itemproperty -path $pathFull -name $RegistryName -ea 0
            if($result){
                return $true
            }
            else{
                return $false
            }
        }
        catch{
            if($_.Exception -is [System.Management.Automation.MethodInvocationException]){
                return $false
            }
            else{
                throw $_
            }
        }
    }
    else{
        return (Test-Path -path $pathFull -ea 0)
    }
}