

<#
.SYNOPSIS
    Processes the ContentTransferManager log to make it more readable.

.DESCRIPTION
    Retrieve all downloads made and present them in a readable format in a CSV file. The object properties are:

    - Source: The computer from which the download was made.
    - Type: The method by which the download was made, whether from a Windows Update DP or some type of peer.
    - Date: The date the download was made.
    - Status: Indicates whether the download was successful or failed.
    - CTMJob ID: The identifier of the CTM job, which allows us to search for the job in the log.
    - URL: The complete URL of the download. In downloads with an internet source, it allows us to identify whether the download is a delta or a full package.
    
.PARAMETER Origen
    The path where the file to be processed is located.

.PARAMETER Destino
    The path where the CSV file generated with the data is desired.

.EXAMPLE
     Transforma-ContentTransferManager -Origen C:\temp\archivos\ContentTransferManager.log -Destino C:\temp\miarchivo.csv

.NOTES
    Author:   Alejandro Aguado Garcia
    Linkedin: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Github:   https://github.com/Iber1to
    Twitter:  @Alejand94399487
#> 



    param(
        [parameter(Mandatory=$true)]
          [String]$Origen,

          [parameter(Mandatory=$true)]
          [String]$Destino

          
    )

#Comprobando archivo de origen
$TestOrigen= Test-Path -Path $Origen
if($TestOrigen -eq $false){throw 'La ruta de origen no existe'}


$Study= Get-Content $Origen |Select-String "started download from"
$DatosProcesados= @()
foreach($item in $Study){
    
    #Proceso los datos
    $Origenes= $item.ToString().Split("'")[1]
    $DTSJob= $item.ToString().split('{')[1].split('}')[0]
    $DTSJobCompletado= Get-Content $Origen |Select-String "CTM job {$($DTSJob)} successfully processed download completion."
    If($DTSJobCompletado){$DTSJobEstado= 'Descarga Completada'}else{$DTSJobEstado= 'Fallo en la descarga'}
        

    $TipoDescarga=$Origenes.Split('/')[3]
    switch ($TipoDescarga.Length){
        1  { $TipoDescarga ='Internet'}
        2  { $TipoDescarga ='Internet'}
        14 { $TipoDescarga ='Distribution Point'}
        17 { $TipoDescarga ='Branch Cache'}
        23 { $TipoDescarga ='Azure'}
    }
    $Device= $Origenes.Split('/')[2].split('.')[0]
    if($Device -eq 'download'){$Device= 'WindowsUpdate'}
    if($Device -eq 'officecdn'){$Device= 'OfficeUpdate'}
    $fechas= [Datetime]::ParseExact(($item[$item.Count -1].ToString() -split 'date="')[1].split('"')[0], 'MM-dd-yyyy', $null)

    #Creo el objeto con los datos procesados
    $ObjectTemp= New-Object System.Object
    $ObjectTemp | Add-Member -type NoteProperty -name 'Origen' -value $Device
    $ObjectTemp | Add-Member -type NoteProperty -name 'Tipo' -value $TipoDescarga
    $ObjectTemp | Add-Member -type NoteProperty -name 'Fecha' -value $fechas.ToShortDateString()
    $ObjectTemp | Add-Member -type NoteProperty -name 'Estado' -value $DTSJobEstado
    $ObjectTemp | Add-Member -type NoteProperty -name 'ID CTMJob' -value $DTSJob
    $ObjectTemp | Add-Member -type NoteProperty -name 'URL' -value $Origenes
    $DatosProcesados+=$ObjectTemp
    }

    $DatosProcesados |Export-Csv $Destino -Append -NoTypeInformation

    

    



    