#Parametros
# No se puede hacer con el import de Intune, el ObjectID que pide el import Bulk es el del export de Azure con ninguno de los de Intune sirve. 
#Este fichero deber ser el export devices de Azure y tiene que contener las columnas "displayName" y "objectId"
$ficheroAzureCsv = "C:\Users\aleja\Downloads\exportDevice_2023-6-23.csv"
#El fichero debe contener una columna "displayName" con el nombre del dispositivo
$ficheroDevicesMatch = "C:\Users\aleja\Downloads\test1.csv"
#Fichero de salida para el csv
$ficheroSalida = "C:\temp\devicesupgrade14.csv"
#Strings para el export-csv
$string1 = "version:v1.0"
$string2 = "Member object ID or user principal name [memberObjectIdOrUpn] Required"

#Inicializo Arrays
$azureObjects = [System.Collections.ArrayList]::new()
$matchObjets = [System.Collections.ArrayList]::new()
$finalObjetcs = [System.Collections.ArrayList]::new()

#Cargo archivos con datos
Import-csv $ficheroAzureCsv | ForEach-Object {$azureObjects.add($_)} |Out-Null
Import-csv $ficheroDevicesMatch | ForEach-Object {$matchObjets.add($_)} |Out-Null

#Cargo strings al Output
$finalObjetcs.Add($string1)
$finalObjetcs.Add($string2)

foreach($item in $matchObjets){
    $Matchuser = $azureObjects.where({$_.displayName -eq $item.displayName})
    if($Matchuser){$finalObjetcs.Add($Matchuser.objectId)
    }
}

$finalObjetcs | Out-File $ficheroSalida -Force