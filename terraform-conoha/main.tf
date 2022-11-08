terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" {
  user_name   = var.user_name
  password    = var.password
  tenant_name = var.tenant_name
  auth_url    = "https://identity.tyo1.conoha.io/v2.0"
}

module "network" {
  source = "./modules/network"
  private_network_cidr = local.private_network_cidr
}

resource "openstack_compute_keypair_v2" "keypair" {
  count = 1
  name       = "terraform-keypair"    # 好きな名前
  public_key = var.public_key
}

resource "openstack_networking_secgroup_v2" "secgroup_jumper_ssh" {
  name        = "secgroup_jumper_ssh"
  description = "secgroup_jumper_ssh"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_ssh_from_jumper" {
  count = 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/32"
  security_group_id = openstack_networking_secgroup_v2.secgroup_jumper_ssh.id
}

resource "openstack_networking_secgroup_v2" "secgroup_database" {
  name        = "secgroup_database"
  description = "secgroup_database"
  delete_default_rules = true
}
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_mysql" {
  count = 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_ip_prefix  = "0.0.0.0/24"
  security_group_id = openstack_networking_secgroup_v2.secgroup_database.id
}

resource "openstack_networking_secgroup_v2" "secgroup_proxy_http" {
  name        = "secgroup_proxy_http"
  description = "secgroup_proxy_http"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_proxy_http" {
  count = 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/24"
  security_group_id = openstack_networking_secgroup_v2.secgroup_proxy_http.id
}

resource "openstack_networking_secgroup_v2" "secgroup_zabbix_agent" {
  name        = "secgroup_zabbix_agent"
  description = "secgroup_zabbix_agent"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_zabbix_agent" {
  count = 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10051
  port_range_max    = 10051
  remote_ip_prefix  = "0.0.0.0/24"
  security_group_id = openstack_networking_secgroup_v2.secgroup_zabbix_agent.id
}

module "compute_web-proxy" {
  source = "./modules/computes"

  on_enabled = true
  name = "web-proxy"
  flavor_name = "g-512mb"
  power_state_on = true

  security_groups = [
    "default",
    "gncs-ipv4-web",
    openstack_networking_secgroup_v2.secgroup_jumper_ssh.name
  ]

  network = [{
    id = module.network.network_id
    subnet_id = module.network.subnet_id
    internal_ip_address = "0.0.0.0"
  }]
}

module "compute_sachie_wordpress" {
  source = "./modules/computes"

  on_enabled = false
  name = "sachie-blog-wordpress"
  flavor_name = "g-512mb"
  power_state_on = true

  security_groups = [
    "default",
    "gncs-ipv4-web",
    openstack_networking_secgroup_v2.secgroup_jumper_ssh.name
  ]

  network = [{
    id = module.network.network_id
    subnet_id = module.network.subnet_id
    internal_ip_address = "0.0.0.0"
  }]
}

module "compute_database" {
  source = "./modules/computes"

  on_enabled = false
  name = "database"
  flavor_name = "g-1gb"
  power_state_on = true

  security_groups = [
    "default",
    openstack_networking_secgroup_v2.secgroup_database.name,
    openstack_networking_secgroup_v2.secgroup_jumper_ssh.name
  ]

  network = [{
    id = module.network.network_id
    subnet_id = module.network.subnet_id
    internal_ip_address = "0.0.0.0"
  }]
}

module "compute_zabbix_server" {
  source = "./modules/computes"

  on_enabled = false
  name = "zabbix_server"
  flavor_name = "g-512mb"
  power_state_on = true
  # force_invalid_interface_attach = true

  security_groups = [
    "default",
    openstack_networking_secgroup_v2.secgroup_jumper_ssh.name,
    openstack_networking_secgroup_v2.secgroup_proxy_http.name,
    openstack_networking_secgroup_v2.secgroup_zabbix_agent.name
  ]

  network = [{
    id = module.network.network_id
    subnet_id = module.network.subnet_id
    internal_ip_address = "0.0.0.0"
  }]
}

# apply count = 1 and power_state = 'shutoff'
# assignment static ip(150.95.166.25) using '追加IPアドレス' in Conoha control panel
# add allowed-port 22, 80, 443, 3306 in Conoha control panel
# apply power_state = 'active'
module "compute_jumper" {
  source = "./modules/computes"

  on_enabled = true
  name = "jumper"
  flavor_name = "g-512mb"
  power_state_on = true

  security_groups = [
    "default",
    "gncs-ipv4-ssh",
    "gncs-ipv4-web"
  ]

  network = [{
    id = module.network.network_id
    subnet_id = module.network.subnet_id
    internal_ip_address = "0.0.0.0"
  }]
}
