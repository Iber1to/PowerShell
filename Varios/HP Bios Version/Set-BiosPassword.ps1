#To deploy by Intune

#Detection Section

$computerModel = Get-WMIObject -Class Win32_ComputerSystem
$Interface = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSettingInterface -ErrorAction SilentlyContinue
$HPBiosSetting = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSetting -ErrorAction SilentlyContinue
$SetupPasswordCheck = ($HPBiosSetting | Where-Object Name -eq "Setup Password").IsSet
if (($computerModel.Manufacturer -eq 'HP') -and ($SetupPasswordCheck -eq '0')){Write-Output 'No password active';Exit 1}
    elseif(($computerModel.Manufacturer -ne 'HP')){Write-Output 'Manufacturer not supported'; Exit 1}
        elseif(($computerModel.Manufacturer -eq 'HP') -and ($SetupPasswordCheck -eq '1')){Write-Output 'Password Enable'; Exit 0}       
else{Write-Output 'Unknown'; Exit 1}


#Remediation Section 
$computerModel = Get-WMIObject -Class Win32_ComputerSystem
$Interface = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSettingInterface -ErrorAction SilentlyContinue
$HPBiosSetting = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSetting -ErrorAction SilentlyContinue
$SetupPasswordCheck = ($HPBiosSetting | Where-Object Name -eq "Setup Password").IsSet
if(($computerModel.Manufacturer -ne 'HP')){Write-Output 'Manufacturer not supported'; Exit 1}

$Interface = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSettingInterface
$HPBiosSetting = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSetting
$Password = "Insert you Password"
$codeOperation00 = $Interface.SetBIOSSetting("Setup Password","<utf-16/>" + $Password,"<utf-16/>").return
$codeOperation01 = $Interface.SetBIOSSetting("Prompt for Admin password on F9 (Boot Menu)","Enable","<utf-16/>" + $Password).return
$codeOperation02 = $Interface.SetBIOSSetting("Prompt for Admin password on F11 (System Recovery)","Enable","<utf-16/>" + $Password).return
$codeOperation03 = $Interface.SetBIOSSetting("Prompt for Admin password on F12 (Network Boot)","Enable","<utf-16/>" + $Password).return
    
$codeOperation =  $codeOperation00 ,$codeOperation01, $codeOperation02, $codeOperation03

foreach($item in $codeOperation){
    switch ($item) {
        0 { $resultado += "OK" }
        1 { $resultado += "Not Supported" }
        2 { $resultado += "Unspecified error" }
        3 { $resultado += "Operation timed out" }
        4 { $resultado += "Operation failed or setting name is invalid" }
        5 { $resultado += "Invalid parameter" }
        6 { $resultado += "Access denied or incorrect password" }
        7 { $resultado += "Bios user already exists" }
        8 { $resultado += "Bios user not present" }
        9 { $resultado += "Bios user name too long" }
        10 { $resultado += "Password policy not met" }
        11 { $resultado += "Invalid keyboard layout" }
        12 { $resultado += "Too many users" }
        32768 { $resultado += "Security or password policy not met" }
        default { $resultado += "Unknown error: $item" }
        }
    }
    return $resultado
    exit $item
