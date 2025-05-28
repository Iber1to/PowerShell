#Region Declare functions
function Write-SimpleLog([string]$Message, [ValidateSet("INFO", "WARNING", "ERROR")] [string]$LogLevel = "INFO") {
    # Generate log file name using script name and current date
    $ScriptName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
    $appName = $installTitle
    $LogFileName = $appName+"_"+$ScriptName+"_"+$(Get-Date -Format 'yyyyMMdd')+".log"
    # Verifica si el usuario tiene privilegios de administrador
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $LogPath = "C:\Users\$env:USERNAME\Documents\Logs\$LogFileName"
    } else {
        $LogPath = "C:\Windows\Logs\Software\$LogFileName"
    }
    # Ensure the log directory exists
    $LogDir = [System.IO.Path]::GetDirectoryName($LogPath)
    if (-not (Test-Path -Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    # Format log message
    $CurrentTime = Get-Date -Format "HH:mm:ss.fff"
    $CurrentDate = Get-Date -Format "yyyy/MM/dd"
    $LogEntry = "[$LogLevel][$CurrentTime][$CurrentDate] $Message"

    # Append log message to log file
    Add-Content $LogPath -Value $LogEntry
}
#endRegion

# Setting this variables
$installTitle = "" # Not cant contains spaces, otherwise it will not work correctly (log problems)
$ProcessName = ""

# Statics variables
$dirFiles = ".\Files"
$MSIFile = "*.msi"
$LogDirMSI = "C:\Users\$env:USERNAME\Documents\Logs\MSILogs\"
$MSILogFullName = Join-Path -Path $LogDirMSI -ChildPath "$($installTitle)_uninstall.log"
$MSIPath = Get-ChildItem -Path "$dirFiles" -Include $MSIFile -File -Recurse -ErrorAction SilentlyContinue
$Argumenlist = "/x `"$($MSIPath.FullName)`" /qn /norestart /L*V `"$msilogFullName`""


#Region Environment variables

[string]$envComputerName = [Environment]::MachineName.ToUpper()
[string]$envComputerNameFQDN = $envComputerName
[psobject]$envHost = $Host

# Get the operating system type
[psobject]$envOS = Get-WmiObject -Class 'Win32_OperatingSystem' -ErrorAction 'SilentlyContinue'
[string]$envOSName = $envOS.Caption.Trim()
[string]$envOSServicePack = $envOS.CSDVersion
[version]$envOSVersion = $envOS.Version
[int32]$envOSProductType = $envOS.ProductType
Switch ($envOSProductType) {
	3 { [string]$envOSProductTypeName = 'Server' }
	2 { [string]$envOSProductTypeName = 'Domain Controller' }
	1 { [string]$envOSProductTypeName = 'Workstation' }
	Default { [string]$envOSProductTypeName = 'Unknown' }
}

# Get the current user account
[Security.Principal.WindowsIdentity]$CurrentProcessToken = [Security.Principal.WindowsIdentity]::GetCurrent()
[string]$ProcessNTAccount = $CurrentProcessToken.Name

## Variables:  Culture
[Globalization.CultureInfo]$culture = Get-Culture
[string]$currentLanguage = $culture.TwoLetterISOLanguageName.ToUpper()
[Globalization.CultureInfo]$uiculture = Get-UICulture
[string]$currentUILanguage = $uiculture.TwoLetterISOLanguageName.ToUpper()

# Get type of Hardware platform
Try {
			Write-SimpleLog -Message 'Retrieve hardware platform information.' 
			$hwBios = Get-WmiObject -Class 'Win32_BIOS' -ErrorAction 'Stop' | Select-Object -Property 'Version', 'SerialNumber'
			$hwMakeModel = Get-WMIObject -Class 'Win32_ComputerSystem' -ErrorAction 'Stop' | Select-Object -Property 'Model', 'Manufacturer'

			If ($hwBIOS.Version -match 'VRTUAL') { $hwType = 'Virtual:Hyper-V' }
			ElseIf ($hwBIOS.Version -match 'A M I') { $hwType = 'Virtual:Virtual PC' }
			ElseIf ($hwBIOS.Version -like '*Xen*') { $hwType = 'Virtual:Xen' }
			ElseIf ($hwBIOS.SerialNumber -like '*VMware*') { $hwType = 'Virtual:VMWare' }
			ElseIf (($hwMakeModel.Manufacturer -like '*Microsoft*') -and ($hwMakeModel.Model -notlike '*Surface*')) { $hwType = 'Virtual:Hyper-V' }
			ElseIf ($hwMakeModel.Manufacturer -like '*VMWare*') { $hwType = 'Virtual:VMWare' }
			ElseIf ($hwMakeModel.Model -like '*Virtual*') { $hwType = 'Virtual' }
			Else { $hwType = 'Physical' }
		}
Catch {
			Write-SimpleLog -Message "Failed to retrieve hardware platform information. $($_.Exception.Message) " -LogLevel "ERROR"
			If (-not $ContinueOnError) {
				Throw "Failed to retrieve hardware platform information: $($_.Exception.Message)"
			}
		}

#  PowerShell Version and Architecture
[hashtable]$envPSVersionTable = $PSVersionTable

[version]$envPSVersion = $envPSVersionTable.PSVersion
[string]$envPSVersion = $envPSVersion.ToString()
[boolean]$Is64BitProcess = [boolean]([IntPtr]::Size -eq 8)
If ($Is64BitProcess) { [string]$psArchitecture = 'x64' } Else { [string]$psArchitecture = 'x86' }

#  CLR (.NET) Version used by PowerShell
[version]$envCLRVersion = $envPSVersionTable.CLRVersion
[string]$envCLRVersion = $envCLRVersion.ToString()
#endRegion

#Region Body script
# Iniciando instalación
# Información del entorno
Write-SimpleLog -Message "--------------------------------------------------------------------------------------------------------------------------------------------------"
Write-SimpleLog -Message "Computer Name is [$envComputerNameFQDN]" 
Write-SimpleLog -Message "Current User is [$ProcessNTAccount]" 
Write-SimpleLog -Message "OS Version is [$envOSName $envOSServicePack $envOSArchitecture $envOSVersion]"
Write-SimpleLog -Message "OS Type is [$envOSProductTypeName]" 
Write-SimpleLog -Message "Current Culture is [$($culture.Name)], language is [$currentLanguage] and UI language is [$currentUILanguage]" 
Write-SimpleLog -Message "Hardware Platform is [$($hwType)]" 
Write-SimpleLog -Message "PowerShell Host is [$($envHost.Name)] with version [$($envHost.Version)]" 
Write-SimpleLog -Message "PowerShell Version is [$envPSVersion $psArchitecture]" 
Write-SimpleLog -Message "PowerShell CLR (.NET) version is [$envCLRVersion]"
Write-SimpleLog -Message "--------------------------------------------------------------------------------------------------------------------------------------------------"

# Test if folder exists, if not create it
if (-not (Test-Path -Path $LogDirMSI)) {
        New-Item -ItemType Directory -Path $LogDirMSI -Force | Out-Null
    }

# Ininciando desinstalación
Write-SimpleLog -Message "Starting uninstallation of [$($installTitle)]."

# Cerrando procesos si estan abiertos
$processes = Get-Process -Name "*$($ProcessName)*" -ErrorAction SilentlyContinue
if ($processes) {
    foreach ($process in $processes) {
        Write-SimpleLog -Message "Killing process: [$($process.Name)]."
        $process | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}

If($MSIPath.Exists)
    {
    Write-SimpleLog -Message "[$($installTitle)] MSI found: [$($MSIPath.FullName)]."
    try {
        Write-SimpleLog -Message "Found [$($MSIPath.FullName)], now attempting to uninstall [$($installTitle)]. With arguments: [$($Argumenlist)]"
        Write-SimpleLog -Message "You can check the installation MSI log in [$($LogDirMSI)]."
        Write-SimpleLog "Uninstalling [$($installTitle)]. This may take some time. Please wait..."
        Start-Process -FilePath msiexec.exe -ArgumentList $Argumenlist -Wait -NoNewWindow
        Write-SimpleLog -Message "[$($installTitle)] Uninstalled successfully."
        }
    catch {
            Write-SimpleLog -Message "Error installing [$($installTitle)]: $($_.Exception.Message)" -LogLevel "ERROR"
         }
        
    }
else {
    Write-SimpleLog -Message "[$($installTitle)] MSI not found in [$($dirFiles)]." -LogLevel "ERROR"
    exit 1
}

#endRegion