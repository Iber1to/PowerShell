$ou = "OU=Workstations,DC=contoso,DC=Intcontoso,DC=LOCAL"
$exportPath = "C:\Temp\GpoWorkstation\"

$lisnkedGPOs = Get-ADOrganizationalUnit -LDAPFilter '(name=*)' -SearchBase $ou -SearchScope Subtree | Select-object -ExpandProperty LinkedGroupPolicyObjects
$LinkedGPOGUIDs = $lisnkedGPOs | ForEach-object{$_.Substring(4,36)}
$listGPOs = $LinkedGPOGUIDs | ForEach-object {Get-GPO -Guid $_ | Select-object DisplayName}
$listGposUnique =$listGPOs | Select-Object -Property DisplayName -Unique
$listGposUnique.ForEach({Get-GPOReport -Name $_.DisplayName -ReportType Xml -Path "$($exportPath)\$($_.DisplayName).xml"})