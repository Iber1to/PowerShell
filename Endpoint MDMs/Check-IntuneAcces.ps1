Function TestPort {
    [cmdletbinding()]
    param(
        [parameter(mandatory,valuefrompipeline)]
        [string]$Name,
        [parameter(mandatory)]
        [int[]]$Port
    )
    
        process
        {
            foreach($i in $port)
            {
                try
                {
                    $testPort = [System.Net.Sockets.TCPClient]::new()
                    $testPort.SendTimeout = 5
                    $testPort.Connect($name, $i)
                    $result = $testPort.Connected
                }
                catch
                {
                    $result = $false
                }
                
                [pscustomobject]@{
                    ServerName = $name
                    Port = $i
                    TestConnection = $result
                }
            }
            
            $testPort.Close()
        }
    }

$urlArray2ports = @(
    'login.microsoftonline.com',
    'config.office.com',
    'graph.windows.net',
    'portal.manage.microsoft.com',
    'm.manage.microsoft.com',
    'Manage.microsoft.com',
    'i.manage.microsoft.com',
    'r.manage.microsoft.com',
    'a.manage.microsoft.com',
    'p.manage.microsoft.com',
    'EnterpriseEnrollment.manage.microsoft.com',
    'EnterpriseEnrollment-s.manage.microsoft.com',
    'portal.fei.amsua0202.manage.microsoft.com',
    'm.fei.amsua0202.manage.microsoft.com',
    'portal.fei.amsua0402.manage.microsoft.com',
    'm.fei.amsua0402.manage.microsoft.com'
    'portal.fei.amsub0202.manage.microsoft.com',
    'm.fei.amsub0202.manage.microsoft.com',
    'portal.fei.amsub0302.manage.microsoft.com',
    'm.fei.amsub0302.manage.microsoft.com',
    'portal.fei.amsub0502.manage.microsoft.com',
    'm.fei.amsub0502.manage.microsoft.com',
    'portal.fei.amsud0101.manage.microsoft.com',
    'm.fei.amsud0101.manage.microsoft.com',
    'enterpriseregistration.windows.net',
    'Admin.manage.microsoft.com',
    'Admin.manage.microsoft.com',
    'manage.microsoft.com',
    'euprodimedatapri.azureedge.net',
    'euprodimedatasec.azureedge.net',
    'euprodimedatahotfix.azureedge.net'
    'catalog.update.microsoft.com'  
)

$urlArray443port = @(
    'fef.msua01.manage.microsoft.com',
    'fef.msua02.manage.microsoft.com',
    'fef.msua04.manage.microsoft.com',
    'fef.msua05.manage.microsoft.com',
    'fef.msua06.manage.microsoft.com',
    'fef.msua07.manage.microsoft.com',
    'fef.msub01.manage.microsoft.com',
    'fef.msub02.manage.microsoft.com',
    'fef.msub03.manage.microsoft.com',
    'fef.msub05.manage.microsoft.com',
    'fef.msuc01.manage.microsoft.com',
    'fef.msuc02.manage.microsoft.com',
    'fef.msuc03.manage.microsoft.com',
    'fef.msuc05.manage.microsoft.com',
    'fef.amsua0202.manage.microsoft.com',
    'fef.amsua0402.manage.microsoft.com',
    'fef.amsua0502.manage.microsoft.com',
    'fef.amsua0602.manage.microsoft.com',
    'fef.amsub0102.manage.microsoft.com',
    'fef.amsub0202.manage.microsoft.com',
    'fef.amsub0302.manage.microsoft.com',
    'fef.amsua0102.manage.microsoft.com',
    'fef.amsua0702.manage.microsoft.com',
    'fef.amsub0502.manage.microsoft.com',
    'fef.msud01.manage.microsoft.com',
    'mam.manage.microsoft.com'
)
$urlArrayportError = @()
foreach ($currentItemName in $urlArray2ports) {
    if ((TestPort $currentItemName -Port 80,443).TestConnection -eq $false){
        $urlArrayportError += $currentItemName
    }
}
foreach ($currentItemName in $urlArray443port) {
    if ((TestPort $currentItemName -Port 443).TestConnection -eq $false){
        $urlArrayportError += $currentItemName
    }
}
if($urlArrayportError){
    Write-Output $urlArrayportError
}
else{Write-Output 'Connectivity OK'}
