provider "azurerm" { }

# Resource group
data "azurerm_resource_group" "test" {
  name     = "RG-Paran"
}

# Log Analytics workspace
data "azurerm_log_analytics_workspace" "test" {
  name                = "ParanOMS"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
  }

# Setting up main network
resource "azurerm_virtual_network" "network" {
  name                = "vmn"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = "${data.azurerm_resource_group.test.name}"

  tags {
    BUC             = "4011.501000.9517..0000.0000.0000"
    AppGroup        = "AppGroupPlaceholder"
    AppGroupEmail   = "AppGroupEmailPlaceholder@fisglobal.com"
    EnvironmentType = "Dev"
    CustomerCRMID   = "FIS {6015}"
    ExpirationDate  = "Never"
  }
}

# Setting up subnet for VM
resource "azurerm_subnet" "network" {
  name                 = "vmsub"
  resource_group_name  = "${data.azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
  address_prefix       = "10.0.2.0/24"
}

# Network interface for VM
resource "azurerm_network_interface" "network" {
  name                = "vmni"
  location            = "eastus"
  resource_group_name = "${data.azurerm_resource_group.test.name}"

  # VM ip type "dynamic"
  ip_configuration {
    name                          = "subnet"
    subnet_id                     = "${azurerm_subnet.network.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags {
    BUC             = "4011.501000.9517..0000.0000.0000"
    AppGroup        = "AppGroupPlaceholder"
    AppGroupEmail   = "AppGroupEmailPlaceholder@fisglobal.com"
    EnvironmentType = "Dev"
    CustomerCRMID   = "FIS {6015}"
    ExpirationDate  = "Never"
  }
}


# VM Creation
resource "azurerm_virtual_machine" "vm1" {
  name                  = "Paranvm"
  location              = "eastus"
  resource_group_name   = "${data.azurerm_resource_group.test.name}"
  network_interface_ids = ["${azurerm_network_interface.network.id}"]
  vm_size               = "Standard_DS1_v2"


  # Specific boot software for VM2
  storage_image_reference {
    publisher = "canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  # Storage HDD for VM
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  # Optional data disks
  storage_data_disk {
    name              = "datadisk_new"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "1023"
  }

  # OS Profile self setting
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    BUC               = "4011.501000.9517..0000.0000.0000"
    AppGroup          = "AppGroupPlaceholder"
    AppGroupEmail     = "AppGroupEmailPlaceholder@fisglobal.com"
    EnvironmentType   = "Dev"
    CustomerCRMID     = "FIS {6015}"
    ExpirationDate    = "Never"
    Tier              = "System"
    MaintenanceWindow = "*/2-5/*/1,3,5,7,9,11/0-6"
    Scheduling        = "Never"
    SLA               = "None"
    SolutionCentralID = "10000490"
  }
}

# Extension for Virtual machine
resource "azurerm_virtual_machine_extension" "test" {
  name                       = "LogAnalytics"
  location                   = "${azurerm_virtual_machine.vm1.location}"
  resource_group_name        = "${data.azurerm_resource_group.test.name}"
  virtual_machine_name       = "${azurerm_virtual_machine.vm1.name}"
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.6"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
	{
	    "workspaceId": "${data.azurerm_log_analytics_workspace.test.workspace_id}"
	}
SETTINGS

  protected_settings = <<protectedsettings
      {
          "workspaceKey" :  "${data.azurerm_log_analytics_workspace.test.primary_shared_key}"
      }
protectedsettings

  depends_on = ["azurerm_virtual_machine.vm1"]

 tags {
    BUC             = "4011.501000.9517..0000.0000.0000"
    AppGroup        = "AppGroupPlaceholder"
    AppGroupEmail   = "AppGroupEmailPlaceholder@fisglobal.com"
    EnvironmentType = "Dev"
    CustomerCRMID   = "FIS {6015}"
    ExpirationDate  = "Never"
  }
}