function Connect-CMSite{
 
     [CmdletBinding()] 
         param (
             [ValidateNotNullOrEmpty()]
             [string]$SiteCode,
             [string]$ProviderMachineName               
               )
     
     # Importando el ConfigurationManager.psd1 module 
     if($null -eq (Get-Module ConfigurationManager)) {
         Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
     }
     
     # Monta la unidad del sitio si no existe todavia
     if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
         New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName
     }
     
     # Cambia la localización al codigo de sitio
     Set-Location "$($SiteCode):\" 
     }

$SCCMServer = 'ESDC1SVPWO033.emea.contoso.local'   
$SiteCode = 'PE1'
$Collection =  '00-GLOBAL_MGM_WS_(Principal_Coll)'
$SQLServer = 'Servidor1.emea.contoso.local'
$SQLDatabase = 'CM_CM1'
$CollectionId = 'CAS00001'
$Domain = '.contoso.local'
   
$ListFailInstall = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query ('SELECT Name, MachineID, CP_LastInstallationError FROM' + [char]32 + 'dbo.' + ((Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query ('Select ResultTableName FROM dbo.Collections WHERE CollectionName =' + [char]32 + [char]39 + $Collection + [char]39)).ResultTableName) + [char]32 + 'WHERE ClientVersion IS NULL AND CP_LastInstallationError = 120 Order By MachineID')  
     If ($ListFailInstall -ne '') {  
          Import-Module $SCCMModule -Force  
          Connect-CMSite -SiteCode $SiteCode -ProviderMachineName $SCCMServer  
          #$ListFailInstall | ForEach-Object { (Get-CMDevice -ResourceId $_.MachineID -Fast).Name }
          $ListFailInstall | ForEach-Object { Get-CMDevice -ResourceId $_.MachineID -Fast | Remove-CMDevice -Confirm:$false -Force }   
          
} else {  
          Exit 1  
}
$loadDuplicates = Get-CMDevice -CollectionId $CollectionId -Fast
$loadDuplicates | Where-Object -FilterScript{$_.ResourceID -clike '209*'} | Remove-CMDevice -Confirm:$false -Force
Invoke-CMCollectionUpdate -CollectionId $CollectionId
$loadDuplicates = Get-CMDevice -CollectionId $CollectionId -Fast


foreach ($item in $loadDuplicates) {
     $itemMirror = $loadDuplicates | Where-Object -FilterScript{($_.Name -eq $item.Name) -and ($_.ResourceID -ne $item.ResourceID)}
     If($itemMirror){
          $pingitemMirror = Test-Connection $($itemMirror.Name+'.'+$itemMirror.Domain+$Domain)
          $pingitem = Test-Connection $($item.Name+'.'+$item.Domain+$Domain)
          if($pingitemMirror.PingSucceeded -eq $true -and $pingitem.PingSucceeded -eq $false){
               Remove-CMDevice -ResourceId $itemMirror.ResourceID -Confirm:$false -Force
          }
          if(($itemMirror.DeviceOS -match '6') -and ($item.DeviceOS -match '10')){
               Remove-CMDevice -ResourceId $itemMirror.ResourceID -Confirm:$false -Force
          }
          elseif(($item.DeviceOS -match '6') -and ($itemMirror.DeviceOS -match '10')){
               Remove-CMDevice -ResourceId $item.ResourceID -Confirm:$false -Force
          }
          elseif (($itemMirror.DeviceOSBuild.split('.')[0] -eq $item.DeviceOSBuild.split('.')[0]) -and ($itemMirror.DeviceOSBuild.split('.')[-1] -gt $item.DeviceOSBuild.split('.')[-1])) {
               Remove-CMDevice -ResourceId $item.ResourceID -Confirm:$false -Force
          }
     }
}
Invoke-CMCollectionUpdate -CollectionId $CollectionId
Remove-PSDrive -Name $SiteCode -Force  

