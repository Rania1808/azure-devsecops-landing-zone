terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

locals {
  project     = "devsecops"
  environment = "dev"
  tags = {
    owner   = "tonnom"
    project = local.project
    env     = local.environment
  }
}

# 1. Groupe de ressources
resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.project}-${local.environment}"
  location = "East US"
  tags     = local.tags
}

# 2. Key Vault avec purge protection
resource "azurerm_key_vault" "kv" {
  name                       = "kv-${local.project}${local.environment}001"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  tags                       = local.tags
}

data "azurerm_client_config" "current" {}

# 3. AKS Zero-Trust
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${local.project}-${local.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-${local.project}-${local.environment}"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = [data.azurerm_client_config.current.object_id]
  }

  network_profile {
    network_plugin = "kubenet"
    network_policy = "calico"
  }

  tags = local.tags
}