$checkEnable = Get-WindowsOptionalFeature -Online -FeatureName NetFx3
if($checkEnable.state -eq "Enabled"){
Write-Output "NetFx3 Habilitado"
Exit 0
}
else{
    Write-Output "NetFx3 Deshabilitado"
    Exit 1   
}