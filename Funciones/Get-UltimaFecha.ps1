#Busca la fecha mas reciente en un array
 <#
    .SYNOPSIS
        List all Wifi Networks in range
    
    .DESCRIPTION
        List all Wifi Networks in range with these properties:
            SSID - Index- Network Type - Authentication - Encryption - BSSID1 - Signal - Wifi Mode - Frecuency - Channel
        Only show the properties of one bssid if both bssids are active.
    
    .EXAMPLE
         Get-WifiNetworks
    
    .NOTES
        Author:  Alejandro Aguado Garcia
        Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
        Twitter: @Alejand94399487
        Github: https://github.com/Iber1to
    #> 
function UltimaFecha {
    Begin { $latest = $null }
    Process {
            if (($_ -ne $null) -and (($null -eq $latest) -or ($_ -gt $latest))) {
                $latest = $_ 
            }
    }
    End { $latest }
}