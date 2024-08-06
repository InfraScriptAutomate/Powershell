$EmailTarget = "Tus correos electrónicos, si es mas de 1 destinatario, separarlos por (,)"
$EmailFrom = "Correo remitente"
$EmailSMTPServer = "IP de relay ó server SMTP"
$EmailSubject = "Alerta - Secretos Registro de Aplicación"

$AppID = 'App ID de tu aplicación de Entra ID'
$TenantID = 'Tenant ID de tu organización'
$AppSecret = 'Secreto de tu aplicación de Entra ID'

#Días que se va a evalular la expiración de los secretos
[int32]$expirationDays = 90

#Conexión para solicitar TOKEN de autenticación
Function Connect-MSGraphAPI {
    param (
        [system.string]$AppID,
        [system.string]$TenantID,
        [system.string]$AppSecret
    )
    begin {
        $URI = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token"
        $ReqTokenBody = @{
            Grant_Type    = "client_credentials"
            Scope         = "https://graph.microsoft.com/.default"
            client_Id     = $AppID
            Client_Secret = $AppSecret
        }
    }
    Process {
        Write-Host "Connecting to the Graph API"
        $Response = Invoke-RestMethod -Uri $URI -Method POST -Body $ReqTokenBody
    }
    End {
        $Response
    }
}

Function Get-MSGraphRequest {
    param (
        [system.string]$Uri,
        [system.string]$AccessToken
    )
    begin {
        [System.Array]$allPages = @()
        $ReqTokenBody = @{
            Headers = @{
                "Content-Type"  = "application/json"
                "Authorization" = "Bearer $($AccessToken)"
            }
            Method  = "Get"
            Uri     = $Uri
        }
    }
    process {
        write-verbose "GET request at endpoint: $Uri"
        $data = Invoke-RestMethod @ReqTokenBody
        while ($data.'@odata.nextLink') {
            $allPages += $data.value
            $ReqTokenBody.Uri = $data.'@odata.nextLink'
            $Data = Invoke-RestMethod @ReqTokenBody
            # to avoid throttling, the loop will sleep for 3 seconds
            Start-Sleep -Seconds 3
        }
        $allPages += $data.value
    }
    end {
        Write-Verbose "Returning all results"
        $allPages
    }
}

$tokenResponse = Connect-MSGraphAPI -AppID $AppID -TenantID $TenantID -AppSecret $AppSecret

$array = @()
$apps = Get-MSGraphRequest -AccessToken $tokenResponse.access_token -Uri "https://graph.microsoft.com/v1.0/applications/"
foreach ($app in $apps) {
    $app.passwordCredentials | foreach-object {
        #Si hay un secreto con una fecha de finalización, necesitamos obtener la expiración de cada uno.
        if ($_.endDateTime -ne $null) {
            [system.string]$secretdisplayName = $_.displayName
            [system.string]$displayname = $app.displayName
            $Date = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]$_.endDateTime, 'Central Standard Time')
            [int32]$daysUntilExpiration = (New-TimeSpan -Start ([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now, "Central Standard Time")) -End $Date).Days
            
            if (($daysUntilExpiration -ne $null) -and ($daysUntilExpiration -le $expirationDays) -and ($daysUntilExpiration -gt 0)) {
                $array += $_ | Select-Object @{
                    name = "displayName"; 
                    expr = { $displayName } 
                }, 
                @{
                    name = "secretName"; 
                    expr = { $secretdisplayName } 
                },
                 @{
                    name = "EndDateTime"; 
                    expr = { $Date.ToString('dd/MM/yyyy') } 
                },                
                @{
                    name = "daysUntil"; 
                    expr = { $daysUntilExpiration } 
                }
            }
            $daysUntilExpiration = $null
            $secretdisplayName = $null
        }
    }
}

# Convertir el array a una tabla HTML con colores para los días restantes
$Body = @"
<html>
<head>
<meta http-equiv='Content-Type' content='text/html; charset='UTF-8'>
</head>
<body style='text-align: center;'>
    <h2 style='text-align: center;'>Alerta - Secretos Registro de Aplicación</h2>
    <table border='1' style='margin: 0 auto;'>
        <tr>
            <th>Nombre Aplicación</th>
            <th>Nombre Secreto</th>
            <th>Fecha de Expiración</th>
            <th>Días Restantes</th>
        </tr>
"@

foreach ($item in $array) {

    $daysUntil = $item.daysUntil
    $color = if ($daysUntil -lt 30) { "red" } else { "blue" }
    $Body += "<tr><td>$($item.displayName)</td><td>$($item.secretName)</td><td>$($item.EndDateTime)</td><td><span style='color:$color'>$daysUntil Días</span></td></tr>"

}

$Body += "</table></body></html>"

# Convertir el Body a UTF-8 encoding
$BodyBytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
$EncodedBody = [System.Text.Encoding]::UTF8.GetString($BodyBytes)

# Verificar si hay secretos por expirar antes de enviar el correo
if ($array.Count -gt 0) {

    # Split the email target into an array
    $EmailTargets = $EmailTarget -split ','

    # Send emails individually
    foreach ($recipient in $EmailTargets) {
        Send-MailMessage -To $recipient -From $EmailFrom -Subject $EmailSubject -SmtpServer $EmailSMTPServer -Body $EncodedBody -BodyAsHtml -Encoding ([System.Text.Encoding]::UTF8)
    }

}
