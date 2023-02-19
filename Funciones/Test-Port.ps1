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