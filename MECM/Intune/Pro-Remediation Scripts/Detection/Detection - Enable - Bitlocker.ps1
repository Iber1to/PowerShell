# Verificar el estado de BitLocker en la unidad C:
$bitlockerStatus = Get-BitLockerVolume -MountPoint 'C:' | Select-Object -ExpandProperty ProtectionStatus

if ($bitlockerStatus -eq "Off") {
    Write-Host "BitLocker no activado"
    exit 1
} else {
    Write-Host "BitLocker está activado en la unidad C:"
    exit 0
}
