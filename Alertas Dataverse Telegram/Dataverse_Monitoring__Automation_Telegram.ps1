# Autenticación Entra ID.
$appId = "tu appId aquí"
$secret = "tu secret aquí"
$tenantId = "tu tenantid aqui"

Add-PowerAppsAccount -Endpoint prod -TenantID $tenantId -ApplicationId $appId -ClientSecret $secret -Verbose

# Obtener los entornos de PowerApps
$environments = Get-AdminPowerAppEnvironment -Capacity

# Capacidades máximas del Dataverse en GB (Coloca la capacidad máxima de tu Dataverse para BD, File y Logs)
$maxDatabaseCapacityGB = 213.33 # En GB
$maxFileCapacityTB = 1.57 # En TB
$maxLogCapacityGB = 2 # En GB

# Inicializar las sumas de capacidad
$totalDatabaseCapacityGB = 0
$totalFileCapacityTB = 0
$totalLogCapacityGB = 0

# Sumar las capacidades de todos los entornos
foreach ($env in $environments) {
    $dbCapacity = ($env.Capacity | Where-Object {$_.capacityType -eq 'Database'}).actualConsumption / 1024
    $fileCapacity = ($env.Capacity | Where-Object {$_.capacityType -eq 'File'}).actualConsumption / (1024 * 1024)
    $logCapacity = ($env.Capacity | Where-Object {$_.capacityType -eq 'Log'}).actualConsumption / 1024

    if ($dbCapacity -ne $null) {
        $totalDatabaseCapacityGB += $dbCapacity
    }
    if ($fileCapacity -ne $null) {
        $totalFileCapacityTB += $fileCapacity
    }
    if ($logCapacity -ne $null) {
        $totalLogCapacityGB += $logCapacity
    }
}

# Restar la capacidad conocida
$totalDatabaseCapacityGB -= 17.44
$totalFileCapacityTB -= 0.02

# Calcular el porcentaje de capacidad consumida y disponible
$databaseCapacityConsumed = ($totalDatabaseCapacityGB) / ($maxDatabaseCapacityGB) * 100
$fileCapacityConsumed = ($totalFileCapacityTB) / $maxFileCapacityTB * 100
$logCapacityConsumed = $totalLogCapacityGB / $maxLogCapacityGB * 100

$databaseCapacityAvailable = 100 - $databaseCapacityConsumed
$fileCapacityAvailable = 100 - $fileCapacityConsumed
$logCapacityAvailable = 100 - $logCapacityConsumed

# Preparar el mensaje para Telegram en formato legible
$message = @"
Tipo de Capacidad: Base de Datos
Usada: {0:N2} GB
Capacidad Máxima: 213.33 GB
Porcentaje Usado: {1:F2} %
Porcentaje Disponible: {2:F2} %

Tipo de Capacidad: Archivo
Usada: {3:N2} TB
Capacidad Máxima: 1.57 TB
Porcentaje Usado: {4:F2} %
Porcentaje Disponible: {5:F2} %

Tipo de Capacidad: Registro
Usada: {6:N2} GB
Capacidad Máxima: 2 GB
Porcentaje Usado: {7:F2} %
Porcentaje Disponible: {8:F2} %
"@ -f $totalDatabaseCapacityGB, $databaseCapacityConsumed, $databaseCapacityAvailable, $totalFileCapacityTB, $fileCapacityConsumed, $fileCapacityAvailable, $totalLogCapacityGB, $logCapacityConsumed, $logCapacityAvailable

# Token y Chat ID de Telegram
$telegramToken = "tu telegram token aqui"
$chatId = "tu chat id aqui"

# Función para enviar mensaje a Telegram
function Send-TelegramMessage {
    param (
        [string]$token,
        [string]$chatId,
        [string]$message
    )
    $url = "https://api.telegram.org/bot$token/sendMessage"
    $params = @{
        chat_id = $chatId
        text = $message
    }
    Invoke-RestMethod -Uri $url -Method Post -ContentType "application/x-www-form-urlencoded" -Body $params
}

# Enviar el mensaje a Telegram
Send-TelegramMessage -token $telegramToken -chatId $chatId -message $message
