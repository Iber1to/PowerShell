#Estableciendo variables
$ErrorActionPreference = "Stop"
$query = (Get-WmiObject -ClassName Win32_computersystem).UserName
$domain = $query.Split('\')[0]
$user = $query.Split('\')[1]
$ntAccount = new-object System.Security.Principal.NTAccount($domain, $user)
$sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
New-PSDrive -PSProvider Registry -Name HKUS -Root HKEY_USERS 
$oneDriveRute = "HKUS:$sid\SOFTWARE\Policies\Microsoft\"


#Generando las entradas de registro para limitar la velocidad de OneDrive
try {

    New-Item -Path $oneDriveRute -Name 'OneDrive' -Force
    $oneDriveRute += 'OneDrive\'
    New-ItemProperty -Path $oneDriveRute -Name 'DownloadBandwidthLimit' -PropertyType 'dword' -Value '126' -Force
    New-ItemProperty -Path $oneDriveRute -Name 'UploadBandwidthLimit' -PropertyType 'dword' -Value '126' -Force 
    Remove-PSDrive -Name HKUS
    Write-Output 'Sucess'
    exit 0
}

catch {
    Remove-PSDrive -Name HKUS
    Write-Output 'Fail'
    exit 1        
}