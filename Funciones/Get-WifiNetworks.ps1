    <#
    .SYNOPSIS
        List all Wifi Networks in range
    
    .DESCRIPTION
        List all Wifi Networks in range with these properties: SSID - Index- Network Type - Authentication - Encryption - BSSID1 - Signal - Wifi Mode - Frecuency - Channel
        Only show the properties of one bssid if both bssids are active.
    
    .EXAMPLE
         Get-WifiNetworks
    
    .NOTES
        Author:  Alejandro Aguado Garcia
        Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
        Twitter: @Alejand94399487
        Github: https://github.com/Iber1to
    #>     
function Get-WifiNetworks{    
        # Capture Wifi networks list
        $listWifis = netsh wlan sh net mode=bssid
    
        # Capture only data lines
        $networksTemp = @()
        foreach ($item in $listWifis){
            if ($item -match '^SSID (\d+) : (.*)$'){
            $networksTemp += $item    
            }
            else{
                if ($item -match '^\s+(.*)\s+:\s+(.*)\s*$'){
                    $networksTemp += $item
                }
            }
        }
    
        # Variables for create WifiNetworksObjects
        $countForCycleObject = 0
        $countExclusions = 0
        $Wifynetworks = @() 
        foreach ($item in $networksTemp){
            # Exlude secon BSSID for Routers with 2.4Gh $ 5Gh enabled
            if ($item -match 'BSSID 2'){$countExclusions++}
            if ($countExclusions -ge 1){$countExclusions++}
    
            # Create Object
            if ($countExclusions -eq 0){
                if ($item -match '^SSID (\d+) : (.*)$'){
                    $countForCycleObject++
                    $newNetwork = New-Object -TypeName PSCustomObject
                    $newNetwork | Add-Member -MemberType NoteProperty -Name "SSID" -Value  $matches[2].trim()
                    $newNetwork | Add-Member -MemberType NoteProperty -Name "Index" -Value  $matches[1].trim()
                }
                if ($item -match '^\s+(.*)\s+:\s+(.*)\s*$'){
                    $countForCycleObject++
                    switch ($countForCycleObject)
                        {
                    2 {$newNetwork | Add-Member -MemberType NoteProperty -Name "Network Type" -Value  $matches[2].trim()}
                    3 {$newNetwork | Add-Member -MemberType NoteProperty -Name "Authentication" -Value  $matches[2].trim()}
                    4 {$newNetwork | Add-Member -MemberType NoteProperty -Name "Encryption" -Value  $matches[2].trim()}
                    5 {$newNetwork | Add-Member -MemberType NoteProperty -Name "BSSID1" -Value  $matches[2].trim()}
                    6 {$newNetwork | Add-Member -MemberType NoteProperty -Name "Signal" -Value  $matches[2].trim()}
                    7 {$newNetwork | Add-Member -MemberType NoteProperty -Name "Wifi Mode" -Value  $matches[2].trim()}
                    8 {$newNetwork | Add-Member -MemberType NoteProperty -Name "Frecuency" -Value  $matches[2].trim()}
                    9 {$newNetwork | Add-Member -MemberType NoteProperty -Name "Channel" -Value  $matches[2].trim()}
                        }      
                }
                # Add object to Array and reset count    
                if ($countForCycleObject -eq 9){
                    $Wifynetworks += $newNetwork
                    $countForCycleObject = 0
                }
            }
            # Reset Exclusions counter
            if ($countExclusions -eq 6){$countExclusions = 0}
        }
    return $Wifynetworks
    }