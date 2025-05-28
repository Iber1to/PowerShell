#Uninstall Docker Desktop
try {
    Start-Process -FilePath Start-Process -FilePath 'C:\Program Files\Docker\Docker\Docker Desktop Installer.exe' -ArgumentList uninstall -Wait
    $testUninstall = Get-ChildItem HKLM:\software\microsoft\windows\currentversion\uninstall | ForEach-Object {Get-ItemProperty $_.PSPath}  | Where-Object { $_.DisplayName -match "Docker" } 
    if($testUninstall)
        {
            Write-Output 'Uninstall Fail'
            Exit 1
        }
    else 
    {
            Write-Output 'Uninstall Succes'
            Exit 0 
    }
    
}   
catch {
    Write-Output 'Uninstall Fail'
    Exit 1
}