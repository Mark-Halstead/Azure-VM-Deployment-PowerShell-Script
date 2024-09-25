# Set variables for the deployment using Read-Host
$resourceGroupName = Read-Host "Enter the Resource Group Name"
$location = Read-Host "Enter the Location (e.g., UKSouth)"
$vmName = Read-Host "Enter the Virtual Machine Name"
$adminUsername = Read-Host "Enter the Admin Username"
$adminPassword = Read-Host -AsSecureString "Enter the Admin Password"  # This ensures the password is entered securely

# Create a resource group if it doesn't exist
if (-not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating resource group..."
    New-AzResourceGroup -Name $resourceGroupName -Location $location
} else {
    Write-Host "Resource group already exists."
}

# Create a public IP address if it doesn't exist
$publicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name "$vmName-PublicIP" -ErrorAction SilentlyContinue
if (-not $publicIp) {
    Write-Host "Creating public IP address..."
    $publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName `
        -Name "$vmName-PublicIP" `
        -Location $location `
        -AllocationMethod Static
} else {
    Write-Host "Public IP address already exists."
}

# Create a virtual network and subnet if they don't exist
$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name "$vmName-VNet" -ErrorAction SilentlyContinue
if (-not $vnet) {
    Write-Host "Creating virtual network and subnet..."
    $vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName `
        -Location $location `
        -Name "$vmName-VNet" `
        -AddressPrefix "10.0.0.0/16"

    $subnet = Add-AzVirtualNetworkSubnetConfig -Name "$vmName-Subnet" `
        -VirtualNetwork $vnet `
        -AddressPrefix "10.0.1.0/24"

    $vnet | Set-AzVirtualNetwork
} else {
    Write-Host "Virtual network and subnet already exist."
}

# Create a network security group if it doesn't exist
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name "$vmName-NSG" -ErrorAction SilentlyContinue
if (-not $nsg) {
    Write-Host "Creating network security group..."
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName `
        -Location $location `
        -Name "$vmName-NSG"
} else {
    Write-Host "Network security group already exists."
}

# Create a NIC (Network Interface) if it doesn't exist
$nic = Get-AzNetworkInterface -ResourceGroupName $resourceGroupName -Name "$vmName-NIC" -ErrorAction SilentlyContinue
if (-not $nic) {
    Write-Host "Creating network interface..."
    if ($vnet -eq $null) {
        Write-Host "Error: `$vnet is null or empty. Make sure the virtual network is created before creating the NIC."
    } else {
        $nic = New-AzNetworkInterface -Name "$vmName-NIC" `
            -ResourceGroupName $resourceGroupName `
            -Location $location `
            -SubnetId $vnet.Subnets[0].Id `
            -PublicIpAddressId $publicIp.Id `
            -NetworkSecurityGroupId $nsg.Id
    }
} else {
    Write-Host "Network interface already exists."
}

# Create a virtual machine configuration
Write-Host "Creating virtual machine configuration..."
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_DS1_v2" | `
    Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential (New-Object System.Management.Automation.PSCredential($adminUsername, (ConvertTo-SecureString $adminPassword -AsPlainText -Force))) | `
    Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest" | `
    Add-AzVMNetworkInterface -Id $nic.Id

# Create the virtual machine if it doesn't exist
$existingVM = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -ErrorAction SilentlyContinue
if (-not $existingVM) {
    Write-Host "Deploying virtual machine..."
    New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig
} else {
    Write-Host "Virtual machine already exists."
}

Write-Host "Virtual machine deployment complete."
Write-Host "Public IP Address: $(Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name $publicIp.Name).IpAddress"
