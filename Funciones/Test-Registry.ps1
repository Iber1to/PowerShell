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

.PARAMETER value
    Optional. The value of the registry value you want to verify within the specified key. If not provided, the function will only check the existence of the registry value.

.EXAMPLE
    Test-Registry -hive "HKLM:\" -path "Software\MyCompany\MyApp" -RegistryName "Version"
    This example verifies the existence of the "Version" value in the registry key "HKLM:\Software\MyCompany\MyApp". It returns $true if the value exists, and $false otherwise.

    Test-reg -hive "HKLM:\" -path "Software\MyCompany\MyApp" -RegistryName "Version" -value "1.0.0"
    This example verifies the existence of the "Version" value in the registry key "HKLM:\Software\MyCompany\MyApp". It returns $true if the value exists and its value is "1.0.0", and $false otherwise.

    Test-Registry -hive HKCU:\ -Path "Software\Policies\Microsoft\Office\16.0\Outlook\Options\Mail"
    This example verifies the existence of the registry key "HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Options\Mail". It returns $true if the key exists, and $false otherwise.

.VERSION
    1.0.0 15-03-2023
    1.1.0 21-03-2023 - Added the ability to check the value of a registry value.
                     - Added the ability to check the existence of a registry key.
                     - Fixed a bug that prevented the function from working properly when the registry value was a binary value.
                     - Fixed a bug that function continued execution if try-catching failed.

    
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
        [string]$RegistryName,
        [ValidateSet("String", "Binary", "DWord", "MultiString", "ExpandString", "QWord", "unknown")]
        [string]$ValueType,
        [string]$value

    )
    $pathFull = $hive + $path
    if(($value)-and (-not $ValueType)){ throw "You must specify the ValueType parameter." }
    if(($value) -and ($ValueType -ne "Binary")){
        try{
            $result = get-itemproperty -path $pathFull -name $RegistryName -ErrorAction Stop | Out-Null
            if($result.$RegistryName -eq $value){
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
    if(($value) -and ($ValueType -eq "Binary")){
        try{
            $result = get-itemproperty -path $pathFull -name $RegistryName -ErrorAction Stop | Out-Null
            $hexString = [System.Text.Encoding]::ASCII.GetString($result.$RegistryName)
            if($hexString -eq $value){
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
    if($RegistryName){
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
    if((-not $value) -and (-not $RegistryName)){
        try{
            $result = get-item -path $pathFull -ErrorAction Stop | Out-Null
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
}