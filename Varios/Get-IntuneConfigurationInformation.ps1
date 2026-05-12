# ============================================
# CONFIGURACIONES INICIALES
# ============================================

$csvPath = ".\Intune_ConfigProfiles_Assignments.csv"
$graphApiVersion = "beta"

# Verificar y crear ruta CSV si es necesario
$folderPath = Split-Path $csvPath
if (-not (Test-Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
    Write-Host " Carpeta creada: $folderPath"
}

# ============================================
# VERIFICAR MÓDULOS REQUERIDOS
# ============================================

$requiredModules = @(
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.DeviceManagement",
    "Microsoft.Graph.Groups"
)

$missingModules = $requiredModules | Where-Object {
    -not (Get-Module -Name $_ -ListAvailable -ErrorAction SilentlyContinue)
}

if ($missingModules.Count -gt 0) {
    Write-Host "Instalando módulos faltantes..."
    Install-Module -Name $missingModules -Force -AllowClobber -Scope CurrentUser
}

foreach ($module in $requiredModules) {
    if (-not (Get-Module -Name $module)) {
        try {
            Import-Module -Name $module -ErrorAction Stop
            Write-Host " Módulo '$module' importado." -ForegroundColor Green
        }
        catch {
            Write-Host " No se pudo importar el módulo '$module': $_" -ForegroundColor Red
        }
    }
}

# ============================================
# AUTENTICACIÓN
# ============================================

if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes DeviceManagementConfiguration.Read.All, Group.Read.All
    Write-Host "🔐 Autenticado en Microsoft Graph." -ForegroundColor Green
}

# ============================================
# OBTENER CONFIGURATION PROFILES Y SUS ASIGNACIONES
# ============================================

Write-Host "`n⏳ Obteniendo Device Configuration Profiles..." -ForegroundColor Cyan

function Get-AllGraphItems {
    param (
        [Parameter(Mandatory)]
        [string]$Uri
    )

    $items = @()
    do {
        $response = Invoke-MgGraphRequest -Method GET -Uri $Uri
        $items += $response.Value
        $Uri = $response.'@odata.nextLink'
    } while ($Uri)

    return $items
}

# Llamada con paginación
$profilesUri = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/deviceConfigurations"
$profiles = Get-AllGraphItems -Uri $profilesUri

$results = @()

foreach ($profile in $profiles) {
    $assignmentsUri = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/deviceConfigurations/$($profile.id)/assignments"
    $assignments = (Invoke-MgGraphRequest -Method GET -Uri $assignmentsUri).Value

    foreach ($assign in $assignments) {
    $assignmentType = $assign.target.'@odata.type' -replace '#microsoft.graph.', ''

    switch ($assignmentType) {
        'allUsersAssignmentTarget' {
            $groupName = "All Users (Built-in)"
        }
        'allDevicesAssignmentTarget' {
            $groupName = "All Devices (Built-in)"
        }
        'groupAssignmentTarget' {
            $groupId = $assign.target.groupId
            if (![string]::IsNullOrWhiteSpace($groupId)) {
                $group = Get-MgGroup -GroupId $groupId -ErrorAction SilentlyContinue
                $groupName = if ($group) { $group.DisplayName } else { $groupId }
            } else {
                $groupName = " (GroupId vacío)"
            }
        }
        default {
            $groupName = " Tipo de asignación no reconocido: $assignmentType"
        }
    }

    $results += [PSCustomObject]@{
        ProfileName    = $profile.displayName
        AssignmentType = $assignmentType
        GroupName      = $groupName
    }
}
}

# ============================================
# EXPORTAR A CSV Y MOSTRAR RESULTADOS
# ============================================

$results | Sort-Object ProfileName, GroupName | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "`n Resultados exportados a: $csvPath" -ForegroundColor Green

# Mostrar en consola
Write-Host "`n Perfiles y asignaciones encontradas:" -ForegroundColor Cyan
$results | Format-Table -AutoSize

Write-Host "`nTotal de perfiles procesados: $($profiles.Count)" -ForegroundColor Yellow
Write-Host "Total de asignaciones encontradas: $($results.Count)" -ForegroundColor Yellow
