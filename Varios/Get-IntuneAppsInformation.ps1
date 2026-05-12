# Variables a definir
# Ruta del archivo CSV de salida
$csvPath = ".\IntuneApps_Assignments.csv"
 
# Módulos a comprobar
$requiredModules = @(
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.DeviceManagement",
    "Microsoft.Graph.Groups"
    
)

# Comprobar si los módulos están instalados
$missingModules = $requiredModules | Where-Object {
    -not (Get-Module -Name $_ -ListAvailable -ErrorAction SilentlyContinue)
}

# Mostrar los que faltan (si hay)
if ($missingModules.Count -gt 0) {
    Write-Host "Los siguientes módulos están faltando:" -ForegroundColor Yellow
    $missingModules | ForEach-Object { Write-Host " - $_" }
} else {
    Write-Host " Todos los módulos requeridos están instalados." -ForegroundColor Green
}

# Instalar los módulos faltantes
if ($missingModules) {
    Write-Host "Instalando módulos faltantes: $missingModules"
    Install-Module -Name $missingModules -Force -AllowClobber -Scope AllUsers 
}

# Importar los módulos requeridos que no esten en la sesión actual
foreach ($module in $requiredModules) {
    if (-not (Get-Module -Name $module)) {
        try {
            Import-Module -Name $module -ErrorAction Stop
            Write-Host " Módulo '$module' importado correctamente." -ForegroundColor Green
        }
        catch {
            Write-Host " No se pudo importar el módulo '$module': $_" -ForegroundColor Red
        }
    } else {
        Write-Host " Módulo '$module' ya está cargado." -ForegroundColor Cyan
    }
}

# Comprueba si ya estás autenticado en Microsoft Graph
if (Get-MgContext) {
    Write-Host "✔ Ya autenticado en Microsoft Graph" -ForegroundColor Green
}else {
    Write-Host "… Iniciando autenticación en Microsoft Graph (Interactive) …" -ForegroundColor Cyan
    Connect-MgGraph -scopes Group.Read.All, DeviceManagementManagedDevices.Read.All, DeviceManagementServiceConfig.Read.All, DeviceManagementApps.Read.All, DeviceManagementApps.Read.All, DeviceManagementConfiguration.Read.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementApps.ReadWrite.All
    Write-Host "✔ Autenticación completada" -ForegroundColor Green
 
}

# Applications 
 
$Resource = "deviceAppManagement/mobileApps"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=(isAssigned eq true)&`$expand=Assignments"
 
 
$Apps = (Invoke-MgGraphRequest -Method GET -Uri $uri).Value | Where-Object {$_.assignments.intent -like "required"}
 
Write-host "Start Script output -----------------" -ForegroundColor Cyan
# Csv export
$results = foreach ($app in $apps) {
    foreach ($assign in $app.assignments) {
        # — Determinar nombre de grupo (built-in o consulta)
        switch -Wildcard ($assign.id) {
            "acacacac-9df4-4c7d-9d50-4ef0226f57a9*" {
                $groupName = "All Users (Built-in)"
                break
            }
            "adadadad-808e-44e2-905a-0b7873a8a531*" {
                $groupName = "All Devices (Built-in)"
                break
            }
            default {
                $grp = Get-MgGroup -Filter "id eq '$($assign.target.groupId)'" -ErrorAction SilentlyContinue
                $groupName = if ($grp) { $grp.DisplayName } else { $assign.target.groupId }
            }
        }
        # — Crea el objeto con las 3 columnas: App, Grupo, Tipo de Asignación
        [PSCustomObject]@{
            AppDisplayName = $app.DisplayName
            AssignmentType = $assign.intent
            GroupName      = $groupName
        }
    }
} 
$results | Sort-Object AppDisplayName, GroupName | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 

# Mostrar el resultado en la consola
foreach ($App in $Apps) { 
    Write-host "$($App.DisplayName)" -ForegroundColor Yellow
    if ($App.assignments.id -like "acacacac-9df4-4c7d-9d50-4ef0226f57a9*" -or $App.assignments.id -like "adadadad-808e-44e2-905a-0b7873a8a531*") {
        if ($App.assignments.id -like "acacacac-9df4-4c7d-9d50-4ef0226f57a9*"){Write-host "Assigned as $($App.assignments.intent) ---- EntraID Group: All Users (Built-in Group)"}
        if ($App.assignments.id -like "adadadad-808e-44e2-905a-0b7873a8a531*"){Write-host "Assigned as $($App.assignments.intent) ---- EntraID Group: All Devices (Built-in Group)"}
    }
    Else { 
        $EIDGroupId = $App.assignments.target.groupId 
        foreach ($group in $EIDGroupId) { 
            $EIdGroup = Get-MgGroup -Filter "Id eq '$group'" -ErrorAction Continue
            $AssignIntent = $App.assignments | Where-Object -Property id -like "$group*" 
            Write-host "Assigned as $($AssignIntent.intent) ---- EntraID Group: $($EIdGroup.displayName)"
        }
    }
}
Write-host "End Script output -----------------" -ForegroundColor Cyan
Write-host "Total apps: $($apps.count)" -ForegroundColor Cyan