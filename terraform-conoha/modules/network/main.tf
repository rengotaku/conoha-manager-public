resource "openstack_networking_network_v2" "network_internal" {
  name = "network_internal"
  admin_state_up = "true"

  lifecycle {
    ignore_changes = [name]
  }
}

resource "openstack_networking_subnet_v2" "subnet_internal" {
  network_id = openstack_networking_network_v2.network_internal.id
  cidr = var.private_network_cidr
  ip_version = 4
  # Method not allowed
  enable_dhcp = false
  no_gateway = true

  lifecycle {
    ignore_changes = [name]
  }
}