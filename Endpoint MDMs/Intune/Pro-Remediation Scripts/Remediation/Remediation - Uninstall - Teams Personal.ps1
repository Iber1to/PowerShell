Try{
 
    Get-AppxPackage -Name "MicrosoftTeams" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object {$_.DisplayName -eq "MicrosoftTeams"} | Remove-AppxProvisionedPackage -Online
 
    Write-Host "Built-In Teams Chat app uninstalled"
    Exit 0
}
catch {
    $errMsg = $_.Exception.Message
    return $errMsg
    Exit 1
}