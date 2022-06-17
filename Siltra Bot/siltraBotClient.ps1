<#
    .SYNOPSIS
        Bot para el mantenimiento desantedido de la aplicacion Siltra.    
    
    .DESCRIPTION
        El botcliente mantiene actualizada la instalacion del cliente Siltra o bien lo instala, tambien instalara Java si no esta instalado si el dispositivo no lo tiene instalado previamente. 
        El botcliente necesita tener acceso a una carpeta compartida, donde el botServidor crea los archivos para la instalación/actualizacion y el archivo para el control de versiones del cliente.
        El control de versiones se realiza mediante el hash del archivo Siltra.jar. Si el hash es distinto en el archivo de versiones que el del cliente, este se actualizara a la version del servidor. 
        Todos los procesos realizados durante la ejecucion del botcliente quedan registrados en el archivo C:\windows\temp\nombredemaquina_siltraBot.log . El tamaño maximo para el archivo de log es de 100MB.

    .VARIABLES CONFIGURABLES
        En la seccion 'Variables Cliente' al inicio del script, se pueden configurar las siguientes variables:
            - '$PathCMTracelog' Ruta donde se creara el archivo de log.
            - '$pathServerBot' Ruta de la carpeta compartida donde estan los archivos necesarios para el funcioanmiento del cliente. Tienen que existir los siguientes archivos para el correcto funcionamiento del bot:
                * 'actu_guion.xml' Archivo para la instalación silen

    .VERSION
        1.0

    .NOTES
        Author:  Alejandro Aguado Garcia
        Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
        Twitter: @Alejand94399487
#> 

