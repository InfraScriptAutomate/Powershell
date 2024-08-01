# Conexión Entra ID
Connect-AzureAD

#Variables
$startDate = Get-Date
#Colocar el # de años que caducarpa el secreto
$endDate = $startDate.AddYears(999)

#Agregar Secreto
$aadappsecret = New-AzureADApplicationPasswordCredential -ObjectId "Object ID App Entra ID" -CustomKeyIdentifier "NombreSecreto" -StartDate $startDate -EndDate $enddate

#Muestra Secreto
$aadappsecret








