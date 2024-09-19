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
$scriptname = "Remediation-Uninstall-Adobe Acrobat (64-bit)"
$filename   = "$scriptname-${username}-${hostname}-${datetime}.log"
$logfilename = Join-Path -Path $logpath -ChildPath $filename
$PathCMTracelog = $logfilename
$ComponentSource = "Remediation"
#endregion "log parameters"
# Test logpath
if(-not (Test-Path $logpath)){
	New-Item -ItemType Directory -Path $logpath -Force
}
#endregion log

#region "Procces script"
Write-CMTracelog "Start execution: $scriptname" 
 
try{
    Write-CMTracelog "Uninstalling Adobe Acrobat (64-bit)"
    Start-Process -filepath "wmic" -argumentlist 'product where name="Adobe Acrobat (64-bit)" call uninstall' -wait -WindowStyle Hidden
    Write-CMTracelog "Uninstalling Adobe Acrobat (64-bit) Completed" -Type Warning
    }catch{Write-CMTracelog "$($_.Exception.Message)" -Component "WMIC" -Type Error}
#endregion "Procces"