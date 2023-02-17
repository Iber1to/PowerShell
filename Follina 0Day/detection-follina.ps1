#Detection Method
New-PSDrive -PSProvider Registry -Name HKCR -Root HKEY_CLASSES_ROOT |Out-null
$Msdt = Test-Path 'HKCR:\ms-msdt'
Remove-PSDrive -Name HKCR

If($Msdt){
Write-Output "MsdtExist"
Exit 1
}
else{
Write-Output "MsdtNotExist"
Exit 0
}

<#
#Detection Method
$backupFile = 'C:\Windows\backupreg\follina.reg'
if(Test-Path $backupFile){write-output 'Patch Done', exit 0}
else{write-output 'Without Patch';exit 1}
#>
