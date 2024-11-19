$resourceGroupName = Read-Host "rg name"
$vmName = Read-Host "enter vm name"
$location = Read-Host "location (uksouth for example)"

$adminUsername = Read-Host "admin username"
$adminPassword = Read-Host -AsSecureString "admin password"



# resource group creation

$azResourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if ($azResourceGroup -ne $null) {
    Write-Host "Resource group already exists"
} else {
    Write-Host "Creating resource group...."
    New-AzresourceGroup -Name $resourceGroupName -Location $location
}



# public IP address creation

$publicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name "$vmName-PublicIP" -ErrorAction SilentlyContinue
if ($publicIp -ne $null) {
    Write-Host "Public IP already exists"
} else {
    Write-Host "Creating publc IP...."
    $publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name "$vmName-PublicIP" -Location $location -AllocationMethod Static
}





# create vnet and subnet

$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name "$vmName-VNet" -ErrorAction SilentlyContinue

if ($vnet -ne $null) {
    Write-Host "VNet already exists."
} else {
    Write-Host "Creating new VNet...."
    # New
    $vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name "$vmName-VNet" -AddressPrefix "10.0.0.0/16"
    # Add
    $subnet = Add-AzVirtualNetworkSubnetConfig -Name "$vmName-Subnet" -VirtualNetwork $vnet -AddressPrefix "10.0.1.0/24"
    # Set
    $vnet | Set-AzVirtualNetwork
}




# nsg creation

$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name "$vmName-NSG" -ErrorAction SilentlyContinue

if ($nsg -ne $null) {
    Write-Host "nsg already exists"
} else {
    Write-Host "creating nsg...."
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$vmName-NSG"
}




#  Create nic
$nic = Get-AzNetworkInterface -ResourceGroupName $resourceGroupName -Name "$vmName-NIC" -ErrorAction SilentlyContinue

if ($nic -ne null) {
    Write-Host "Network interface already exists."
} else {
    Write-Host "Creating network interface..."
    $nic = New-AzNetworkInterface -Name "$vmName-NIC" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id -NetworkSecurityGroupId $nsg.Id
} 




# create vm configuration

Write-Host "Creating virtual machine configuration..."
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_DS1_v2" | `
    Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential (New-Object System.Management.Automation.PSCredential($adminUsername, (ConvertTo-SecureString $adminPassword -AsPlainText -Force))) | `
    Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest" | `
    Add-AzVMNetworkInterface -Id $nic.Id


# create actual vm
$existingVM = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -ErrorAction SilentlyContinue
if ($existingVM -ne null) {
    Write-Host "VM already exists/."
} else {
    Write-Host "Creating VM...."
    New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig
}



Write-Host "VM deployment Complete."
