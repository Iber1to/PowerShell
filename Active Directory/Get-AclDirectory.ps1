#Variables de configuracion
$listadoDirectorios = 'Ruta del CSV con el listado de directorios'
$profundidadBusqueda = '2' #Numero de subdirectorios desde el principal en los que va a profundizar
#$directorioBusqueda = 'C:\Temp' #Ruta del directorio sobre el que se quiere hacer la busqueda - Se suprime al pasar las rutas a traves de un CSV
$archivoExport = 'Pon aqui la ruta del archivo donde salvar los datos' #Path completo sin el nombre del archivo. Exp: 'C:\temp'
$pathnoacces = @()

#Cargando Listado de directorios
$loadListadoDirectorios = Import-csv -Path $listadoDirectorios
$listDirectoriosExplorados = @()

foreach ($currentItem in $loadListadoDirectorios) {

#Hay que comprobar si en el NAS al hacer el Get-Childitem modifica la propiedad 'LastAccessTime' . Con directorio Windows si lo hace y habria que cambiar la propiedad en el objeto por LastWriteTime o ignorarla
    $listAcl = Get-ChildItem -Path $currentItem.ruta -Recurse -Directory -Depth $profundidadBusqueda -ErrorVariable pathnoacces -erroraction Silentlycontinue
    $listData = @()
    foreach($item in $listAcl){
    try{
        if($item.PSIsContainer){
            $aclProperties = $item | Get-acl
            foreach($object in $aclProperties.access){
                $temp = New-Object -TypeName PSObject
                $temp | Add-Member -MemberType NoteProperty -Name Path -Value $item.FullName
                $temp | Add-Member -MemberType NoteProperty -Name LastAccess -Value $item.LastAccessTime
                $temp | Add-Member -MemberType NoteProperty -Name Owner -Value $aclProperties.Owner
                $temp | Add-Member -MemberType NoteProperty -Name FileSystemRights -Value $object.FileSystemRights
                $temp | Add-Member -MemberType NoteProperty -Name AccessControlType -Value $object.AccessControlType
                $temp | Add-Member -MemberType NoteProperty -Name IdentityReference -Value $object.IdentityReference
                $listData += $temp                
            }            
        }
    }Catch{
        $temp = New-Object -TypeName PSObject
        $temp | Add-Member -MemberType NoteProperty -Name Path -Value $item.FullName
        $temp | Add-Member -MemberType NoteProperty -Name LastAccess -Value $item.LastAccessTime
        $temp | Add-Member -MemberType NoteProperty -Name Owner -Value 'No acces'
        $temp | Add-Member -MemberType NoteProperty -Name FileSystemRights -Value 'No acces'
        $temp | Add-Member -MemberType NoteProperty -Name AccessControlType -Value 'No acces'
        $temp | Add-Member -MemberType NoteProperty -Name IdentityReference -Value 'No acces'
        $listData += $temp 
    }
    }
    foreach($item in $pathnoacces){
    $temp = New-Object -TypeName PSObject
    $temp | Add-Member -MemberType NoteProperty -Name Path -Value $item.ToString().Split("'")[1]
    $temp | Add-Member -MemberType NoteProperty -Name LastAccess -Value 'No acces'
    $temp | Add-Member -MemberType NoteProperty -Name Owner -Value 'No acces'
    $temp | Add-Member -MemberType NoteProperty -Name FileSystemRights -Value 'No acces'
    $temp | Add-Member -MemberType NoteProperty -Name AccessControlType -Value 'No acces'
    $temp | Add-Member -MemberType NoteProperty -Name IdentityReference -Value 'No acces'
    $listData += $temp 
    }
    $csvName = "$($currentItem.ruta.trim().split('\prosegurf.emea.prosegur.local\',[System.StringSplitOptions]::RemoveEmptyEntries))"+'.csv'
    try {
        if ((Test-Path -Path $archivoExport\$csvName) -eq $false){
            $listData | Export-Csv -Path $archivoExport\$csvName -Encoding UTF8 -NoTypeInformation -Force
            $resultObject = New-Object -TypeName psobject
            $resultObject | Add-Member -MemberType NoteProperty -Name 'ruta' -Value $currentItem.ruta
            $resultObject | Add-Member -MemberType NoteProperty -Name 'export-csv' -Value 'Succes'
            $resultObject | Add-Member -MemberType NoteProperty -Name 'Nombre del archivo' -Value $csvName
            $listDirectoriosExplorados += $resultObject
            }
        elseif ((Test-Path -Path $archivoExport\$csvName) -eq $true){
            $csvName = $(Get-Date -Format filedatetime)+$csvName
            $listData | Export-Csv -Path $archivoExport\$csvName -Encoding UTF8 -NoTypeInformation -Force
            $resultObject = New-Object -TypeName psobject
            $resultObject | Add-Member -MemberType NoteProperty -Name 'ruta' -Value $currentItem.ruta
            $resultObject | Add-Member -MemberType NoteProperty -Name 'export-csv' -Value 'Succes'
            $resultObject | Add-Member -MemberType NoteProperty -Name 'Nombre del archivo' -Value $csvName
            $listDirectoriosExplorados += $resultObject
        }
    }
    catch {
        $resultObject = New-Object -TypeName psobject
        $resultObject | Add-Member -MemberType NoteProperty -Name 'ruta' -Value $currentItem.ruta
        $resultObject | Add-Member -MemberType NoteProperty -Name 'export-csv' -Value 'Fail'
        $resultObject | Add-Member -MemberType NoteProperty -Name 'Nombre del archivo' -Value $csvName
        $listDirectoriosExplorados += $resultObject
    }    
    $listDirectoriosExplorados | Export-Csv -Path  "$archivoExport\00listadoExportDirectorios.csv"    
}