Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


#Carga el archivo CSV
function Get-FileName($InitialDirectory)
{
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $InitialDirectory
    $OpenFileDialog.filter = "CSV (*.csv) | *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.FileName
}

#Envia mensajes por pantalla

function show-notify {
param ([string]$message)
$notify = new-object system.windows.forms.notifyicon
$notify.icon = [System.Drawing.SystemIcons]::Information
$notify.visible = $true
return $notify.showballoontip(30,$message,' ',[system.windows.forms.tooltipicon]::None)
}


#Pantalla de inicio
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Create Users'
$form.Size = New-Object System.Drawing.Size(250,200)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,75)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'Load CSV'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Por favor cargue el CSV con los usuarios'
$form.Controls.Add($label)
$form.Topmost = $true
$result = $form.ShowDialog()
if ($result -eq [System.Windows.Forms.DialogResult]::OK){$FileBrowser = Get-FileName}

show-notify -message "Procesando archivo CSV"
#Normalizando caracteres en el CSV para evitar acentos, ñ o caracteres raros.
Get-Content $FileBrowser  -Encoding UTF7 | ForEach-Object {[Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding('Cyrillic').GetBytes($_))} | Set-Content .\temporal.csv
$UserList = Import-Csv .\temporal.csv -Delimiter ";"

#Comprobando que el CSV cargado tiene los campos correctos. 
$ListProperties = ($UserList | Get-Member -MemberType NoteProperty) | Select-Object Name
$CheckCsv = @('Codigo AD', 'Name', 'Surname', 'Complete Name', 'Logon Name', 'UPN', 'Direccion email ALLFUNDS', 'Password AD', 'OU CREACION')
$test = $($listproperties.ForEach({$CheckCsv.Contains($_.Name)}) | Sort-Object -Unique)

if(($test -match "True") -and ($test.Count -eq 1)){show-notify -message "El archivo CSV cargado tiene el formato correcto"}else{
    $Result = [System.Windows.Forms.MessageBox]::Show("El CSV cargado no tiene los campos correctos. ¿Desea ver la lista de campos necesarios?", "Inetum Creador de usuarios", "YesNo", [System.Windows.Forms.MessageBoxIcon]::Error)
    if($Result -eq "Yes"){$CheckCsv |Out-GridView ; Exit 1}else{Exit 1}
}

show-notify -message "Creando Usuarios"
#Cargando Usuarios
$GroupsAddFail = $UsersFail = $UpnSuffix = @()
$UpnSuffix += Get-ADForest |Select-Object -ExpandProperty UPNSuffixes
$UpnSuffix += Get-ADForest |Select-Object -ExpandProperty Name
#Grupos por defecto
$GroupsDefault = "CORP_VPN", "zscaler_pov"
$OuTree = (Get-ADOrganizationalUnit -Filter * -Properties *)
foreach($User in $UserList){
    foreach($Ou in $OuTree){if($Ou.CanonicalName -match $User.'OU CREACION'){$OuExist = $Ou.DistinguishedName}}
    $UpnExist = $null
    foreach($Upn in $UpnSuffix){if($Upn -eq $user.'Direccion email ALLFUNDS'.Split('@')[-1]){$UpnExist = $Upn}}
    If($OuExist -and $UpnExist){  
# Crear objeto de usuario y definir sus propiedades
    
        try{
            New-ADUser -SamAccountName $User.'Codigo AD' -Name $User.'Codigo AD' -UserPrincipalName $User.UPN -Description "ESC/C///" -GivenName $User.Name -Surname $User.Surname -Enabled $True -ChangePasswordAtLogon $True -DisplayName $User.'Complete Name' -EmailAddress $User.'Direccion email ALLFUNDS' -Path $OuExist -AccountPassword (convertto-securestring $User.'Password AD' -AsPlainText -Force) 
        }catch{$UsersFail += $User.'Complete Name'}

        try{$GroupsDefault.ForEach({Add-ADGroupMember -Identity $_ -Members $User.'Codigo AD'})}catch{$GroupsAddFail += $User.'Complete Name'}
    
    }else{$UsersFail += $User.'Complete Name'}
}

If($Error.Count -gt 0){
    $Result = [System.Windows.Forms.MessageBox]::Show("Se produjeron $($Error.count) errores. ¿Desea ver un listado con los errores?", "Inetum Creador de usuarios", "YesNo", [System.Windows.Forms.MessageBoxIcon]::Error)
    if($Result -eq "Yes"){$error |Out-HtmlView}
}

If(($UsersFail.count -gt 0) -or ($GroupsAddFail.count -gt 0) ){
    If($UsersFail.count -gt 0){$CountFail = ($UsersFail |Sort-Object -Unique ).count}else{$CountFail = ($GroupsAddFail |Sort-Object -Unique ).count}
    $Result = [System.Windows.Forms.MessageBox]::Show("$CountFail usuarios no se pudieron crear o añadir a un grupo. ¿Desea ver un listado con los usuarios?", "Inetum Creador de usuarios", "YesNo", [System.Windows.Forms.MessageBoxIcon]::Error)
    if($Result -eq "Yes"){$UsersFail |Sort-Object -Unique |Out-HtmlView}
}else{[System.Windows.Forms.MessageBox]::Show("La ejecucion se completo sin problemas, $($UserList.Count) usuarios creados", "Inetum Creador de usuarios", "Ok", [System.Windows.Forms.MessageBoxIcon]::Information)}



