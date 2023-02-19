<#
    .SYNOPSIS
        Bot para el mantenimiento desantedido de la aplicacion Siltra. 
    
    .DESCRIPTION
        El botservidor comprueba la version de Siltra en la web de la Seguridad Social y si detecta una versión distinta a la ultima que se bajo la descarga y la actualiza.
        En el dispositivo que se ejecute el botservidor se autoinstalara Siltra. Esto es necesario ya que el software no proporciona ningun tipo de informacion sobre versiones,
        por lo que el control de versiones se realiza mientras hash del archivo Siltra.jar .
        El bot cuenta con algunos controles para informar si la pagina web de Siltra no esta accesible o ha cambiado de formato.
        Informa por correo cuando hay una nueva versión o cuando ha tenido algun problema durante la ejecuccion.
        Todos los procesos realizados durante la ejecucion del botcliente quedan registrados en el archivo C:\windows\temp\nombredemaquina_siltraBot.log .El tamaño maximo para el archivo de log es de 100MB.  
  
    .VARIABLES CONFIGURACION
        En la seccion 'Variables Servidor' al inicio del script, se deben configurar las siguientes variables:
            - '$uriSiltra'. Url de la pagina desde donde se descarga Siltra.
            - '$PathCMTracelog'. Ruta donde se creara el archivo de log.
            - '$pathServerBot'. Ruta de la carpeta compartida donde estan los archivos necesarios para el funcioanmiento del cliente. Tienen que existir los siguientes archivos para el correcto funcionamiento del bot:
                * 'actu_guion.xml'. Archivo para la actualizacion desantedida de Siltra.
                * 'actuSILTRAxxx.jar'. Archivo para la actualizacion de Siltra. 'xxx' sera la version en el momento de hacer este desarrollo vamos por la version 3.1.3
                * 'currentversion.txt'. Archivo donde el botservidor deja el numero de la ultima version descargada. Lo consultara cada vez que haga un checkeo para comparar la ultima version descargada con la presente en la web.
                * 'guion.xml'. Archivo para la instalación desatendida de Siltra.
                * 'JavaSetup8u333.exe'. Archivo para la instalación de Java. Si se actualiza la version de Java ahi que actualizar la variable de configuración '$javaMachinePath'
                * 'SILTRA313.jar'. Archivo para la instalacion del cliente Siltra. 'xxx' sera la version en el momento de hacer este desarrollo vamos por la version 3.1.3
                * 'siltraversionServer.txt'. Archivo con el Hash del archivo Siltra.jar instalado en el servidor.
            - '$pathSiltraInstall'. Ruta del archivo Siltra.jar . Se usara para comprobar si Siltra esta instalado y sacar la version instalada.
            - '$javaMachinePath'. Ruta del archivo java.exe. Se utiliza tanto para lanzar la instalacion/actualizacion de Siltra, como para detectar si Java esta instalado.

    .VARIABLES DE CONTROL
        En la seccion 'Variables de control' se encuentran las siguientes variables:
            - '$ejecucion'. Indica si todos los pasos se han completado correctamente '$true' o alguno ha fallado '$false'. Con valor '$false' enviara un correo informando del error.
            - '$currentVersion'. Ruta donde se encuentra el archivo 'currentversion.txt' donde se almacena cual es la ultima version de Siltra descargada.
            - '$parserStatus = $null'. Indica si ha habido algun error al conectar a la web o al parsear los datos, bien porque no se tenga acceso a ella o porque hayan cambiado el formato de la web. Con valor $false envia un correo informando. 


    .VERSION
        1.0 - 17 de Junio del año 2022
    
    .NOTES
        Author:  Alejandro Aguado Garcia
        Website: https://www.linkedin.com/in/alejandro-aguado-garcia-Iber0/
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
    
    if(!$Path){$Path= $PathCMTracelog}            
        switch ($Type) {
            "Info" { [int]$Type = 1 }
            "Warning" { [int]$Type = 2 }
            "Error" { [int]$Type = 3 }
        }
    
    # Crea una entrada con formato CMTrace
    $Content = "<![LOG[$Message]LOG]!>" +`
        "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
        "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
        "component=`"$Component`" " +`
        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
        "type=`"$Type`" " +`
        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
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
    param($pathSiltraInstall,$pathServerBot)
    $siltraVersionClient = (Get-FileHash $pathSiltraInstall).hash
    if(Test-Path "$pathServerBot\siltraversionServer.txt"){
        $siltraVersionServer = Get-Content "$pathServerBot\siltraversionServer.txt" | Where-Object { $_.Trim() -ne '' }
    }
    else{
        Write-CMTracelog "No se pudo cargar la version de Siltra instalada en el servidor" -Type Error
        return $false
    }
    if ($siltraVersionServer -eq $siltraVersionClient){
        Write-CMTracelog "La version actual es la misma que la del servidor"
        return  $true
    }
    else{
        Write-CMTracelog "Error desconocido al comparar la version instalada con la del servidor"
        return $false}

}
function installJava{
    param ($pathServerBot,$javaMachinePath)
    Try{
        Write-CMTracelog "Iniciando la instalacion de Java"
        Start-Process $pathServerBot\JavaSetup8u333.exe -ArgumentList '/s' -Wait -NoNewWindow
        if(Test-Path $javaMachinePath ){
            Write-CMTracelog "Instalacion de Java completada"
            return $true
        }
    }catch{
        Write-CMTracelog "No se puedo instalar Java. Error: $($Error[-1])" -Type Error
        return $false
    }
}
function installSiltra {
    param ($javaMachinePath ,$installSiltra, $pathServerBot)
    Write-CMTracelog "Llamando al instalador de Siltra"
    if((Test-Path $javaMachinePath) -eq $false){
        Write-CMTracelog "No se encuentra la instalacion de Java"
        $temp = installJava $pathServerBot $javaMachinePath
        if($temp -eq $false){
            return $false
        }
    }
    if(Test-Path $javaMachinePath){   
        try {
            Write-CMTracelog 'Iniciando instalacion de Siltra'
            Start-Process $javaMachinePath -ArgumentList $installSiltra -Wait -WindowStyle hidden
            if(testSiltraInstall $pathSiltraInstall){
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
function siltraClient {
<#
    .SYNOPSIS
        Bot para el mantenimiento desantedido de la aplicacion Siltra.    
    
    .DESCRIPTION
        El botcliente mantiene actualizada la instalacion del cliente Siltra con la ultima version o bien la instala. Tambien instalara Java si el dispositivo no lo tiene instalado. 
        El botcliente necesita tener acceso a una carpeta compartida, donde el botServidor crea los archivos para la instalación o actualizacion y el archivo para el control de versiones.
        El control de versiones se realiza mediante el hash del archivo Siltra.jar. Si el hash es distinto en el archivo de versiones que el instalado en el cliente, este se actualizara a la version del servidor. 
        Todos los procesos realizados durante la ejecucion del botcliente quedan registrados en el archivo C:\windows\temp\nombredemaquina_siltraBot.log . El tamaño maximo para el archivo de log es de 100MB.

    .VARIABLES CONFIGURABLES
        En la seccion 'Variables Cliente' al inicio del script, se pueden configurar las siguientes variables:
            - '$PathCMTracelog'. Ruta donde se creara el archivo de log.
            - '$pathServerBot'. Ruta de la carpeta compartida donde estan los archivos necesarios para el funcioanmiento del cliente. Tienen que existir los siguientes archivos para el correcto funcionamiento del bot:
                * 'actu_guion.xml'. Archivo para la actualizacion desantedida de Siltra.
                * 'actuSILTRAxxx.jar'. Archivo para la actualizacion de Siltra. 'xxx' sera la version en el momento de hacer este desarrollo vamos por la version 3.1.3
                * 'currentversion.txt'. Archivo donde el botservidor deja el numero de la ultima version descargada. Lo consultara cada vez que haga un checkeo para comparar la ultima version descargada con la presente en la web.
                * 'guion.xml'. Archivo para la instalación desatendida de Siltra.
                * 'JavaSetup8u333.exe'. Archivo para la instalación de Java. Si se actualiza la version de Java ahi que actualizar la variable de configuración '$javaMachinePath'
                * 'SILTRA313.jar'. Archivo para la instalacion del cliente Siltra. 'xxx' sera la version en el momento de hacer este desarrollo vamos por la version 3.1.3
                * 'siltraversionServer.txt'. Archivo con el Hash del archivo Siltra.jar instalado en el servidor.
            - '$pathSiltraInstall'. Ruta del archivo Siltra.jar . Se usara para comprobar si Siltra esta instalado y sacar la version instalada.
            - '$javaMachinePath'. Ruta del archivo java.exe. Se utiliza tanto para lanzar la instalacion/actualizacion de Siltra, como para detectar si Java esta instalado.
    
    .FUNCIONES
        - 'Write-CMTracelog'. Genera las entradas del archivo log. Necesita de la variable '$PathCMTracelog' para funcionar correctamente.
        - 'testSiltraInstall'. Comprueba que Siltra esta instalado.
        - 'checkSiltraVersion'. Comprueba que la version de Siltra en el cliente, es la misma que en el servidor. 
        - 'installJava'. Instala Java.
        - 'installSiltra' Instala Siltra. 

    .VERSION
        1.0

    .NOTES
        Author:  Alejandro Aguado Garcia
        Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
        Twitter: @Alejand94399487
#>

    #Variables Cliente
    $PathCMTracelog= "C:\windows\temp\$(hostname)_siltraBot.log"
    $pathServerBot = '\\192.168.26.1\SiltraBot'
    $pathSiltraInstall = 'C:\SILTRA\SILTRA.jar'
    $javaMachinePath = "c:\Program Files (x86)\Java\jre1.8.0_333\bin\java.exe"
    
    #Reiniciando archivo log si sobrepasa los 100mb de tamaño 
    if(Test-Path $PathCMTracelog){
        $logSize = Get-Item $PathCMTracelog
        if ((($logSize.Length)/1MB) -ge 100){
            Remove-Item $PathCMTracelog
        }
    }
    Write-CMTracelog "Iniciando Bot en cliente"

     
    $listJarFiles = Get-ChildItem "$pathServerBot\*.jar"
    $actuSiltra = "-jar "+(($listJarFiles | Where-Object -FilterScript{$_.Name -match 'actu'}).FullName)+" "+"$pathServerBot\actu_guion.xml"
    $installSiltra = "-jar "+(($listJarFiles | Where-Object -FilterScript{$_.Name -notmatch 'actu'}).FullName)+" "+"$pathServerBot\guion.xml"
    
    #Comprobando si Siltra esta instalado para instalarlo o actualizarlo a la nueva version
    if((testSiltraInstall $pathSiltraInstall) -eq $false){
        $tempinstall = installSiltra $javaMachinePath $installSiltra $pathServerBot
        if($tempinstall -eq $true){
            Write-CMTracelog "Finalizando Bot en cliente" -Path $PathCMTracelog # no hace falta poner la variable $pathCMTracelog es solo para que el Visual Code no me el error de que esta declarada pero sin uso. 
            return $true
        }
        else{
            Write-CMTracelog "Finalizando Bot en cliente"
            return $false
        }
    }
    elseif((testSiltraInstall $pathSiltraInstall) -eq $true){
        if((checkSiltraVersion $pathSiltraInstall $pathServerBot)){
            Write-CMTracelog "Version correcta no hacer nada"
            Write-CMTracelog "Finalizando Bot en cliente"
            return $true
            }
        elseif((checkSiltraVersion $pathSiltraInstall $pathServerBot) -eq $false){
            try{
                Write-CMTracelog "Iniciando actualizacion de Siltra"       
                Start-Process $javaMachinePath -ArgumentList $actuSiltra -Wait -WindowStyle hidden
                Write-CMTracelog "Verificando que la actualizacion es correcta"
                if((checkSiltraVersion $pathSiltraInstall $pathServerBot)){
                    Write-CMTracelog "Siltra Actualizado"
                    Write-CMTracelog "Finalizando Bot en cliente"
                    return $true
                }
                else{
                    Write-CMTracelog "No se pudo completar la actualizacion de Siltra" -Type Error
                    Write-CMTracelog "Finalizando Bot en cliente"
                    return $false
                }
            }
            catch{
                Write-CMTracelog "No se pudo completar la actualizacion de Siltra. Error: $($Error[-1])" -Type Error
                Write-CMTracelog "Finalizando Bot en cliente"
                return $false
            }
        } 
    }

    Write-CMTracelog 'Bot en el cliente finalizado'
}
    
# Variables Servidor
$uriSiltra = 'https://www.seg-social.es/wps/portal/wss/internet/InformacionUtil/5300/2837/2839/3098/200589'
$PathCMTracelog= "C:\windows\temp\$(hostname)_siltraBot.log"
$pathServerBot = '\\192.168.26.1\SiltraBot'
$pathSiltraInstall = 'C:\SILTRA\SILTRA.jar'
$javaMachinePath = "c:\Program Files (x86)\Java\jre1.8.0_333\bin\java.exe" 

#Variables proxy
$pass = ConvertTo-SecureString "tupassword" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList "contos\username", $pass
$proxy = ([System.Net.WebRequest]::GetSystemWebproxy()).GetProxy($uriSiltra)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $uriSiltra -UseBasicParsing -Proxy $proxy -ProxyCredential $cred

# Variables de control
$parserStatus = $null
$ejecucion = $true
$nuevaVersion = $null

#Reiniciando archivo log si sobrepasa los 100mb de tamaño 
if(Test-Path $PathCMTracelog){
    $logSize = Get-Item $PathCMTracelog
    if ((($logSize.Length)/1MB) -ge 100){
        Remove-Item $PathCMTracelog
    }
}
Write-CMTracelog "Iniciando Bot en cliente"

#Cargando la Pagina de Siltra
try {
    Write-CMTracelog "Cargando pagina web de Siltra"
    $siltraVersion = Invoke-WebRequest -Uri $uriSiltra -UseBasicParsing
    $lastversion = $siltraVersion.Links | Where-Object -FilterScript {$_.outerHTML -match 'actualización.jar'}
}
catch {
    $parserStatus = $falsea
    Write-CMTracelog "Error al solicitar la pagina de siltra: $($Error[-1])" -Type error
}

#Comprobando que el parseo es valido
if (($lastversion.outerHTML.split('>')[1].split('actualización')[0]) -notmatch 'SILTRA'){
    $parserStatus = $false
    Write-CMTracelog "Fallo al parsear la Web de Siltra" -Type Error
}
elseif ($siltraVersion.StatusCode -ne '200') {
    $parserStatus = $false
    Write-CMTracelog "Error: $($siltraVersion.StatusCode) al solicitar la web de Siltra" -Type Error
}
else{

#Comprobando si hay versiones nuevas en la Web
$currentVersion = Get-Content "$pathServerBot\currentversion.txt" -ErrorAction SilentlyContinue
    if($currentVersion -ne ($lastversion.outerHTML.split('>')[1].split('actualización')[0])){
        Write-CMTracelog "Version nueva encontrada"
        Write-CMTracelog "Preparando version: $($lastversion.outerHTML.split('>')[1].split('actualización')[0])"
        Write-CMTracelog "Eliminando .jar version vieja"
        try {
            Get-ChildItem "$pathServerBot\*.jar" | Remove-Item -Force
            Write-CMTracelog "Archivos eliminados con exito"
        }
        catch {
            Write-CMTracelog "Error al eliminar los archivos antiguos. Error: $($Error[-1]). La descarga se detendra" -Type Error
            $ejecucion = $false
        }

        #Iniciando la descarga de la nueva version
        Write-CMTracelog "Iniciando descarga de archivos"
        $siltraActualizacion = $lastversion.href
        $siltraFullversion = $siltraVersion.Links | Where-Object -FilterScript {$_.outerHTML -match $($lastversion.outerHTML.split('>')[1].split('actualización')[0]).Trim()+'.jar'}

        # Descargando version de actualizacion
        Invoke-WebRequest -Uri $siltraActualizacion -OutFile "$pathServerBot\$($siltraActualizacion.split('/')[-1])" -InformationAction SilentlyContinue
        if(Test-Path "$pathServerBot\$($siltraActualizacion.split('/')[-1])"){
            Write-CMTracelog "$($siltraActualizacion.split('/')[-1]) descargado con exito"
        }
        else{
            Write-CMTracelog "$($siltraActualizacion.split('/')[-1]) fallo durante la descarga" -Type Error
            $ejecucion = $false
        }
        
        #Descargando version completa
        Invoke-WebRequest -Uri $siltraFullversion.href -OutFile "$pathServerBot\$($siltraFullversion.href.split('/')[-1])" -InformationAction SilentlyContinue
        if(Test-Path "$pathServerBot\$($siltraFullversion.href.split('/')[-1])"){
            Write-CMTracelog "$($siltraFullversion.href.split('/')[-1]) descargado con exito"
            
        }
        else{
            Write-CMTracelog "$($siltraFullversion.href.split('/')[-1]) fallo durante la descarga" -Type Error
            $ejecucion = $false
        }

        #Comprobamos que los archivos se han descargado y actualizamos la version instalada en el servidor
        if((Test-Path "$pathServerBot\$($siltraActualizacion.split('/')[-1])") -and (Test-Path "$pathServerBot\$($siltraFullversion.href.split('/')[-1])")){

            #actualizamos el numero de version para la siguiente descarga
            $nuevaVersion = $($lastversion.outerHTML.split('>')[1].split('actualización')[0])
            $nuevaVersion | Out-File $pathServerBot\currentversion.txt -Force

            #Lanzamos la instalación del cliente. Es necesaria en el servidor para poder obtener el atributo LastWriteTime de Siltra.jar. Es con lo que evaluamos que version de siltra tiene instalada el cliente.
            #Si ya tiene cliente instalado lo actualiza con la nueva version, sino tiene cliente lo instala
            Write-CMTracelog "Actualizando Siltra"
            $insActSiltra = siltraClient
            if($insActSiltra -eq $false){
                Write-CMTracelog 'Fallo al instalar/actualizar Siltra a la nueva version' -Type Error
            }
            #Actualizamos el fichero con la nueva version para la detección en los clientes
            Write-CMTracelog "La actualizacion de Siltra se completo con exito"
            try {
                $siltraVersionServer = (Get-FileHash $pathSiltraInstall).hash
                $siltraVersionServer | Out-File "$pathServerBot\siltraversionServer.txt" -Force
                Write-CMTracelog "File Hash para la nueva version actualizado en el fichero"
            }
            catch {
                Write-CMTracelog "Error al actualizar el File Hash para la nueva version. Error: $($Error[-1])." -Type Error
                $ejecucion = $false
            }
            
        }
    }

    #Comprobamos si la version Web es la misma
    if($currentVersion -eq ($lastversion.outerHTML.split('>')[1].split('actualización')[0])){
        Write-CMTracelog "No hay ninguna version nueva"
    }
}
#Mandamos un correo si hay una nueva version o si algo ha salido mal 
$SMTP = "smtp.gmail.com"
$From = "enviocorreo770@gmail.com"
$To = "alejandro.aguado@gmail.com"
$Subject = "Novedades en el bot de Siltra"
$Email = New-Object Net.Mail.SmtpClient($SMTP, 587)
$Email.EnableSsl = $true
$Email.Credentials = New-Object System.Net.NetworkCredential("enviocorreo770@gmail.com", "kqxxicsmevvbmjxn");
if($parserStatus -eq $false){
    $Body = "La pagina Web de Siltra ha sido modificada o no hay acceso posible codigo de error al solicitar la web: $($siltraVersion.StatusCode). Revise el log en $PathCMTracelog para mas detalles"
    try {
        $Email.Send($From, $To, $Subject, $Body)
        Write-CMTracelog 'Correo electronico enviado'
    }
    catch {
        Write-CMTracelog "Fallo al enviar el correo electronico. Error: $($Error[-1])" -Type Error
    }
}
elseif (($nuevaVersion) -and ($ejecucion -eq $true) -and ($insActSiltra -eq $true)){  
    $Body = "Hay una version nueva de siltra: $nuevaversion. El servidor se actualizo correctamente y empezara a servir la nueva version a los clientes"
    try {
        $Email.Send($From, $To, $Subject, $Body)
        Write-CMTracelog 'Correo electronico enviado'
    }
    catch {
        Write-CMTracelog "Fallo al enviar el correo electronico. Error: $($Error[-1])" -Type Error
    }
}
elseif (($nuevaVersion) -and ($ejecucion -eq $true) -and ($insActSiltra -eq $false)) {
    $Body = "Hay una version nueva de siltra: $nuevaversion. El servidor la descargo correctamente pero no pudo instalarla y no estara disponibles para los clientes. Por favor revise el log del bot en $PathCMTracelog"
    try {
        $Email.Send($From, $To, $Subject, $Body)
        Write-CMTracelog 'Correo electronico enviado'
    }
    catch {
        Write-CMTracelog "Fallo al enviar el correo electronico. Error: $($Error[-1])" -Type Error
    }
}   
elseif (($nuevaVersion) -and ($ejecucion -eq $false)){
    $Body = "Hay una version nueva de siltra: $nuevaversion. Hubo problemas durante la descarga y no estara disponible para los clientes. Por favor revise el log del bot en $PathCMTracelog"
    try {
        $Email.Send($From, $To, $Subject, $Body)
        Write-CMTracelog 'Correo electronico enviado'
    }
    catch {
        Write-CMTracelog "Fallo al enviar el correo electronico. Error: $($Error[-1])" -Type Error
    }
} 
Write-CMTracelog 'FIN del SCRIPT'




