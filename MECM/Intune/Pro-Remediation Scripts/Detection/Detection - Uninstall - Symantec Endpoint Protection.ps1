#region log
function Write-CMTracelog {
    [CmdletBinding()]
    Param(

          [Parameter(Mandatory=$true)]
          [String]$Message,
            
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]$Path,
                  
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]$Component,

          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [ValidateSet("Information", "Warning", "Error")]
          [String]$Type = 'Information'
    )

    if(!$Path){
        $Path= $PathCMTracelog
        }
    if(!$Component){
        $Component= $ComponentSource
        }
        
    switch ($Type) {
        "Info" { [int]$Type = 1 }
        "Warning" { [int]$Type = 2 }
        "Error" { [int]$Type = 3 }
    }

    # Create a CMTrace formatted entry
    $Content = "<![LOG[$Message]LOG]!>" +`
        "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
        "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
        "component=`"$Component`" " +`
        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
        "type=`"$Type`" " +`
        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
        "file=`"`">"

    # Add the line to the log file   
    Add-Content -Path $Path -Value $Content
}
#region "log parameters"
$logpath  = 'C:\Windows\Logs\Uninstall\'
$username   = $env:USERNAME
$hostname   = hostname
$datetime   = Get-Date -f 'yyyyMMddHHmmss'
$scriptname = "Detection-Uninstall-Symantec Endpoint Protection"
$filename   = "$scriptname-${username}-${hostname}-${datetime}.log"
$logfilename = Join-Path -Path $logpath -ChildPath $filename
$PathCMTracelog = $logfilename
$ComponentSource = "Detection"
#endregion "log parameters"
# Test logpath
if(-not (Test-Path $logpath)){
	New-Item -ItemType Directory -Path $logpath -Force
}
#endregion log

#region "Procces"
Write-CMTracelog "Start execution: $scriptname"
Write-CMTracelog "Searching for Apps"
$App001 = Get-Package | Where-Object {$_.Name -eq 'Symantec Endpoint Protection'}
if ($App001) {
    Write-Host "App detected"
    Write-CMTracelog "App detected"
    Write-CMTracelog "End execution: $scriptname"
    exit 1
}else{
    Write-CMTracelog "Not App detected"
    Write-Host "Not App detected"
    Write-CMTracelog "End execution: $scriptname"
    exit 0
}
#endregion "Procces"