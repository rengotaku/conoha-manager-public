variable "user_name" {
  description = "OpenStack user name"
  type = string
}
variable "password" {
  description = "OpenStack password"
  type = string
}
variable "tenant_name" {
  description = "OpenStack tenant name"
  type = string
}
variable "public_key" {
  description = "OpenStack public key"
  type = string
}

#network variables
locals {
  private_network_cidr = "0.0.0.0/24"
}
