# Configure the Microsoft Azure Provider
provider "azurerm" {
    version = "~>2.0"
    features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "DeepDriver_ResourceGroup" {
    name     = "DeepDriver_ResourceGroup"
    location = "westeurope"

    tags = {
        environment = "DeepDriver_TerraformInfrastructure"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "DeepDriver_Network" {
    name                = "DeepDriver_Network"
    address_space       = ["10.0.0.0/16"]
    location            = "westeurope"
    resource_group_name = azurerm_resource_group.DeepDriver_ResourceGroup.name

    tags = {
        environment = "DeepDriver_TerraformInfrastructure"
    }
}

# Create subnet
resource "azurerm_subnet" "DeepDriver_subnet" {
    name                 = "DeepDriver_subnet"
    resource_group_name  = azurerm_resource_group.DeepDriver_ResourceGroup.name
    virtual_network_name = azurerm_virtual_network.DeepDriver_Network.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "DeepDriver_publicip" {
    name                         = "DeepDriver_publicip"
    location                     = "westeurope"
    resource_group_name          = azurerm_resource_group.DeepDriver_ResourceGroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "DeepDriver_TerraformInfrastructure"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "DeepDriver_NetworkSecurityGroup" {
    name                = "DeepDriver_NetworkSecurityGroup"
    location            = "westeurope"
    resource_group_name = azurerm_resource_group.DeepDriver_ResourceGroup.name
    
    security_rule {
        name                       = "RDPandWINRMandCarla"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges     = ["3389","5985","2000","2001","2002"]
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "DeepDriver_TerraformInfrastructure"
    }
}

# Create network interface
resource "azurerm_network_interface" "DeepDriver_NIC" {
    name                      = "DeepDriver_NIC"
    location                  = "westeurope"
    resource_group_name       = azurerm_resource_group.DeepDriver_ResourceGroup.name

    ip_configuration {
        name                          = "DeepDriver_NIC_Configuration"
        subnet_id                     = azurerm_subnet.DeepDriver_subnet.id
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = azurerm_public_ip.DeepDriver_publicip.id
    }

    tags = {
        environment = "DeepDriver_TerraformInfrastructure"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "Binding" {
    network_interface_id      = azurerm_network_interface.DeepDriver_NIC.id
    network_security_group_id = azurerm_network_security_group.DeepDriver_NetworkSecurityGroup.id
                                
}

// # Generate random text for a unique storage account name
// resource "random_id" "randomId" {
//     keepers = {
//         # Generate a new ID only when a new resource group is defined
//         resource_group = azurerm_resource_group.DeepDriver_ResourceGroup.name
//     }
    
//     byte_length = 8
// }

// # Create storage account for boot diagnostics
// resource "azurerm_storage_account" "DeepDriver_storageaccount" {
//     name                        = "diag${random_id.randomId.hex}"
//     resource_group_name         = azurerm_resource_group.DeepDriver_ResourceGroup.name
//     location                    = "westeurope"
//     account_tier                = "Standard"
//     account_replication_type    = "LRS"

//     tags = {
//         environment = "DeepDriver_TerraformInfrastructure"
//     }
// }

# Create Virtual Machine
resource "azurerm_windows_virtual_machine" "DeepDriverVM" {
    name                  = "DeepDriverVM"
    location              = "westeurope"
    resource_group_name   = azurerm_resource_group.DeepDriver_ResourceGroup.name
    network_interface_ids = [azurerm_network_interface.DeepDriver_NIC.id]
    size                  = "Standard_NC6_PROMO" 
    # https://docs.microsoft.com/de-de/azure/virtual-machines/nc-series?toc=/azure/virtual-machines/linux/toc.json&bc=/azure/virtual-machines/linux/breadcrumb/toc.json
    computer_name         = "DeepDriverVM"
    admin_username        = "azureuser"
    admin_password        = "P@$$w0rd1234!"

    os_disk {
        name              = "DeepDriver_OsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
        # https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types
    }

    // source_image_reference {
    //     publisher = "MicrosoftWindowsDesktop"
    //     offer     = "Windows-10"
    //     sku       = "rs5-pro"
    //     version   = "latest"
    // }

    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.DeepDriver_storageaccount.primary_blob_endpoint
    }

    timeouts {
        create = "60m"
        read = "60m"
    }

    tags = {
        environment = "DeepDriver_TerraformInfrastructure"
    }
}

# Virtual Machine Extension to Deploy Software
 resource "azurerm_virtual_machine_extension" "Download" {
    depends_on           = [azurerm_windows_virtual_machine.DeepDriverVM]

    name                 = "Powershell-Extension-Download"
    virtual_machine_id   = azurerm_windows_virtual_machine.DeepDriverVM.id
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"
    settings = <<SETTINGS
        {
            "fileUris": [
            "https://raw.githubusercontent.com/pcbl/DeepDriver/master/Infrastructure/Azure/CarlaServer/DeploySoftware.ps1",
            "https://raw.githubusercontent.com/pcbl/DeepDriver/master/Infrastructure/Azure/CarlaServer/DeployPostConfig.ps1",
            ]
        }
SETTINGS

    timeouts {
        create = "60m"
        read = "60m"
        update = "60m"
        delete = "60m"
    }

 }

 # Virtual Machine Extension to Deploy Software
 resource "azurerm_virtual_machine_extension" "InstallPostConfig" {
    depends_on           = [azurerm_windows_virtual_machine.DeepDriverVM]

    name                 = "Powershell-Extension-InstallPostConfig"
    virtual_machine_id   = azurerm_windows_virtual_machine.DeepDriverVM.id
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"
    settings = <<SETTINGS
        {
            "commandToExecute": "powershell.exe -ExecutionPolicy bypass -Command ./DeployPostConfig.ps1"
        }
SETTINGS

    timeouts {
        create = "60m"
        read = "60m"
        update = "60m"
        delete = "60m"
    }

 }

  # Virtual Machine Extension to Deploy Software
 resource "azurerm_virtual_machine_extension" "InstallDeploySoftware" {
    depends_on           = [azurerm_windows_virtual_machine.DeepDriverVM]

    name                 = "Powershell-Extension-InstallDeploySoftware"
    virtual_machine_id   = azurerm_windows_virtual_machine.DeepDriverVM.id
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"
    settings = <<SETTINGS
        {
            "commandToExecute": "powershell.exe -ExecutionPolicy bypass -Command ./DeploySoftware.ps1"
        }
SETTINGS

    timeouts {
        create = "60m"
        read = "60m"
        update = "60m"
        delete = "60m"
    }

 }