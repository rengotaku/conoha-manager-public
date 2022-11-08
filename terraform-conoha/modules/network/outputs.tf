output "network_id" {
  value       = openstack_networking_network_v2.network_internal.id
  description = "Internal network id"
}
output "subnet_id" {
  value       = openstack_networking_subnet_v2.subnet_internal.id
  description = "Internal network's subnet id"
}
