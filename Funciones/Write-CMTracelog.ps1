<#
.SYNOPSIS
    Add a lgo entry

.DESCRIPTION
    Add entries to an existing log file or create a new one.

.PARAMETER Path
    File path. If omitted, the variable PathCMTracelog parameter must be configured out of function.

.PARAMETER PathCMTracelog
    Variable to declare in the script that uses the function with the path to the log file.
    Used to avoid constantly passing the 'Path' parameter.  

.PARAMETER Message
    Content to be added to the entry.

.PARAMETER Component
    Component that adds the entry to the log. By default it adds the function itself.

.PARAMETER Type
    Type of message to add. The default value is 'Information' . The other values are Warning' and 'Error'.

.EXAMPLE
     $PathCMTracelog= 'C:\Temp\logalternativo.log'
     Write-CMTracelog 'This is a default test message'
     Output= This is a default test message  Write-CMTracelog 31/08/2021 13:21:20 0 (0x0)

.EXAMPLE
    Write-CMTracelog -Path C:\Temp\logalternativo.log -Message $error[0] -Type Error -Component $MyInvocation.MyCommand.Name


.NOTES
    Author:  Alejandro Aguado Garcia
    Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Twitter: @Alejand94399487
    Github: https://github.com/Iber1to
#> 

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
          [String]$Component= $MyInvocation.MyCommand.Name,

          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [ValidateSet("Information", "Warning", "Error")]
          [String]$Type = 'Information'
    )

    if(!$Path){
        $Path= $PathCMTracelog
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