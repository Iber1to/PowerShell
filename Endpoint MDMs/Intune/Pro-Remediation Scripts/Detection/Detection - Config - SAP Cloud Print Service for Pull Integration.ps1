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
$logpath  = 'C:\Windows\Logs\Intune-Detection\'
$username   = $env:USERNAME
$hostname   = hostname
$datetime   = Get-Date -f 'yyyyMMddHHmmss'
$scriptname = "Detection - Config - SAP Cloud Print Service for Pull Integration"
$filename   = "${scriptname}-${username}-${hostname}-${datetime}.log"
$logfilename = Join-Path -Path $logpath -ChildPath $filename
$PathCMTracelog = $logfilename
$ComponentSource = $MyInvocation.MyCommand.Name
#endregion "log parameters"
# Test logpath
if(-not (Test-Path $logpath)){
	New-Item -ItemType Directory -Path $logpath -Force |Out-Null
}
#endregion log
# Nombre del servicio a comprobar
$ServiceName = "Sap Cloud Print Service for Pull Integration"

Write-CMTracelog "Start execution Script: ${scriptname}"
# Comprobar si el servicio existe
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
Write-CMTracelog "Check if the service $ServiceName exists"

if (-not $service) {
    # El servicio no está instalado
    Write-Output "The service $ServiceName is not installed"
    Write-CMTracelog "The service $ServiceName is not installed"
    Write-CMTracelog "Its necesary install the service before remediation"
    Write-CMTracelog "End execution Script: ${scriptname}"
    exit 0
}

# Comprobar si el servicio está configurado para ejecutarse como "System"
Write-CMTracelog "Check if the service $ServiceName is configured to run as System or Administrator"
$serviceConfig = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
if  ($serviceConfig.StartName -eq "LocalSystem" -or $serviceConfig.StartName -eq ".\Administrador") {
    # El servicio no está configurado como "System"
    Write-Output "The service $ServiceName is configured to run as LocalSystem or Administrador."
    Write-CMTracelog "The service $ServiceName is configured to run as LocalSystem or Administrador."
    Write-CMTracelog "Its necesary run remediation script to configure the service"
    Write-CMTracelog "End execution Script: ${scriptname}"
    exit 1
}

# Todo está correcto
Write-Output "The service $ServiceName is configured correctly."
Write-CMTracelog "The service $ServiceName is configured correctly."
Write-CMTracelog "End execution Script: ${scriptname}"
exit 0