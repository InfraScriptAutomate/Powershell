# Importar módulos necesarios
Import-Module Az.Compute
Import-Module Az.Resources

# Variables
$resourceGroupName = "yourResourceGroupName"
$vmName = "yourVMName"

# Iniciar la máquina virtual
Start-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

# Mensaje de salida
Write-Output "La máquina v

irtual $vmName en el grupo de recursos $resourceGroupName ha sido iniciada."