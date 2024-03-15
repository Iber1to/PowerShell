
#region FUNCTION
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
#endregion FUNCTION

#region "log parameters"
$logpath  = 'C:\Windows\Temp'
$username   = $env:USERNAME
$hostname   = hostname
$datetime   = Get-Date -f 'yyyyMMddHHmmss'
$scriptname = "Delete-TaskScheduled"
$filename   = "${scriptname}-${username}-${hostname}-${datetime}.log"
$logfilename = Join-Path -Path $logpath -ChildPath $filename
$PathCMTracelog = $logfilename
$ComponentSource = $MyInvocation.MyCommand.Name
#endregion "log parameters"

#region "Delete Task"
Write-CMTracelog "Start execution: ${scriptname}" 

# Parameters
$taskIsDeleted = $false
$taskName = "InventoryDevice"

# Check if task exists
$listTasks = get-scheduledtask -TaskName $taskName -ErrorAction SilentlyContinue
Write-CMTracelog "Check if task exists: ${taskName}" -Component "get-scheduledtask"
if($listTasks){
    Write-CMTracelog "Task exists: ${taskName}" -Component "get-scheduledtask"
     try{   
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        $taskIsDeleted = $true
        Write-CMTracelog "Task deleted: ${taskName}" -Component "Unregister-ScheduledTask"
     }catch {
        Write-CMTracelog "Error deleting task: ${taskName}" -Type Warning -Component "Unregister-ScheduledTask"
        Write-CMTracelog "Error: $($_.Exception.Message)" -Type Error -Component "Unregister-ScheduledTask"
        Write-CMTracelog "Error: $($_.ScriptStackTrace)" -Type Error -Component "Unregister-ScheduledTask"
        Write-CMTracelog "Error: $($_CategoryInfo.ToString())" -Type Error -Component "Unregister-ScheduledTask"
     }
}else{
    Write-CMTracelog "Task does not exist: ${taskName}" -Component "get-scheduledtask"
}

# Check if file exists
if($taskIsDeleted){
    Write-CMTracelog "Chek if file exists: $($env:windir)\Temp\Inetum\InventoryDevice.ps1" -Type Information
    If(Test-Path "$($env:windir)\Temp\Inetum\InventoryDevice.ps1"){
        Write-CMTracelog "File exists: $($env:windir)\Temp\Inetum\InventoryDevice.ps1" -Type Information -Component "Test-Path"
        try {
            Remove-Item -Path "$($env:windir)\Temp\Inetum\InventoryDevice.ps1" -Force
            Write-CMTracelog "File deleted: $($env:windir)\Temp\Inetum\InventoryDevice.ps1" -Type Information -Component "Remove-Item"
        }
        catch {
            Write-CMTracelog "Error deleting file: $($env:windir)\Temp\Inetum\InventoryDevice.ps1" -Type Warning -Component "Remove-Item"
            Write-CMTracelog "Error: $($_.Exception.Message)" -Type Error -Component "Unregister-ScheduledTask"
            Write-CMTracelog "Error: $($_.ScriptStackTrace)" -Type Error -Component "Unregister-ScheduledTask"
            Write-CMTracelog "Error: $($_CategoryInfo.ToString())" -Type Error -Component "Unregister-ScheduledTask"
        } 
    }
}
Write-CMTracelog  "End execution: ${scriptname}"
#endregion "Delete Task"
exit 0