    <#
    .SYNOPSIS
        List all Wifi Networks interfaces in the endpoint
    
    .DESCRIPTION
        List all Wifi Networks in range with these properties:
            Name - Description - GUID - Address - Interface Type - State - RadioState 
        Only show the properties of one bssid if both bssids are active.
    
    .EXAMPLE
         Get-WifiNetworkInterfaces
    
    .NOTES
        Author:  Alejandro Aguado Garcia
        Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
        Twitter: @Alejand94399487
        Github: https://github.com/Iber1to
    #>     
    function Get-WifiNetworkInterfaces{    
        # Capture Wifi networks list
        $listWifis = netsh wlan show interfaces
    
        # Capture only data lines
        $networksTemp = @()
        foreach ($item in $listWifis){
            if ($item -match '^\s+(.*)\s+:\s+(.*)\s*$'){
                    $networksTemp += $item
                }
        }
    
        # Variables for create WifiNetworksObjects
        $countForCycleObject = 0
        $WifynetworksInterfaces = @() 
        foreach ($item in $networksTemp){
            # Create Object
            if($countForCycleObject -eq 0){$newNetwork = New-Object -TypeName PSCustomObject}
            if ($item -match '^\s+(.*)\s+:\s+(.*)\s*$'){
                $countForCycleObject++               
                switch ($countForCycleObject)
                    {
                    1 {$newNetwork | Add-Member -MemberType NoteProperty -Name "Name" -Value  $matches[2].trim()}
                    2 {$newNetwork | Add-Member -MemberType NoteProperty -Name "Description" -Value  $matches[2].trim()}
                    3 {$newNetwork | Add-Member -MemberType NoteProperty -Name "GUID" -Value  $matches[2].trim()}
                    4 {$newNetwork | Add-Member -MemberType NoteProperty -Name "Address" -Value  $matches[2].trim()}
                    5 {$newNetwork | Add-Member -MemberType NoteProperty -Name "Interface Type" -Value  $matches[2].trim()}
                    6 {$newNetwork | Add-Member -MemberType NoteProperty -Name "State" -Value  $matches[2].trim()}
                    7 {$newNetwork | Add-Member -MemberType NoteProperty -Name "RadioState" -Value  $matches[2].trim()}
                    }      
                }
                # Add object to Array and reset count    
            if ($countForCycleObject -eq 7){
                $WifynetworksInterfaces += $newNetwork
                $countForCycleObject = 0
            }
        }
            # Reset Exclusions counter
    return $WifynetworksInterfaces
    }