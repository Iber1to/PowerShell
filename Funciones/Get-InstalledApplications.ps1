# Recopilado en: https://xkln.net/blog/please-stop-using-win32product-to-find-installed-software-alternatives-inside/

function Get-InstalledApplications() {
    [cmdletbinding(DefaultParameterSetName = 'GlobalAndAllUsers')]

    Param (
        [Parameter(ParameterSetName="Global")]
        [switch]$Global,
        [Parameter(ParameterSetName="GlobalAndCurrentUser")]
        [switch]$GlobalAndCurrentUser,
        [Parameter(ParameterSetName="GlobalAndAllUsers")]
        [switch]$GlobalAndAllUsers,
        [Parameter(ParameterSetName="CurrentUser")]
        [switch]$CurrentUser,
        [Parameter(ParameterSetName="AllUsers")]
        [switch]$AllUsers
    )

    # Excplicitly set default param to True if used to allow conditionals to work
    if ($PSCmdlet.ParameterSetName -eq "GlobalAndAllUsers") {
        $GlobalAndAllUsers = $true
    }

    # Check if running with Administrative privileges if required
    if ($GlobalAndAllUsers -or $AllUsers) {
        $RunningAsAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($RunningAsAdmin -eq $false) {
            Write-Host "Finding all user applications requires administrative privileges"
            exit 1
        }
    }
    
    # Empty array to store applications
    $Apps = @()
    $32BitPath = "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $64BitPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

    # Retreive globally insatlled applications
    if ($Global -or $GlobalAndAllUsers -or $GlobalAndCurrentUser) {
        $Apps += Get-ItemProperty "HKLM:\$32BitPath"
        $Apps += Get-ItemProperty "HKLM:\$64BitPath"
    }

    if ($CurrentUser -or $GlobalAndCurrentUser) {
        $Apps += Get-ItemProperty "Registry::\HKEY_CURRENT_USER\$32BitPath"
        $Apps += Get-ItemProperty "Registry::\HKEY_CURRENT_USER\$64BitPath"
    }

    if ($AllUsers -or $GlobalAndAllUsers) {
        $AllProfiles = Get-CimInstance Win32_UserProfile | Select-Object LocalPath, SID, Loaded, Special | Where-Object {$_.SID -like "S-1-5-21-*"}
        $MountedProfiles = $AllProfiles | Where-Object {$_.Loaded -eq $true}
        $UnmountedProfiles = $AllProfiles | Where-Object {$_.Loaded -eq $false}
        $MountedProfiles | ForEach-Object {
            $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($_.SID)\$32BitPath"
            $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($_.SID)\$64BitPath"
        }
        $UnmountedProfiles | ForEach-Object {

            $Hive = "$($_.LocalPath)\NTUSER.DAT"
            if (Test-Path $Hive) {
            
                REG LOAD HKU\temp $Hive

                $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$32BitPath"
                $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$64BitPath"

                # Run manual GC to allow hive to be unmounted
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()
            
                REG UNLOAD HKU\temp

            } else {
            }
        }
    }

    Write-Output $Apps
}

 Get-Installedapplications | Where-Object {$_.DisplayName -like "*Amazon*"} | Select-Object DisplayName, Displayversion, uninstallstring, QuietUninstallString