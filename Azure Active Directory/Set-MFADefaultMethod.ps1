# Info sobre el endpoint usado en: https://learn.microsoft.com/en-us/graph/api/authentication-update?view=graph-rest-beta&tabs=http

# Define el método de MFA preferido (reemplaza <MFAMethod> con el código del método deseado)
$preferredMethod = "PhoneAppNotification" 

# Define el nombre del grupo específico
$groupName = "<NombreDelGrupo>"

# Define el path completo del archivo para los resultados
$PathCSV = "C\temp\cambiodeMFA.csv"

# Conectarse a Microsoft Graph (asegúrate de tener los permisos adecuados)
Install-Module Microsoft.Graph -Scope CurrentUser -Force
Connect-MgGraph -Scopes "User.ReadWrite.All", "GroupMember.Read.All"

# Obtener el ID del grupo por su nombre
$group = Get-MgGroup -Filter "displayName eq '$groupName'"
if (-not $group) {
    Write-Host "Group not found: $groupName"
    exit
}

# Obtener los usuarios del grupo
$groupId = $group.Id
$groupMembers = Get-MgGroupMember -GroupId $groupId -All

# Crear el cuerpo de la solicitud JSON con el método de MFA preferido
$bodyJson = @{ userPreferredMethodForSecondaryAuthentication = $preferredMethod } | ConvertTo-Json

# Inicializar arrays para usuarios actualizados y fallidos
$updatedUsers = @()
$failedUsers = @()

# Iterar sobre los usuarios del grupo y actualizar el método de MFA
$groupMembers | ForEach-Object {
    $uri = "https://graph.microsoft.com/beta/users/$($_.Id)/authentication/signInPreferences"
    $result = [PSCustomObject]@{
        UPN = $_.UserPrincipalName
    }
    try {
        Invoke-MgGraphRequest -Uri $uri -Body $bodyJson -Method Patch -ErrorAction Stop
        $updatedUsers += $result.UPN
    } catch {
        $failedUsers += $result.UPN
    }
}

# Crear un objeto con los resultados de la operación
$outputData = [PSCustomObject]@{
    "Default MFA Authentication - Successfully Updated Users" = $updatedUsers -join ","
    "Default MFA Authentication - Failed Users" = $failedUsers -join ","
}

# Exportar los resultados a un archivo CSV (reemplaza <CSVFilePath> con la ruta del archivo deseado)
$outputData | Export-Csv -Path $PathCSV -NoTypeInformation