# Set variables for the deployment
$resourceGroupName = "{ResourceGroupName}"
$location = "UKSouth"
$vmName = "MyVM"
$adminUsername = "azureuser"
$adminPassword = "P@ssw0rd123!"  # Ensure you follow Azure's password policy

# Create a resource group if it doesn't exist
if (-not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating resource group..."
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}

# Create a public IP address
Write-Host "Creating public IP address..."
$publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName `
    -Name "$vmName-PublicIP" `
    -Location $location `
    -AllocationMethod Dynamic

# Create a virtual network and subnet
Write-Host "Creating virtual network and subnet..."
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name "$vmName-VNet" `
    -AddressPrefix "10.0.0.0/16"

$subnet = Add-AzVirtualNetworkSubnetConfig -Name "$vmName-Subnet" `
    -VirtualNetwork $vnet `
    -AddressPrefix "10.0.1.0/24"

$vnet | Set-AzVirtualNetwork

# Create a network security group
Write-Host "Creating network security group..."
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name "$vmName-NSG"

# Create a NIC (Network Interface)
Write-Host "Creating network interface..."
$nic = New-AzNetworkInterface -Name "$vmName-NIC" `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $publicIp.Id `
    -NetworkSecurityGroupId $nsg.Id

# Create a virtual machine configuration
Write-Host "Creating virtual machine configuration..."
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_DS1_v2" | `
    Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential (New-Object System.Management.Automation.PSCredential($adminUsername, (ConvertTo-SecureString $adminPassword -AsPlainText -Force))) | `
    Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest" | `
    Add-AzVMNetworkInterface -Id $nic.Id

# Create the virtual machine
Write-Host "Deploying virtual machine..."
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

Write-Host "Virtual machine deployment complete."
Write-Host "Public IP Address: $(Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name $publicIp.Name).IpAddress"
