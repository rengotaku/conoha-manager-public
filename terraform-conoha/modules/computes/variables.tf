variable "name" {
  description = "Compute name"
  type        = string
}

variable "on_enabled" {
  description = "Compute enable state"
  type        = bool
  default     = false
}

variable "flavor_name" {
  description = "Compute flavor_name(g-512mb, g-1gb)"
  type        = string
  default     = "g-512mb"
}

# If displaied error like below:
# Error: Error retrieving openstack_compute_interface_attach_v2 xxx-xxx/xxx-xxx: Internal Server Error
variable "force_invalid_interface_attach" {
  description = "Compute interface attach is invalid forcely"
  type        = bool
  default     = false
}

variable "power_state_on" {
  description = "Compute power state"
  type        = bool
  default     = false
}

variable "security_groups" {
  description = "Compute security groups"
  type        = list(string)
  default     = ["default"]
}

variable "network" {
  description = "Compute network data"
  type = list(object({
    id = string
    subnet_id = string
    internal_ip_address = string
  }))
}
