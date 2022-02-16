#Funciónes para el log
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )
$LogName= hostname
$outFilePathlog= '\\ESDC1SVPWO033.emea.prosegur.local\client\ESU\logs'
$outFilelog ="$outFilePathlog\$Logname.log"
$Time= (Get-Date -f g)
$Tab= [char]9
$line="$Time $Tab $Message $Tab $Severity"        
Add-Content -Value $line -Path $outFilelog
 }

#Variables para la lista de dispositivos
$ListDeviceError= 'ListFailedDevices.log'
$ListDeviceComplete= 'ListCompletedDevices.log'
$DeviceName= hostname
$outFilePathlist= '\\ESDC1SVPWO033.emea.prosegur.local\client\ESU'
$Time= (Get-Date -f g)
$Tab= [char]9

Write-Log -Message "*** Iniciando Ejecucion del Script ***" -Severity Warning

#Compruebo si ya se ejecuto el Script con exito anteriormente
$TestLastRun= Test-Path 'HKLM:\SOFTWARE\ESUActivacionYear2\'
If($TestLastRun){
    Write-Log -Message "$DeviceName Ya ejecuto el script anteriormente"
    Write-Log -Message "*** Script Finalizado ***" -Severity Warning
    EXIT}

#Chequeo de las actualizaciones
$SHA2KB = "Non-Compliant"
$SSUSHA2KB = "Non-Compliant"
$MCUKB = "Non-Compliant"
$MSSUsKB = "Non-Compliant"
$ListMCUKB = 'KB4519976','KB4525235','KB4530692','KB4534314','KB4525235','KB4530692','KB4534314'
$ListMSSUsKB ='KB4516655','KB4523206','KB4531786','KB4536952','KB4537829','KB4550735','KB4550738','KB4555449','KB4562030','KB4565354','KB4570673','KB4580970','KB4592510'

#SHA-2 Update
If (Get-HotFix -id kb4474419){
    $SHA2KB = "Compliant"
    Write-Log -Message "SHA-2 Update $SHA2KB"
    }
Else{
    Write-Log -Message "SHA-2 Update $SHA2KB" -Severity Error
    Add-Content -Value "$time $Tab $DeviceName no tiene instalado SHA-2 Update kb4474419 $Tab Error " -Path $outFilePathlist\$ListDeviceError
    Exit
    }

#SSU (MAR 2019)
If (Get-HotFix -id KB4490628){
    $SSUSHA2KB = "Compliant"
    Write-Log -Message "SSU (MAR 2019) $SSUSHA2KB"
    }
Else{
    Write-Log -Message "SSU (MAR 2019) $SSUSHA2KB" -Severity Error
    Add-Content -Value "$time $Tab $DeviceName no tiene instalado SSU (MAR 2019) KB4490628 $Tab Error " -Path $outFilePathlist\$ListDeviceError
    Exit
    }

#Multiple Cumulative Updates
If (get-hotfix -id $ListMCUKB){
    $MCUKB = "Compliant"
    Write-Log -Message "Multiple Cumulative Updates $MCUKB"
    }
Else{
    Write-Log -Message "Multiple Cumulative Updates $MCUKB" -Severity Error
    Add-Content -Value "$time $Tab $DeviceName no tiene instalado ninguno de los kb's para Multiple Cumulative Updates $Tab Error " -Path $outFilePathlist\$ListDeviceError
    Exit
    }

#Multiple SSus
If (get-hotfix -id $ListMSSUsKB){
    $MSSUsKB = "Compliant"
    Write-Log -Message "Multiple SSus $MSSUsKB"
    }
Else{
    Write-Log -Message "Multiple SSus $MSSUsKB" -Severity Error
    Add-Content -Value "$time $Tab $DeviceName no tiene instalado ninguno de los kb's para Multiple SSus $Tab Error " -Path $outFilePathlist\$ListDeviceError
    Exit
    }

Write-Log -Message "$DeviceName cumple los requisitos de parcheo"

#Instalación de la licencia ESU
Write-Log -Message "Iniciando instacion de la licencia ESU"

