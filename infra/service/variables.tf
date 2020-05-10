variable "region" {}
variable "private_network_cidr" {}

variable "component" {}

variable "deployment_identifier" {}

variable "service_desired_count" {}

variable "openvpn_server_image" {}
variable "openvpn_server_service_container_port" {}
variable "openvpn_server_service_host_port" {}
variable "openvpn_server_service_lb_port" {}
variable "openvpn_server_allow_cidrs" {
  type = list(string)
}

variable "secrets_bucket_name" {}

variable "domain_state_bucket_name" {}
variable "domain_state_key" {}
variable "domain_state_bucket_region" {}
variable "domain_state_bucket_is_encrypted" {}

variable "network_state_bucket_name" {}
variable "network_state_key" {}
variable "network_state_bucket_region" {}
variable "network_state_bucket_is_encrypted" {}

variable "cluster_state_bucket_name" {}
variable "cluster_state_key" {}
variable "cluster_state_bucket_region" {}
variable "cluster_state_bucket_is_encrypted" {}
