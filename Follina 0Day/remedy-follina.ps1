$backupFile = 'C:\Windows\backupreg\follina.reg'
reg export HKEY_CLASSES_ROOT\ms-msdt follina.reg
New-item -path 'C:\Windows\' -name 'backupreg' -ItemType 'directory' -InformationAction SilentlyContinue -Force
Move-Item follina.reg -Destination 'C:\Windows\backupreg\' -Force
if(Test-Path $backupFile){
    reg delete HKEY_CLASSES_ROOT\ms-msdt /f
    write-output 'Patch Done'
    exit 0
}
else{
    reg delete HKEY_CLASSES_ROOT\ms-msdt /f
    write-output 'Backup Fail'
    exit 1
}