$ProductKey= 'QXY6F-8TQJY-83VYV-26VV9-HHBTV'
try {
		# Compruebo si la clave del producto ya esta instalada y activada.
		$partialProductKey = $ProductKey.Substring($ProductKey.Length - 5)
		$licensingProduct = Get-WmiObject -Query ('SELECT LicenseStatus FROM SoftwareLicensingProduct where PartialProductKey = "{0}"' -f $partialProductKey)
		
		if ($licensingProduct.LicenseStatus -eq 1) {
			Write-Log "ESU Year 2 ya esta activado"
            Add-Content -Value "$time $Tab $DeviceName tiene ESU Year 2 activado $Tab Information " -Path $outFilePathlist\$ListDeviceComplete
            New-Item -Path 'HKLM:\SOFTWARE\' -Name 'ESUActivacionYear2' -Force
			Exit
		}
	
		# Instalo la clave de producto.
		Write-Log "Instalando clave de producto terminada en $partialProductKey ..."
		$licensingService = Get-WmiObject -Query 'SELECT VERSION FROM SoftwareLicensingService'
        $Msg1= "La version de licencia actual es "+$licensingService.Version
        Write-Log $Msg1
		$licensingService.InstallProductKey($ProductKey) | Out-Null
		$licensingService.RefreshLicenseStatus() | Out-Null
        Write-Log -Message "Clave de producto instalada con exito"

	} catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
		Write-Log "Fallo al instalar la clave de producto." -Severity Error
        Write-Log "El mensaje de error fue: $ErrorMessage"
        Write-Log "Asegurese de que el script se ejecuta con privilegios administrativos"
        Add-Content -Value "$time $Tab $DeviceName fallo al instalar la clave de producto $Tab Error " -Path $outFilePathlist\$ListDeviceError
		Exit 
	}

#Activacion de la clave
	try {
        # Cargo la información de licencia.
		Write-Log "Cargando Informacion de la licencia..."
		$licensingProduct = Get-WmiObject -Query ('SELECT ID, Name, OfflineInstallationId, ProductKeyID FROM SoftwareLicensingProduct where PartialProductKey = "{0}"' -f $partialProductKey)

		if(!$licensingProduct) {
			Write-Log "No hay informacion sobe la licencia con clave terminada en $partialProductKey ." -Severity Error
            Add-Content -Value "$time $Tab $DeviceName No tiene instalada la productkey ESU $Tab Error " -Path $outFilePathlist\$ListDeviceError
			Exit 
		}
		
		$licenseName = $licensingProduct.Name                       
		$InstallationId = $licensingProduct.OfflineInstallationId  
		$activationId = $licensingProduct.ID                       
		$ExtendedProductId = $licensingProduct.ProductKeyID        
	   
		Write-Log "Nombre             : $licenseName"
		Write-Log "Installation ID  : $InstallationId"
		Write-Log "Activation ID    : $activationId"
		Write-Log "Extd. Product ID : $ExtendedProductId"
		
	} catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
		Write-Log "Fallo al extraer la informacion sobre la licencia. $FailedItem" -Severity Error
        Write-Log "El mensaje de error fue $ErrorMessage"
        Add-Content -Value "$time $Tab $DeviceName Fallo al extraer la informacion sobre la licencia $Tab Error " -Path $outFilePathlist\$ListDeviceError
        Exit 
	}

	try {
		#Activando el producto
		Write-Log "Activando Producto..."
		$licensingProduct.Activate() | Out-Null
		$licensingService.RefreshLicenseStatus() | Out-Null
		
		# Comprobando si la activacion se realizo correctamente.
		$licensingProduct = Get-WmiObject -Query ('SELECT LicenseStatus, LicenseStatusReason FROM SoftwareLicensingProduct where PartialProductKey = "{0}"' -f $partialProductKey)
		
		if (!$licensingProduct.LicenseStatus -eq 1) {
			Write-Log "Activacion de producto fallida ($($licensingProduct.LicenseStatusReason))." -Severity Error
			Add-Content -Value "$time $Tab $DeviceName Fallo la activacion de la licencia ESU $Tab Error " -Path $outFilePathlist\$ListDeviceError
            Exit 
		}
		
		Write-Log "ESU Year2 se activo correctamente"
        Add-Content -Value "$time $Tab $DeviceName tiene ESU Year 2 activado $Tab Information " -Path $outFilePathlist\$ListDeviceComplete
        New-Item -Path 'HKLM:\SOFTWARE\' -Name 'ESUActivacionYear2' -Force
		
	} catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
		Write-Log "Fallo al activar el producto" -Severity Error
        Write-Log "El mensaje de error fue $ErrorMessage"
        Add-Content -Value "$time $Tab $DeviceName Fallo la activacion de la licencia ESU $Tab Error " -Path $outFilePathlist\$ListDeviceError
		Exit 
	}

Write-Log -Message "*** Script Finalizado ***" -Severity Warning