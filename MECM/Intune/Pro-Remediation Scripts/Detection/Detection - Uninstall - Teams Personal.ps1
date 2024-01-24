try {
 
    $TeamsApp = Get-AppxPackage "*Teams*" -AllUsers  -ErrorAction SilentlyContinue
    if ($TeamsApp.Name -eq "MicrosoftTeams")
        {
            Write-Host "Built-in Teams Chat App Detected"
            Exit 1
        }
    ELSE
        {
            Write-Host "Built-in Teams Chat App Not Detected"
            Exit  0
               }
}
catch {
    $errMsg = $_.Exception.Message
    return $errMsg
    Exit 1
}