# Quitar comentario la primera vez que se use para instalar el modulo.
# Install-Module -Name Microsoft.Graph.Users, Microsoft.Graph.Groups, Microsoft.Graph.DeviceManagement, Microsoft.Graph.Devices.CorporateManagement

$scopes = @("DeviceManagementApps.Read.All","DeviceManagementManagedDevices.Read.All","User.Read.All","GroupMember.ReadWrite.All","Group.ReadWrite.All")
Connect-MgGraph -scopes $scopes
Select-MgProfile -Name beta

# El $Name tiene que ser tal como aparece en el name de Get-Package o en DisplayName de Get-InstalledApplication
$Name = "Application Name"
$application = Get-MgDeviceAppMgtMobileApp -Filter "DisplayName eq '$Name'" | Where-Object isAssigned -eq $true
$applicationInstallationsUsers = (Get-MgDeviceAppMgtMobileAppDeviceStatuses -MobileAppId $($application.id)).userPrincipalName | sort -unique
$applicationInstallationsDevices = (Get-MgDeviceAppMgtMobileAppDeviceStatuses -MobileAppId $($application.id)).deviceId | sort -unique

$groupParams = @{
    Description = "Group containing user or devices with $($application.name) installed"
    DisplayName = $Name
    MailEnabled = $false
    MailNickname = "NotSet"
    SecurityEnabled = $true
}
New-MgGroup -BodyParameter $groupParams
$groupId = (Get-MgGroup -Filter "DisplayName eq '$groupName'").Id

foreach ($user in $applicationInstallationsUsers) {
    $userObjectId = (Get-MgUser -UserId $user).Id
    New-MgGroupMember -GroupId $groupId -DirectoryObjectId $userObjectId
}

foreach ($device in $applicationInstallationsDevices) {
    #Retrieve device Azure Id from device Intune Id
    $deviceAzureId = (Get-MgDeviceManagementManagedDevice -ManagedDeviceId $device).AzureActiveDirectoryDeviceId

    #Retrieve device Object Id from device Azure Id
    $deviceObjectId = (Get-MgDevice -Filter "DeviceId eq '$deviceAzureId'").Id

    New-MgGroupMember -GroupId $groupId -DirectoryObjectId $deviceObjectId
}