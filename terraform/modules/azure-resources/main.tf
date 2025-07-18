terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.90.0"
    }

  }
}

# Create a Resource Group
resource "azurerm_resource_group" "rg_iac" {
  name     = var.azure_resource_group
  location = var.azure_location
}

# tls for ssh key
resource "tls_private_key" "linux_vm_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}


resource "azurerm_ssh_public_key" "example" {
  name                = var.azure_server_key_pair_name
  resource_group_name = azurerm_resource_group.rg_iac.name
  location            = azurerm_resource_group.rg_iac.location
  public_key          = tls_private_key.linux_vm_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.linux_vm_key.private_key_pem
  filename          = "./${var.azure_server_key_pair_name}.pem"
  file_permission   = "0400"
}

/*
# save key in our machine
resource "azurerm_ssh_public_key" "example" {
  name                = var.azure_server_key_pair_name
  resource_group_name = azurerm_resource_group.rg_iac.name
  location            = azurerm_resource_group.rg_iac.location
  public_key          = tls_private_key.linux_vm_key.public_key_openssh
  provisioner "local-exec"{
  command = "echo '${tls_private_key.linux_vm_key.private_key_pem}' > ./${var.azure_server_key_pair_name}.pem"
}
}

resource "local_sensitive_file" "private_key_pem" {
  content         = tls_private_key.linux_vm_key.private_key_pem
  filename        = "./${var.azure_server_key_pair_name}.pem"
  file_permission = "0400"
}
*/
# Create a VNet
resource "azurerm_virtual_network" "vnet_1" {
  resource_group_name = azurerm_resource_group.rg_iac.name
  name                = var.azure_vnet_name
  address_space       = [var.azure_vnet_cidr]
  location            = azurerm_resource_group.rg_iac.location
}

# Create a Subnet
resource "azurerm_subnet" "subnet_1" {
  address_prefixes     = [var.azure_subnet_cidr]
  resource_group_name  = azurerm_resource_group.rg_iac.name
  virtual_network_name = azurerm_virtual_network.vnet_1.name
  name                 = var.azure_subnet_name
  depends_on = [
    azurerm_virtual_network.vnet_1
  ]
}

# Create a Public IP
resource "azurerm_public_ip" "ip_1" {
  allocation_method = "Static"
  name = "public_ip_1"
  resource_group_name = azurerm_resource_group.rg_iac.name
  location = azurerm_resource_group.rg_iac.location
  sku                 = "Standard"
}

# Create a Network Interface
resource "azurerm_network_interface" "nic_1" {
  name                = "nic_1"
  location            = azurerm_resource_group.rg_iac.location
  resource_group_name = azurerm_resource_group.rg_iac.name
  ip_configuration {
    name                          = "nic_ip"
    subnet_id                     = azurerm_subnet.subnet_1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.azure_private_ip
    public_ip_address_id = azurerm_public_ip.ip_1.id
  }
  depends_on = [
    azurerm_virtual_network.vnet_1,
    azurerm_public_ip.ip_1
  ]
}
data "template_file" "apache_install" {
    template = file("/root/infoblox-lab/Infoblox-PoC/scripts/azure-user-data.sh")
}

# Create a Network Security Group
resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_resource_group.rg_iac.location
  resource_group_name = azurerm_resource_group.rg_iac.name
}

# Allow ICMP traffic
resource "azurerm_network_security_rule" "allow_icmp" {
  name                        = "allow-icmp"
  priority                    = 1002  # Adjust the priority as needed
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = [
    "10.0.0.0/8",
    "20.113.88.59/32",
  ]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_iac.name
  network_security_group_name = azurerm_network_security_group.example.name
}

# Allow TCP port 5000 traffic
resource "azurerm_network_security_rule" "allow_tcp_5000" {
  name                        = "allow-tcp-5000"
  priority                    = 1001  # Adjust the priority as needed
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5000"
  source_address_prefixes     = [
    "10.0.0.0/8",
    "20.113.88.59/32",
  ]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_iac.name
  network_security_group_name = azurerm_network_security_group.example.name
}

# Allow SSH traffic
resource "azurerm_network_security_rule" "allow_ssh" {
  name                    = "allow-ssh"
  priority                = 1003  # Adjust the priority as needed
  direction               = "Inbound"
  access                  = "Allow"
  protocol                = "Tcp"
  source_port_range       = "*"
  destination_port_range  = "22"
  source_address_prefixes = [
    "0.0.0.0/0",
  ]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_iac.name
  network_security_group_name = azurerm_network_security_group.example.name
}

  # Allow UDP port 5201 traffic
resource "azurerm_network_security_rule" "allow_udp_5201" {
  name                        = "allow-udp-5201"
  priority                    = 1004  # Adjust the priority as needed
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "5201"
  source_address_prefixes     = [
    "10.0.0.0/8",
    "20.113.88.59/32",
  ]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_iac.name
  network_security_group_name = azurerm_network_security_group.example.name
}

  # Allow TCP port 5201 traffic
resource "azurerm_network_security_rule" "allow_tcp_5201" {
  name                    = "allow-tcp-5201"
  priority                = 1005  # Adjust the priority as needed
  direction               = "Inbound"
  access                  = "Allow"
  protocol                = "Tcp"
  source_port_range       = "*"
  destination_port_range  = "5201"
  source_address_prefixes = [
    "10.0.0.0/8",
    "20.113.88.59/32",
  ]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_iac.name
  network_security_group_name = azurerm_network_security_group.example.name
}

# Associate the NSG with the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id    = azurerm_network_interface.nic_1.id
  network_security_group_id = azurerm_network_security_group.example.id
}


# Create a VM
resource "azurerm_linux_virtual_machine" "vm_1" {
  name                = var.azure_instance_name
  location            = azurerm_resource_group.rg_iac.location
  resource_group_name = azurerm_resource_group.rg_iac.name
  size             = var.azure_vm_size
  network_interface_ids = [azurerm_network_interface.nic_1.id]
  admin_username = "linuxuser"
  custom_data = base64encode(data.template_file.apache_install.rendered)
  admin_ssh_key {
    username   = "linuxuser"
    public_key = tls_private_key.linux_vm_key.public_key_openssh
  }
  os_disk {
  caching = "ReadWrite"
  storage_account_type = "Standard_LRS"
  }

  source_image_reference {
  publisher = "Canonical"
  offer = "UbuntuServer"
  sku = "18.04-LTS"
  version = "latest"
  }
  
  depends_on = [
    azurerm_network_interface.nic_1,
    tls_private_key.linux_vm_key
  ]

}
