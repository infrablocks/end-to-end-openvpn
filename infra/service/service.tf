data "template_file" "openvpn_server_dns_name" {
  template = "$${component}-$${deployment_label}.$${domain}"

  vars = {
    component = var.component
    deployment_label = var.deployment_identifier
    domain = data.terraform_remote_state.domain.outputs.domain_name
  }
}

data "template_file" "openvpn_server_task_container_definitions" {
  template = file("${path.root}/container-definitions/openvpn-server.json.tpl")

  vars = {
    env_file_object_path = data.template_file.env_file_object_path.rendered
    container_port = var.openvpn_server_service_container_port
    host_port = var.openvpn_server_service_host_port
  }
}

module "openvpn_server_service" {
  source  = "infrablocks/ecs-service/aws"
  version = "3.2.0"

  component = var.component
  deployment_identifier = var.deployment_identifier

  region = var.region
  vpc_id = data.aws_vpc.vpc.id

  service_task_container_definitions = data.template_file.openvpn_server_task_container_definitions.rendered

  service_name = "${var.component}-${var.deployment_identifier}"
  service_image = var.openvpn_server_image
  service_port = var.openvpn_server_service_container_port

  service_desired_count = var.service_desired_count
  service_deployment_maximum_percent = 200
  service_deployment_minimum_healthy_percent = 50

  service_elb_name = aws_elb.openvpn_server.name

  ecs_cluster_id = data.terraform_remote_state.cluster.outputs.ecs_cluster_id
  ecs_cluster_service_role_arn = data.terraform_remote_state.cluster.outputs.ecs_service_role_arn
}
