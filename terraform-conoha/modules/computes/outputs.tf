output "compute_instance_id" {
  value       = var.on_enabled ? openstack_compute_instance_v2.compute_instance[0].id : null
  description = "Compute instance id"
}