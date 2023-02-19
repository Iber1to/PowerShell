# siltraBotClient

    .SYNOPSIS
        Bot para el mantenimiento desantedido de la aplicacion Siltra.    
    
    .DESCRIPTION
        El botcliente mantiene actualizada la instalacion del cliente Siltra con la ultima version o bien la instala. Tambien instalara Java si el dispositivo no lo tiene instalado. 
        El botcliente necesita tener acceso a una carpeta compartida, donde el botServidor crea los archivos para la instalación o actualizacion y el archivo para el control de versiones.
        El control de versiones se realiza mediante el hash del archivo Siltra.jar. Si el hash es distinto en el archivo de versiones que el instalado en el cliente, este se actualizara a la version del servidor. 
        Todos los procesos realizados durante la ejecucion del botcliente quedan registrados en el archivo C:\windows\temp\nombredemaquina_siltraBot.log . El tamaño maximo para el archivo de log es de 100MB.

    .VARIABLES CONFIGURABLES
        En la seccion 'Variables Cliente' al inicio del script, se deben configurar las siguientes variables:
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
    
    .ISSUES
        Estos son los errores más comunes detectados. Los listo de más frecuente a menos. 
            - Fallo de conectividad. El equipo cliente no tiene acceso al recurso compartido.
            - Fallo en la instalacion o actualización de Siltra. Esto ocurre porque hay una versión de Java instalada distinta a la declarada en '$javaMachinePath'.
            

    .VERSION
        1.0 - 17 de Junio del año 2022

# siltraBotServer

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