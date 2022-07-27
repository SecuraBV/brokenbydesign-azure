data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

provider "azurerm" {
  skip_provider_registration = true
  features {
    key_vault {
      recover_soft_deleted_key_vaults = false
      purge_soft_delete_on_destroy    = true
    }
  }
}

resource "azurerm_resource_group" "vulnerable" {
  name     = "SuperCompany"
  location = var.default_location
}

resource "azurerm_storage_account" "vuln_storage_account" {
  name                     = "supercompanystorage"
  resource_group_name      = azurerm_resource_group.vulnerable.name
  location                 = var.default_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "vuln_storage_container" {
  name                  = "storagecontainer"
  storage_account_name  = azurerm_storage_account.vuln_storage_account.name
  container_access_type = "container"
}

resource "azurerm_storage_blob" "website_logo" {
  name                   = "logo.png"
  storage_account_name   = azurerm_storage_account.vuln_storage_account.name
  storage_container_name = azurerm_storage_container.vuln_storage_container.name
  type                   = "Block"
  source                 = "files/logo.png"
}

resource "azuread_application" "vuln_application" {
  display_name = "Very important and secure application"

  provisioner "local-exec" {
    command = "cat files/key.pem | sed -e 's/APP_ID_HERE/${azuread_application.vuln_application.application_id}/g' -e 's/TENANT_ID_HERE/${data.azurerm_client_config.current.tenant_id}/g' > files/temp.pem"
  }
}

resource "azuread_service_principal" "vuln_application" {
  application_id               = azuread_application.vuln_application.application_id
  app_role_assignment_required = false
  owners                       = [data.azurerm_client_config.current.object_id]

  feature_tags {
    enterprise = true
    gallery    = true
  }
}

resource "azuread_directory_role" "vuln_application" {
  display_name = "Directory readers"
}

resource "azuread_directory_role_member" "vuln_application" {
  member_object_id = azuread_service_principal.vuln_application.id
  role_object_id   = azuread_directory_role.vuln_application.id
}

resource "azuread_application_certificate" "vuln_application_cert" {
  application_object_id = azuread_application.vuln_application.id
  type                  = "AsymmetricX509Cert"
  value                 = file("files/cert.pem")
  end_date              = "2032-03-14T14:36:57Z"
}

resource "azurerm_storage_blob" "private_key" {
  name                   = "SECURA{C3RT1F1C3T3}.pem"
  storage_account_name   = azurerm_storage_account.vuln_storage_account.name
  storage_container_name = azurerm_storage_container.vuln_storage_container.name
  type                   = "Block"
  source                 = "files/temp.pem"
}


# Azure function stuff
resource "azurerm_resource_group" "devops_function" {
  name     = "azure-func-rg-secura"
  location = var.default_location
}

resource "azurerm_storage_account" "devops_storage_acc" {
  name                     = "securafuncstor"
  resource_group_name      = azurerm_resource_group.devops_function.name
  location                 = azurerm_resource_group.devops_function.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "devops_service_plan" {
  name                = "azure-functions-secura-sp"
  location            = azurerm_resource_group.devops_function.location
  resource_group_name = azurerm_resource_group.devops_function.name
  os_type             = "Windows"
  sku_name            = "F1"
}

resource "azurerm_windows_function_app" "devops_func_app" {
  name                       = "af-secura"
  location                   = azurerm_resource_group.devops_function.location
  resource_group_name        = azurerm_resource_group.devops_function.name
  service_plan_id            = azurerm_service_plan.devops_service_plan.id
  storage_account_name       = azurerm_storage_account.devops_storage_acc.name
  storage_account_access_key = azurerm_storage_account.devops_storage_acc.primary_access_key

  site_config {}
}

resource "null_resource" "publish_function" {
  depends_on = [
    azurerm_windows_function_app.devops_func_app
  ]

  provisioner "local-exec" {
    command = "cd files/function;sleep 60;func azure functionapp publish af-secura --force"
  }
}

# Database stuff
resource "azurerm_resource_group" "db" {
  name     = "secura-db-rg"
  location = var.default_location # Change this to West Europe when subscription allows this
}

resource "azurerm_storage_account" "db" {
  name                     = "securadbstorageacc"
  resource_group_name      = azurerm_resource_group.db.name
  location                 = azurerm_resource_group.db.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_numeric      = 3
  min_lower        = 3
  min_upper        = 3
  min_special      = 1
}

resource "azurerm_mssql_server" "db" {
  name                         = "securavulnerableserver"
  resource_group_name          = azurerm_resource_group.db.name
  location                     = azurerm_resource_group.db.location
  version                      = "12.0"
  administrator_login          = "Th1sUs3rn4m3!sUnh4ck4bl3"
  administrator_login_password = random_password.password.result
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_firewall_rule" "db" {
  name             = "All Access"
  server_id        = azurerm_mssql_server.db.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

resource "azurerm_mssql_database" "db" {
  depends_on = [
    azurerm_mssql_firewall_rule.db # We need the firewall rule to be applied otherwise we cannot execute the sqlcmd's from the local machine
  ]

  name         = "securavulnerabledb"
  server_id    = azurerm_mssql_server.db.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 1
  sku_name     = "Basic"

  provisioner "local-exec" {
    command = "sleep 60;sqlcmd -S securavulnerableserver.database.windows.net -U Th1sUs3rn4m3!sUnh4ck4bl3 -P ${random_password.password.result} -d master -i files/sql_create_user.sql; sqlcmd -S securavulnerableserver.database.windows.net -U Th1sUs3rn4m3!sUnh4ck4bl3 -P ${random_password.password.result} -d securavulnerabledb -i files/sql_setup.sql"
  }
}

# Azure DevOps account
resource "azuread_user" "vuln_devops_user" {
  user_principal_name         = "devops@secvulnapp.onmicrosoft.com"
  display_name                = "DevOps"
  password                    = "SECURA{D4F4ULT_P4SSW0RD}"
  disable_password_expiration = true
  disable_strong_password     = true
  office_location             = "Password temp changed to SECURA{D4F4ULT_P4SSW0RD}"
}

resource "azurerm_role_definition" "devops_role_def" {
  name        = "DevOps reader"
  description = "Allow DevOps users to read some resources for development purpose"
  scope       = azurerm_resource_group.devops_function.id

  permissions {
    actions = [
      "Microsoft.Web/sites/*"
    ]
    not_actions = [
      "*/write",
      "*/delete",
      "microsoft.web/apimanagementaccounts/apis/connections/listsecrets/action",
      "Microsoft.Web/containerApps/listsecrets/action",
      "Microsoft.Web/staticSites/listsecrets/action",
      "microsoft.web/sites/config/snapshots/listsecrets/action",
      "microsoft.web/sites/slots/config/snapshots/listsecrets/action",
      "microsoft.web/sites/slots/functions/listsecrets/action",
      "microsoft.web/sites/functions/listsecrets/action",
      "microsoft.web/apimanagementaccounts/apis/connections/listconnectionkeys/action",
      "microsoft.web/serverfarms/firstpartyapps/keyvaultsettings/read",
      "microsoft.web/serverfarms/firstpartyapps/keyvaultsettings/write",
      "microsoft.web/connections/listConnectionKeys/action",
      "microsoft.web/connections/revokeConnectionKeys/action",
      "Microsoft.Web/staticSites/resetapikey/Action",
      "microsoft.web/sites/hostruntime/functions/keys/read",
      "Microsoft.Web/sites/hostruntime/host/_master/read",
      "microsoft.web/sites/slots/functions/listkeys/action",
      "microsoft.web/sites/slots/functions/keys/write",
      "microsoft.web/sites/slots/functions/keys/delete",
      "microsoft.web/sites/slots/host/listkeys/action",
      "microsoft.web/sites/slots/host/functionkeys/write",
      "microsoft.web/sites/slots/host/functionkeys/delete",
      "microsoft.web/sites/slots/host/systemkeys/write",
      "microsoft.web/sites/slots/host/systemkeys/delete",
      "microsoft.web/sites/host/listkeys/action",
      "microsoft.web/sites/host/functionkeys/write",
      "microsoft.web/sites/host/functionkeys/delete",
      "microsoft.web/sites/host/systemkeys/write",
      "microsoft.web/sites/host/systemkeys/delete",
      "microsoft.web/sites/functions/listkeys/action",
      "microsoft.web/sites/functions/keys/write",
      "microsoft.web/sites/functions/keys/delete",
      "microsoft.web/sites/functions/masterkey/read",
      "microsoft.web/sites/hybridconnectionnamespaces/relays/listkeys/action",
      "Microsoft.Web/sites/config/list/Action",
      "Microsoft.Web/sites/slots/config/list/Action"
    ]
  }

  assignable_scopes = [
    azurerm_resource_group.devops_function.id
  ]
}

resource "azurerm_role_assignment" "devops_role_assignment" {
  scope              = azurerm_resource_group.devops_function.id
  role_definition_id = split("|", azurerm_role_definition.devops_role_def.id)[0] # For some reason this is broken? See https://github.com/hashicorp/terraform-provider-azurerm/issues/8426
  principal_id       = azuread_user.vuln_devops_user.id
}
