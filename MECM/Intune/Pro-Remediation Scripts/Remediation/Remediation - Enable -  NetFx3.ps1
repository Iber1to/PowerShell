try{
    Enable-WindowsOptionalFeature -Online -FeatureName NetFx3
    Write-Output "NetFx3 Habilitado"
    }
catch{Write-Output $Error}