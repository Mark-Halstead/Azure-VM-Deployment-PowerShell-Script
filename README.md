# Azure VM Deployment Script

This PowerShell script is designed to deploy a virtual machine (VM) in Microsoft Azure, complete with a public IP address. It leverages Azure PowerShell cmdlets to automate the process of setting up the necessary resources, including a virtual network, subnet, network security group, and network interface, before creating the VM itself.

## Prerequisites

Before using this script, ensure you have the following:

- **Azure Subscription**: You must have an active Azure subscription.
- **Azure Cloud Shell Access**: The script is intended to be run in Azure Cloud Shell.
- **Permissions**: You must have the necessary permissions to create and manage resources in your Azure subscription.

## Script Overview

### Variables

The script begins by defining key variables:

- `resourceGroupName`: The name of the resource group where the VM will be deployed.
- `location`: The Azure region where the resources will be created (e.g., "EastUS").
- `vmName`: The name of the virtual machine.
- `adminUsername`: The admin username for the VM.
- `adminPassword`: The password for the admin account.

### Resource Group Creation

If the specified resource group does not already exist, the script creates it.

### Public IP Address

The script creates a dynamic public IP address to be associated with the VM.

### Virtual Network and Subnet

A virtual network and a subnet within that network are created for the VM.

### Network Security Group (NSG)

The script sets up a Network Security Group (NSG) to control traffic to and from the VM.

### Network Interface (NIC)

A network interface is created and associated with the public IP address, subnet, and NSG.

### Virtual Machine Configuration and Deployment

The VM is configured with the specified operating system, size, and network interface, and is then deployed.

### Output

After deployment, the script outputs the public IP address of the VM.

## Usage

1. Open Azure Cloud Shell from the Azure portal or your preferred method.
2. Copy and paste the script into the Cloud Shell, or upload the script file if you have it saved locally.
3. Modify the variable values at the beginning of the script to suit your environment.
4. Run the script by typing `./<scriptname>.ps1` and hitting Enter.

### Example

To deploy a VM named "MyVM" in the "EastUS" region with an admin username of "azureuser", you would modify the script variables as follows:

```powershell
$resourceGroupName = "MyResourceGroup"
$location = "EastUS"
$vmName = "MyVM"
$adminUsername = "azureuser"
$adminPassword = "P@ssw0rd123!"  # Ensure you follow Azure's password policy


Then run the script in Azure Cloud Shell or via a pipeline in Azure DevOps, making sure to configure the right permissions for the Service Principal for your service connection.
