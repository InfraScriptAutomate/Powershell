# Credenciales de Entra ID
$appId = "tu_app_id_aqui"
$secret = "tu_secret_aqui"
$tenantId = "tu_tenand_id_aqui"

Add-PowerAppsAccount -Endpoint prod -TenantID $tenantId -ApplicationId $appId -ClientSecret $secret -Verbose

# Obtener los entornos de PowerApps
$environments = Get-AdminPowerAppEnvironment -Capacity

# Función para formatear la capacidad a MB y con dos decimales
function Format-Capacity {
    param (
        [double]$capacity
    )
    return "{0:N2}" -f ($capacity / 1024) + " GB"
}

# Seleccionar los campos específicos de cada entorno y mostrarlos con capacidades en GB y dos decimales
$environments | Select-Object `
    @{Name="EnvironmentName"; Expression={$_.EnvironmentName}}, `
    @{Name="DisplayName"; Expression={$_.DisplayName}}, `
    @{Name="EnvironmentType"; Expression={$_.EnvironmentType}}, `
    @{Name="ProvisioningState"; Expression={$_.CommonDataServiceDatabaseProvisioningState}}, `
    @{Name="RetentionPeriod"; Expression={$_.RetentionPeriod}}, `
    @{Name="DatabaseCapacity_GB"; Expression={Format-Capacity (($_.Capacity | Where-Object {$_.capacityType -eq 'Database'}).actualConsumption)}}, `
    @{Name="FileCapacity_GB"; Expression={Format-Capacity (($_.Capacity | Where-Object {$_.capacityType -eq 'File'}).actualConsumption)}}, `
    @{Name="LogCapacity_GB"; Expression={Format-Capacity (($_.Capacity | Where-Object {$_.capacityType -eq 'Log'}).actualConsumption)}}
