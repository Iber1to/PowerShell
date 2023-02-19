# Ejemplo: .\cambiaUPN.ps1 -TxtFile .\rename.txt
# Devuelve un archivo "changelog_.txt" en la misma ruta donde esta cambiaUPN.ps1 con los cambios realizados
# Devuelve un archivo "errorlog_.txt" misma ruta donde esta cambiaUPN.ps1 con los usuarios que no ha podido cambiar

[CmdletBinding()]
param ([string]$TxtFile)
$Users= Get-Content -Path $TxtFile
$Ed=[Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))
$NameLog= "changelog_"+"$Ed.txt"
$NameLogError= "errorlog_"+"$Ed.txt"
$newUpn="@Contoso.dev"


foreach ($user in $Users)
{

Try{
    $userOldUpn= Get-ADUser -Identity $user | Select-Object UserPrincipalName
    $userOldUpn | Out-File -NoNewline ".\$NameLog" -Append

    Set-ADUser -UserPrincipalName "$user$newUpn" -Identity $user
    Set-ADUser -Identity $user -Replace @{extensionAttribute9="PILOT-UPN-CHANGE"}

    $UserNewUpn= Get-ADUser -Identity $user | Select-Object UserPrincipalName
    Write-Output " ----> " | Out-File -NoNewline ".\$NameLog" -Append
    $UserNewUpn.UserPrincipalName | Out-File ".\$NameLog" -Append
    }

Catch{$User | Out-File ".\$NameLogError" -Append}
    
}                         
                   