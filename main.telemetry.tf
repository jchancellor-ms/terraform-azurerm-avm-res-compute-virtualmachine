resource "random_id" "telemetry" {
  count       = var.enable_telemetry ? 1 : 0
  byte_length = 4
}

# This is the module telemetry deployment that is only created if telemetry is enabled.
# It is deployed to the resource's resource group.
resource "azurerm_resource_group_template_deployment" "telemetry" {
  count               = var.enable_telemetry ? 1 : 0
  name                = local.telem_arm_deployment_name
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"
  template_content    = local.telem_arm_template_content
  tags                = {}
}
