Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm:$false -Force:$true
Install-Script get-windowsautopilotinfo -Confirm:$false -Force:$true
get-windowsautopilotinfo -Online -TenantId "your tenant" -AppId "your appId" -AppSecret "your appsecret" -grouptag "your grouptag"
shutdown.exe /s /t 10