# Paso 1.- Instalar módulos Az
Install-Module -Name Az -AllowClobber -Force 

# Paso 2.- Permitir ejecución de scripts
Set-ExecutionPolicy RemoteSigned 

# Autenticarse en Azure 
Connect-AzAccount

# Verificar conexión 
Get-AzSubscription 

#Conectarte a una suscripción en específica
Connect-AzAccount | Select-AzSubscription -SubscriptionId "ID-De-Tu-Suscripcion"
