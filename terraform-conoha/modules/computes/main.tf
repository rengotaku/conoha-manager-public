# If you want `count = 0`, you have to remove `jumper_internal_port` from `terraform-conoha/terraform.tfstate`
resource "openstack_compute_instance_v2" "compute_instance" {
  count       = var.on_enabled ? 1 : 0

  name        = var.name
  image_name  = {
    "g-512mb" = "vmi-centos-7.7-amd64-20gb"
    "g-1gb"   = "vmi-centos-7.7-amd64"
  }[var.flavor_name]
  flavor_name = var.flavor_name

  key_pair    = "terraform-keypair" # "openstack_compute_keypair_v2"のnameと合わせる
  power_state = var.power_state_on ? "active" : "shutoff"

  security_groups = var.security_groups

  metadata = {
    instance_name_tag = var.name # ダッシュボード表示名
  }

  lifecycle {
    ignore_changes = [
      name,
      region,
      # security_groups,
      network
    ]
  }
}

resource "openstack_compute_interface_attach_v2" "attache_internal_port" {
  count = var.force_invalid_interface_attach ? 0 : (var.on_enabled ? length(var.network) : 0)
  instance_id = var.on_enabled ? openstack_compute_instance_v2.compute_instance[0].id : null
  port_id     = openstack_networking_port_v2.internal_port[count.index].id
}

resource "openstack_networking_port_v2" "internal_port" {
  count          = var.on_enabled ? length(var.network) : 0
  name           = format("%s-%02d", var.name, count.index + 1)
  network_id     = var.network[count.index].id
  admin_state_up = "true"

  fixed_ip {
    subnet_id = var.network[count.index].subnet_id
    ip_address = var.network[count.index].internal_ip_address
  }

  lifecycle {
    ignore_changes = [name]
  }
}