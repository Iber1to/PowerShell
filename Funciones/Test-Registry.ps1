function Test-Registry {
    param (
        [ValidateSet("HKLM:\", "HKCU:\", "HKCR:\", "HKU:\", "HKCC:\")]
        [string]$hive,
        [string]$path,
        [string]$value
    )
    $pathFull = $hive + $path
    if($value){
        try{
            $result = get-itemproperty -path $pathFull -name $value -ea 0
            if($result){
                return $true
            }
            else{
                return $false
            }
        }
        catch{
            if($_.Exception -is [System.Management.Automation.MethodInvocationException]){
                return $false
            }
            else{
                throw $_
            }
        }
    }
    else{
        return (Test-Path -path $pathFull -ea 0)
    }
}