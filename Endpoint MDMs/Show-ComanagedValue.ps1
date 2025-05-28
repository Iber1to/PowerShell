<#
.SYNOPSIS
    This PowerShell function is used to determine whether a device is being managed by SCCM (System Center Configuration Manager) or by Intune.

.DESCRIPTION
    The script determines whether the device is being managed by SCCM or by Intune. It checks the value of CoManagementFlags in the registry key "HKLM:SOFTWARE\Microsoft\CCM"to determine if the device is being managed by SCCM. 
    If the value matches one of the values in the $SCCMUpdates array, the device is being managed by SCCM. 
    If the value does not match any of the values in the $SCCMUpdates array, the device is being managed by Intune. 
    If a value for CoManagementFlags cannot be obtained, it is considered that the device is not being co-managed.
.PARAMETER Param1
    This function does not accept any parameters.

.PARAMETER Param2
    [Descripción del parámetro 2, incluyendo su función, valor predeterminado (si lo tiene), etc.]

.EXAMPLE
    Show-ComanagedValue
.NOTES
    Autor: Alejandro Aguado García
    Fecha de creación: [Fecha de creación del script]
    Última modificación: [Fecha de última modificación]
    Versión: 1.0.0
#>
function Show-ComanagedValue{
    [CmdletBinding()]
    param()
    $coManaged = (Get-ItemProperty -Path 'HKLM:SOFTWARE\Microsoft\CCM' -Name CoManagementFlags -ErrorAction SilentlyContinue).CoManagementFlags 
    $SCCMUpdates = @(1,3,5,7,9,11,13,15,33,35,37,39,41,43,45,65,67,71,73,75,77,79,97,99,101,103,105,107,109,111,,129,131,135,137,139,141,143,161,163,165,167,169,171,173,175,193,195,197,199,201,203,207,225,227,229,231,233,235,237,239)
    if ($coManaged){
        if($SCCMUpdates -Contains $coManaged){
            return "Valor: $coManaged - Managed by SCCM"
        }
        else{
            return "Value: $coManaged - Managed by Intune"
        }
    }
    else {
        return "Device is not co-managed"
    }
} 
