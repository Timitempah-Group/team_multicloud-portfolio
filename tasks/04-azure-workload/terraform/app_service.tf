# Standard S1 tier -- required for autoscale rules; Basic tier does not
# support autoscaling on App Service Plans.
resource "azurerm_service_plan" "main" {
  name                = "asp-multicloud-task4"
  resource_group_name = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
  location            = "uksouth"
  os_type             = "Linux"
  sku_name            = "S1"

  tags = {
    Project = "multicloud-portfolio"
    Task    = "04-azure-workload"
  }
}

# Runs a well-known public demo image that displays the responding
# container's hostname -- gives the same "which instance answered" proof
# as Task 3's instance-ID page, with no custom image build required.
resource "azurerm_linux_web_app" "main" {
  name                = "app-multicloud-task4"
  resource_group_name = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
  location            = "uksouth"
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image_name   = "nginxdemos/hello:latest"
      docker_registry_url = "https://index.docker.io"
    }
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "04-azure-workload"
  }
}

# Autoscale: min 1, max 3, scales out on CPU > 70 percent -- mirrors the
# ASG's scaling behaviour in Task 3.
resource "azurerm_monitor_autoscale_setting" "main" {
  name                = "autoscale-multicloud-task4"
  resource_group_name = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
  location            = "uksouth"
  target_resource_id  = azurerm_service_plan.main.id

  profile {
    name = "default"

    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "04-azure-workload"
  }
}