function Write-CMTracelog {

    <#
    .SYNOPSIS
        A�ade una entrada a un archivo log
    
    .DESCRIPTION
        A�ade entradas a un archivo log existente o crea uno nuevo
    
    .PARAMETER Path
        Ruta del archivo. Si se omite hay que configurar el parametro PathCMTracelog
    
    .PARAMETER PathCMTracelog
        Variable a declarar en el script que use la funci�n con la ruta del archivo log.
        Se usa para evitar estar pasando constantemente el parametro 'Path' 
    
    .PARAMETER Message
        Contenido a a�adir en la entrada.
    
    .PARAMETER Component
        Componente que a�ade la entrada al log. Por defecto a�ade la propia funci�n.
    
    .PARAMETER Type
        Tipo de mensaje a a�arir. El valor por defecto es 'Information' . Los otros valores son 
        'Warning' y 'Error'
    
    .EXAMPLE
         $PathCMTracelog= 'C:\Temp\logalternativo.log'
         Write-CMTracelog 'Esto es un mensaje de prueba por defecto'
         Output= Esto es un mensaje de prueba por defecto  Write-CMTracelog 31/08/2021 13:21:20 0 (0x0)
    
    .EXAMPLE
        Write-CMTracelog -Path C:\Temp\logalternativo.log -Message $error[0] -Type Error -Component $MyInvocation.MyCommand.Name
    
    
    .NOTES
        Author:  Alejandro Aguado Garcia
        Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
        Twitter: @Alejand94399487
    #> 
    
    
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Message,                
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Path,              
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Component = $MyInvocation.MyCommand.Name,    
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Information", "Warning", "Error")]
        [String]$Type = 'Information'
    )
    
    if (!$Path) { $Path = $PathCMTracelog }            
    switch ($Type) {
        "Info" { [int]$Type = 1 }
        "Warning" { [int]$Type = 2 }
        "Error" { [int]$Type = 3 }
    }
    
    # Crea una entrada con formato CMTrace
    $Content = "<![LOG[$Message]LOG]!>" + `
        "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " + `
        "date=`"$(Get-Date -Format "M-d-yyyy")`" " + `
        "component=`"$Component`" " + `
        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + `
        "type=`"$Type`" " + `
        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " + `
        "file=`"`">"
    
    # A�ade la linea al archivo log   
    Add-Content -Path $Path -Value $Content
}
function testSiltraInstall {
    param($pathSiltraInstall)
    $testExist = Test-Path $pathSiltraInstall
    return $testExist
}
function checkSiltraVersion {
    param($pathSiltraInstall, $pathServerBot)
    #Cargando version instalada en el cliente
    $siltraVersionClient = (Get-FileHash $pathSiltraInstall).hash
    if (Test-Path "$pathServerBot\siltraversionServer.txt") {
        $siltraVersionServer = Get-Content "$pathServerBot\siltraversionServer.txt" | Where-Object { $_.Trim() -ne '' }
    }
    else {
        Write-CMTracelog "No se pudo cargar la version de Siltra instalada en el servidor" -Type Error
        return $false
    }
    #Comparandola con la version del cliente
    if ($siltraVersionServer -eq $siltraVersionClient) {
        Write-CMTracelog "La version actual es la misma que la del servidor"
        return  $true
    }
    elseif ($siltraVersionServer -ne $siltraVersionClient) {
        Write-CMTracelog "La version del cliente no coincide con la del servidor"
        return $false
    }
    else {
        Write-CMTracelog "Error desconocido al comparar la version instalada con la del servidor"
        return $false
    }

}
function installJava {
    param ($pathServerBot, $javaMachinePath)
    Try {
        Write-CMTracelog "Iniciando la instalacion de Java"
        Start-Process $pathServerBot\JavaSetup8u333.exe -ArgumentList '/s' -Wait -NoNewWindow
        if (Test-Path $javaMachinePath ) {
            Write-CMTracelog "Instalacion de Java completada"
            return $true
        }
    }
    catch {
        Write-CMTracelog "No se puedo instalar Java. Error: $($Error[-1])" -Type Error
        return $false
    }
}
function installSiltra {
    param ($javaMachinePath , $installSiltra, $pathServerBot)
    Write-CMTracelog "Llamando al instalador de Siltra"
    if ((Test-Path $javaMachinePath) -eq $false) {
        Write-CMTracelog "No se encuentra la instalacion de Java"
        $temp = installJava $pathServerBot $javaMachinePath
        if ($temp -eq $false) {
            return $false
        }
    }
    if (Test-Path $javaMachinePath) {   
        try {
            Write-CMTracelog 'Iniciando instalacion de Siltra'
            Start-Process $javaMachinePath -ArgumentList $installSiltra -Wait -WindowStyle hidden
            if (testSiltraInstall $pathSiltraInstall) {
                Write-CMTracelog "Siltra Instalado"
                return $true
            }         
        }
        catch {
            Write-CMTracelog "Fallo al instalar Siltra. Error: $($Error[-1])" -Type Error
            return $false      
        }
    }
    
}
   
#Variables Cliente
$PathCMTracelog = "C:\windows\temp\$(hostname)_siltraBot.log"
$pathServerBot = '\\192.168.26.1\SiltraBot'
$pathSiltraInstall = 'C:\SILTRA\SILTRA.jar'
$javaMachinePath = "c:\Program Files (x86)\Java\jre1.8.0_333\bin\java.exe"

#Reiniciando archivo log si sobrepasa los 100mb de tamaño 
if (Test-Path $PathCMTracelog) {
    $logSize = Get-Item $PathCMTracelog
    if ((($logSize.Length) / 1MB) -ge 100) {
        Remove-Item $PathCMTracelog
    }
}

Write-CMTracelog "Iniciando Bot en cliente"

#Esto es solo para el entorno de pruebas
$UserName = 'alex'
$PlainPassword = '123456'
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword
New-PSDrive -Name SiltraServer -PSProvider FileSystem -Root $pathServerBot -Credential $Credentials | Out-null
# Fin de la parte para el entorno de pruebas
     
$listJarFiles = Get-ChildItem "$pathServerBot\*.jar"
$actuSiltra = "-jar " + (($listJarFiles | Where-Object -FilterScript { $_.Name -match 'actu' }).FullName) + " " + "$pathServerBot\actu_guion.xml"
$installSiltra = "-jar " + (($listJarFiles | Where-Object -FilterScript { $_.Name -notmatch 'actu' }).FullName) + " " + "$pathServerBot\guion.xml"
    
if ((testSiltraInstall $pathSiltraInstall) -eq $false) {
    $tempinstall = installSiltra $javaMachinePath $installSiltra $pathServerBot
    if ($tempinstall -eq $true) {
        Write-CMTracelog "Finalizando Bot en cliente" -Path $PathCMTracelog # no hace falta poner la variable $pathCMTracelog es solo para que el Visual Code no me el error de que esta declarada pero sin uso. 
        return $true
    }
    else {
        Write-CMTracelog "Finalizando Bot en cliente"
        return $false
    }
}
elseif ((testSiltraInstall $pathSiltraInstall) -eq $true) {
    if ((checkSiltraVersion $pathSiltraInstall $pathServerBot)) {
        Write-CMTracelog "Version correcta no hacer nada"
        Write-CMTracelog "Finalizando Bot en cliente"
        return $true
    }
    elseif ((checkSiltraVersion $pathSiltraInstall $pathServerBot) -eq $false) {
        try {
            Write-CMTracelog "Iniciando actualizacion de Siltra"       
            Start-Process $javaMachinePath -ArgumentList $actuSiltra -Wait -WindowStyle hidden
            Write-CMTracelog "Verificando que la actualizacion es correcta"
            if ((checkSiltraVersion $pathSiltraInstall $pathServerBot)) {
                Write-CMTracelog "Siltra Actualizado"
                Write-CMTracelog "Finalizando Bot en cliente"
                return $true
            }
            else {
                Write-CMTracelog "No se pudo completar la actualizacion de Siltra" -Type Error
                Write-CMTracelog "Finalizando Bot en cliente"
                return $false
            }
        }
        catch {
            Write-CMTracelog "No se pudo completar la actualizacion de Siltra. Error: $($Error[-1])" -Type Error
            Write-CMTracelog "Finalizando Bot en cliente"
            return $false
        }
    } 
}

Write-CMTracelog 'Bot en el cliente finalizado'