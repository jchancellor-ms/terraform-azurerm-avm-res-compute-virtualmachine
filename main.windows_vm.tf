resource "azurerm_windows_virtual_machine" "this" {
  count = (lower(var.virtualmachine_os_type) == "windows") ? 1 : 0

  #required properties
  admin_password        = local.admin_password
  admin_username        = var.admin_username
  location              = local.location
  name                  = var.virtualmachine_name
  network_interface_ids = [for interface in azurerm_network_interface.virtualmachine_network_interfaces : interface.id]
  resource_group_name   = data.azurerm_resource_group.virtualmachine_deployment.name
  size                  = var.virtualmachine_sku_size

  os_disk {
    caching                          = var.os_disk.caching
    storage_account_type             = var.os_disk.storage_account_type
    disk_encryption_set_id           = var.os_disk.disk_encryption_set_id
    disk_size_gb                     = var.os_disk.disk_size_gb
    name                             = var.os_disk.name
    secure_vm_disk_encryption_set_id = var.os_disk.secure_vm_disk_encryption_set_id
    security_encryption_type         = var.os_disk.security_encryption_type
    write_accelerator_enabled        = var.os_disk.write_accelerator_enabled

    dynamic "diff_disk_settings" {
      for_each = var.os_disk.diff_disk_settings == null ? [] : ["diff_disk_settings"]

      content {
        option    = var.os_disk.diff_disk_settings.option
        placement = var.os_disk.diff_disk_settings.placement
      }
    }
  }

  #optional properties
  allow_extension_operations                             = var.allow_extension_operations
  availability_set_id                                    = var.availability_set_resource_id
  bypass_platform_safety_checks_on_user_schedule_enabled = var.bypass_platform_safety_checks_on_user_schedule_enabled
  capacity_reservation_group_id                          = var.capacity_reservation_group_resource_id
  computer_name                                          = coalesce(var.computer_name, var.virtualmachine_name)
  custom_data                                            = var.custom_data
  dedicated_host_id                                      = var.dedicated_host_resource_id
  dedicated_host_group_id                                = var.dedicated_host_group_resource_id
  edge_zone                                              = var.edge_zone
  enable_automatic_updates                               = var.enable_automatic_updates
  encryption_at_host_enabled                             = var.encryption_at_host_enabled
  eviction_policy                                        = var.eviction_policy
  extensions_time_budget                                 = var.extensions_time_budget
  hotpatching_enabled                                    = var.hotpatching_enabled
  license_type                                           = var.license_type
  max_bid_price                                          = var.max_bid_price
  patch_assessment_mode                                  = var.patch_assessment_mode
  patch_mode                                             = var.patch_mode
  platform_fault_domain                                  = var.platform_fault_domain
  priority                                               = var.priority
  provision_vm_agent                                     = var.provision_vm_agent
  proximity_placement_group_id                           = var.proximity_placement_group_resource_id
  reboot_setting                                         = var.reboot_setting
  secure_boot_enabled                                    = var.secure_boot_enabled
  source_image_id                                        = var.source_image_resource_id
  tags                                                   = local.tags
  timezone                                               = var.timezone
  user_data                                              = var.user_data
  virtual_machine_scale_set_id                           = var.virtual_machine_scale_set_resource_id
  vtpm_enabled                                           = var.vtpm_enabled
  zone                                                   = var.zone

  dynamic "additional_capabilities" {
    for_each = var.vm_additional_capabilities == null ? [] : ["additional_capabilities"]

    content {
      ultra_ssd_enabled = var.vm_additional_capabilities.ultra_ssd_enabled
    }
  }

  dynamic "additional_unattend_content" {
    for_each = {
      for content in var.additional_unattend_contents : sha256(content) => content
    }

    content {
      content = additional_unattend_content.value.content
      setting = additional_unattend_content.value.setting
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics ? ["boot_diagnostics"] : []

    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  dynamic "gallery_application" {
    for_each = { for app in var.gallery_applications : app.version_id => app }

    content {
      version_id             = gallery_application.value.version_id
      configuration_blob_uri = gallery_application.value.configuration_blob_uri
      order                  = gallery_application.value.order
      tag                    = gallery_application.value.tag
    }
  }

  dynamic identity {
    for_each = local.managed_identity_type == null ? [] : ["identity"]
      content{
        type         = local.managed_identity_type
        identity_ids = var.managed_identities.user_assigned_resource_ids
      }
  }

  dynamic "plan" {
    for_each = var.plan == null ? [] : ["plan"]

    content {
      name      = var.plan.name
      product   = var.plan.product
      publisher = var.plan.publisher
    }
  }

  dynamic "secret" {
    for_each = toset(var.secrets)

    content {
      key_vault_id = secret.value.key_vault_id

      dynamic "certificate" {
        for_each = secret.value.certificate

        content {
          url = certificate.value.url
          store = certificate.value.store
        }
      }
    }
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_resource_id == null ? ["source_image_reference"] : []

    content {
      publisher = local.source_image_reference.publisher
      offer     = local.source_image_reference.offer
      sku       = local.source_image_reference.sku
      version   = local.source_image_reference.version
    }
  }

  dynamic "termination_notification" {
    for_each = var.termination_notification == null ? [] : [
      "termination_notification"
    ]

    content {
      enabled = var.termination_notification.enabled
      timeout = var.termination_notification.timeout
    }
  }

  dynamic "winrm_listener" {
    for_each = { for listener in var.winrm_listeners : sha256(listener) => listener }

    content {
      protocol        = winrm_listener.value.protocol
      certificate_url = winrm_listener.value.certificate_url
    }
  }

}

  resource "azurerm_management_lock" "this-windows-virtualmachine" {
    count      = var.lock.kind != "None" &&  (lower(var.virtualmachine_os_type) == "windows")  ? 1 : 0
    name       = coalesce(var.lock.name, "lock-${var.virtualmachine_name}")
    scope      = azurerm_windows_virtual_machine.this[0].id
    lock_level = var.lock.kind
  }
