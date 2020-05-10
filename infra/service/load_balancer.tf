resource "aws_elb" "openvpn_server" {
  subnets = data.terraform_remote_state.network.outputs.public_subnet_ids

  internal = false

  security_groups = [
    aws_security_group.openvpn_server.id
  ]

  listener {
    instance_port = var.openvpn_server_service_host_port
    instance_protocol = "tcp"
    lb_port = var.openvpn_server_service_lb_port
    lb_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:${var.openvpn_server_service_host_port}"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 60
  connection_draining = true
  connection_draining_timeout = 60

  tags = {
    Name = "elb-${var.component}-${var.deployment_identifier}"
    Component = var.component
    DevelopmentIdentifier = var.deployment_identifier
    Service = "web"
  }
}

resource "aws_security_group" "openvpn_server" {
  name = "elb-${var.component}-${var.deployment_identifier}"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  description = "${var.component}-elb"

  ingress {
    from_port = var.openvpn_server_service_lb_port
    to_port = var.openvpn_server_service_lb_port
    protocol = "tcp"
    cidr_blocks = var.openvpn_server_allow_cidrs
  }

  egress {
    from_port = 1
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = [
      data.aws_vpc.vpc.cidr_block
    ]
  }
}

resource "aws_route53_record" "public" {
  zone_id = data.terraform_remote_state.domain.outputs.public_zone_id
  name = data.template_file.openvpn_server_dns_name.rendered
  type = "A"

  alias {
    name = aws_elb.openvpn_server.dns_name
    zone_id = aws_elb.openvpn_server.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "private" {
  zone_id = data.terraform_remote_state.domain.outputs.private_zone_id
  name = data.template_file.openvpn_server_dns_name.rendered
  type = "A"

  alias {
    name = aws_elb.openvpn_server.dns_name
    zone_id = aws_elb.openvpn_server.zone_id
    evaluate_target_health = false
  }
}
