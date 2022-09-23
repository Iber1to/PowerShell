 <#
    .SYNOPSIS
        Find the last date in an array
    
    .DESCRIPTION
        Find the last date in an array
    
    
    .EXAMPLE
        $Date = $Searcher.QueryHistory(0, $HistoryCount) |  UltimaFecha 

    
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