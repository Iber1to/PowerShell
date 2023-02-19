Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

function launchPass {
       
    switch ($listbox.SelectedItem) {
    'EMEA' { $adUser = 'APP_EME_CMDB'; $server = 'emea.contoso.local' }
    'LATAM1' { $adUser = 'APP_LA1_CMDB'; $server = 'latam1.contoso.local' }
    'LATAM2' { $adUser = 'APP_LA2_CMDB'; $server = 'latam2.contoso.local' }
    'APAC' { $adUser = 'APP_APA_CMDB'; $server = 'apac.contoso.local' }
    'NA' { $adUser = 'APP_NA_CMDB'; $server = 'na.contoso.local' }
}
    $mergedPassword =  $textBox2.Text + $textBox.Text | ConvertTo-SecureString -AsPlainText -Force

    try {
    Set-ADAccountPassword -Identity $adUser -NewPassword $mergedPassword -Server $server
    return [System.Windows.MessageBox]::Show("Password cambiado con exito ",'Assembly Password','0','Asterisk ')
    
}
    catch {
    return [System.Windows.MessageBox]::Show('Error al cambiar el password', 'Assembly Password','0','Error')
    
}
}

function clearForm {
    $textBox.Text = $null
    $textBox2.Text = $null
    $listbox.SelectedItem = $null    
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Assembly Password'
$form.Size = New-Object System.Drawing.Size(450, 300)
$form.StartPosition = 'CenterScreen'

#Boton Lanzar
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(100, 200)
$okButton.Size = New-Object System.Drawing.Size(100, 23)
$okButton.Text = 'Launch'
$okButton.Add_Click({launchPass;clearForm})
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

#Boton Salir
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Location = New-Object System.Drawing.Point(250, 200)
$exitButton.Size = New-Object System.Drawing.Size(100, 23)
$exitButton.Text = 'Exit'
$exitButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $exitButton
$form.Controls.Add($exitButton)

#Password Sistemas
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(250, 10)
$label.Size = New-Object System.Drawing.Size(150, 20)
$label.Text = 'Password Systemas'
$label.Anchor
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.MaskedTextBox
$textBox.PasswordChar = '*'
$textBox.Location = New-Object System.Drawing.Point(250, 30)
$textBox.Size = New-Object System.Drawing.Size(150, 20)
$form.Controls.Add($textBox)

#Password CISO
$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(50, 10)
$label2.Size = New-Object System.Drawing.Size(150, 20)
$label2.Text = 'Password CISO'
$form.Controls.Add($label2)

$textBox2 = New-Object System.Windows.Forms.MaskedTextBox
$textBox2.PasswordChar = '*'
$textBox2.Location = New-Object System.Drawing.Point(50, 30)
$textBox2.Size = New-Object System.Drawing.Size(150, 20)
$form.Controls.Add($textBox2)

#Selección de cuenta:

$label3 = New-Object System.Windows.Forms.Label
$label3.Location = New-Object System.Drawing.Point(150, 90)
$label3.Size = New-Object System.Drawing.Size(150, 20)
$label3.Text = 'Usuario AD'
$form.Controls.Add($label3)

$listBox = New-Object System.Windows.Forms.combobox
$listBox.Location = New-Object System.Drawing.Point(150, 110)
$listBox.Size = New-Object System.Drawing.Size(150, 20)

[void]$listBox.Items.Add('EMEA')
[void]$listBox.Items.Add('LATAM1')
[void]$listBox.Items.Add('LATAM2')
[void]$listBox.Items.Add('APAC')
[void]$listBox.Items.Add('NA')
$form.Controls.Add($listBox)

$form.Topmost = $true
$form.Add_Shown({ $textBox.Select() })

$form.ShowDialog()


