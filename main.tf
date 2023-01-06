resource "azurerm_resource_group" "example" {
  name     = "myResourceazure"
  location = "West Europe"
}
resource "azurerm_virtual_network" "example" {
  name                = "myVNet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "frontend" {
  name                 = "myAGSubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.0.0/24"]
}
# resource "azurerm_public_ip" "pip1" {
#   name                = "myAGPublicIPAddress"
#   resource_group_name = azurerm_resource_group.example.name
#   location            = azurerm_resource_group.example.location
#   allocation_method   = "Static"
# }
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.example.id
}
resource "azurerm_network_security_group" "example" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  security_rule {
    name                       = "test123"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_windows_virtual_machine_scale_set" "example"{
  name                = "test-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard_F2"
  instances           = 1
  admin_password      = "P@55w0rd1234!"
  admin_username      = "adminuser"
  # custom_data = base64encode(<<CUSTOM_DATA
  # <powershell>
  # # [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Ssl3
  # # [Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"
  # # Invoke-WebRequest -Uri "https://tallymirror.tallysolutions.com/download_centre/Rel_2.1/TP/Full/setup.exe" -OutFile "C:\Users\adminuser\Downloads\setup.exe"
  # New-Item -Path 'C:\Users\adminuser\Downloads\test_folder' -ItemType Directory
  # </powershell>
  # CUSTOM_DATA
  # )
  # custom_data         = filebase64(test.ps1)
  
  # custom_data =  base64encode(""
  #     <powershell>
  #     Invoke-WebRequest -Uri "https://tallymirror.tallysolutions.com/download_centre/Rel_2.1/TP/Full/setup.exe" -OutFile "C:\Users\Administrator\Downloads\setup.exe"
  #     </powershell>
  # )

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                       = "example"
    primary                    = true
    network_security_group_id  = azurerm_network_security_group.example.id
    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.frontend.id     
  
    public_ip_address {
      name                = "root"
    }
    }
  }
  #  provisioner "remote-exec" {
  #   # command = "install.ps1"
  #   # interpreter = ["PowerShell"]
  #   connection {

  #     type     = "winrm"
  #     user     = "adminuser"
  #     password = "P@55w0rd1234!"
  #     timeout  = "5m"
  #     host     = azurerm_public_ip.pip1.ip_address
  #   }
  #   inline = [
  #        "powershell -ExecutionPolicy Unrestricted -File install.ps1"
  #       ]
  # }
  connection {
    host     = "20.126.96.159"
    type     = "winrm"
    port     = 5985
    https    = false
    timeout  = "5m"
    user     = "adminuser"
    password = "P@55w0rd1234!"
  }

  provisioner "file" {
    source      = "install.ps1"
    destination = "C:\\Users\\adminuser\\Downloads\\install_script.ps1"
  }

  provisioner "remote-exec" {
    inline = [
      "PowerShell.exe -ExecutionPolicy Unrestricted C:\\Users\\adminuser\\Downloads\\install_script.ps1",
    ]
  }
}
# resource "null_resource" "VM" {
#   provisioner "file" {
#     source      = "install.ps1"
#     destination = "C:\\Users\\adminuser\\Downloads\\install_script.ps1"

#     connection {
#       type     = "winrm"
#       user     = "adminuser"
#       password = "P@55w0rd1234!"
#       host     = "20.126.96.159"
#       port     = "5985"
#       timeout  = "5m"
#     }
#   }
# }
  
 
# resource "azurerm_network_interface" "nic" {
#   name                = "nic-demo"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
#   ip_configuration {
#     name                          = "nic-ipconfig"
#     subnet_id                     = azurerm_subnet.frontend.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.pip1.id
#   }
# }
# resource "azurerm_network_interface_security_group_association" "example" {
#   network_interface_id      = azurerm_network_interface.nic.id
#   network_security_group_id = azurerm_network_security_group.example.id
# }
resource "azurerm_monitor_autoscale_setting" "example" {
  name                = "myAutoscaleSetting"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.example.id
  profile {
    name = "Weekends"
    capacity {
      default = 1
      minimum = 1
      maximum = 10
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.example.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 90
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "2"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.example.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 10
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "2"
        cooldown  = "PT1M"
      }
    }
    recurrence {
      timezone = "Pacific Standard Time"
      days     = ["Saturday", "Sunday"]
      hours    = [12]
      minutes  = [0]
    }
  }
  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = ["admin@contoso.com"]
    }
  }
}
# resource "tls_private_key" "example" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# 
# resource "azurerm_ssh_public_key" "example" {
#   name                = "example"
#   resource_group_name = azurerm_resource_group.example.name
#   location            = azurerm_resource_group.example.location
#   public_key          = tls_private_key.example.public_key_openssh
#   provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
#     command = "echo '${tls_private_key.example.private_key_pem}' > ./example.pem"
# }
# }           



#   netsh advfirewall set allprofiles state off



resource "azurerm_virtual_machine_scale_set_extension" "example" {
  name                         = "test"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.example.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.0"

  protected_settings = <<SETTINGS
  {
     "commandToExecute": "powershell -encodedCommand ${textencodebase64(file("install.ps1"), "UTF-16LE")}"
  }
  SETTINGS
}