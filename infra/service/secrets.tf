locals {
  ca_cert_local_path = "../../../config/secrets/pki/ca.crt"
  server_cert_local_path = "../../../config/secrets/pki/issued/${data.template_file.openvpn_server_dns_name.rendered}.crt"
  server_key_local_path = "../../../config/secrets/pki/private/${data.template_file.openvpn_server_dns_name.rendered}.key"
  dh_params_local_path = "../../../config/secrets/pki/dh.pem"
  crl_local_path = "../../../config/secrets/pki/crl.pem"
}

data "template_file" "env_file_object_key" {
  template = "vpn/service/environments/default.env"
}

data "template_file" "ca_cert_object_key" {
  template = "vpn/service/secrets/pki/ca.crt"
}

data "template_file" "server_cert_object_key" {
  template = "vpn/service/secrets/pki/server.crt"
}

data "template_file" "server_key_object_key" {
  template = "vpn/service/secrets/pki/server.key"
}

data "template_file" "dh_params_object_key" {
  template = "vpn/service/secrets/pki/dh2048.pem"
}

data "template_file" "crl_file_object_key" {
  template = "vpn/service/secrets/pki/crl.pem"
}

data "template_file" "env_file_object_path" {
  template = "s3://$${secrets_bucket}/$${environment_object_key}"

  vars = {
    secrets_bucket = var.secrets_bucket_name
    environment_object_key = data.template_file.env_file_object_key.rendered
  }
}

data "template_file" "ca_cert_object_path" {
  template = "s3://$${secrets_bucket}/$${ca_cert_object_key}"

  vars = {
    secrets_bucket = var.secrets_bucket_name
    ca_cert_object_key = data.template_file.ca_cert_object_key.rendered
  }
}

data "template_file" "server_cert_object_path" {
  template = "s3://$${secrets_bucket}/$${server_cert_object_key}"

  vars = {
    secrets_bucket = var.secrets_bucket_name
    server_cert_object_key = data.template_file.server_cert_object_key.rendered
  }
}

data "template_file" "server_key_object_path" {
  template = "s3://$${secrets_bucket}/$${server_key_object_key}"

  vars = {
    secrets_bucket = var.secrets_bucket_name
    server_key_object_key = data.template_file.server_key_object_key.rendered
  }
}

data "template_file" "dh_params_object_path" {
  template = "s3://$${secrets_bucket}/$${dh_params_object_key}"

  vars = {
    secrets_bucket = var.secrets_bucket_name
    dh_params_object_key = data.template_file.dh_params_object_key.rendered
  }
}

data "template_file" "crl_file_object_path" {
  template = "s3://$${secrets_bucket}/$${crl_file_object_key}"

  vars = {
    secrets_bucket = var.secrets_bucket_name
    crl_file_object_key = data.template_file.crl_file_object_key.rendered
  }
}

data "template_file" "additional_server_configuration" {
  template = file("${path.root}/conf-files/server.conf.additional.tpl")

  vars = {}
}

data "template_file" "env" {
  template = file("${path.root}/envfiles/openvpn-server.env.tpl")

  vars = {
    dns_server = cidrhost(data.aws_vpc.vpc.cidr_block, 2)
    remote_ip = cidrhost(var.private_network_cidr, 0)
    remote_mask = cidrnetmask(var.private_network_cidr)
    remote_cidr = var.private_network_cidr
    server_ip = cidrhost(cidrsubnet(data.aws_vpc.vpc.cidr_block, 8, 150), 0)
    server_mask = cidrnetmask(cidrsubnet(data.aws_vpc.vpc.cidr_block, 8, 150))
    server_port = var.openvpn_server_service_container_port
    ca_cert_object_path = data.template_file.ca_cert_object_path.rendered
    server_cert_object_path = data.template_file.server_cert_object_path.rendered
    server_key_object_path = data.template_file.server_key_object_path.rendered
    dh_params_object_path = data.template_file.dh_params_object_path.rendered
    crl_file_object_path = data.template_file.crl_file_object_path.rendered
    additional_configuration = data.template_file.additional_server_configuration.rendered
  }
}

resource "aws_s3_bucket_object" "env" {
  key = data.template_file.env_file_object_key.rendered
  bucket = var.secrets_bucket_name
  content = data.template_file.env.rendered

  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "ca_cert" {
  key = data.template_file.ca_cert_object_key.rendered
  bucket = var.secrets_bucket_name
  source = local.ca_cert_local_path
  etag = filemd5(local.ca_cert_local_path)

  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "server_cert" {
  key = data.template_file.server_cert_object_key.rendered
  bucket = var.secrets_bucket_name
  source = local.server_cert_local_path
  etag = filemd5(local.server_cert_local_path)

  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "server_key" {
  key = data.template_file.server_key_object_key.rendered
  bucket = var.secrets_bucket_name
  source = local.server_key_local_path
  etag = filemd5(local.server_key_local_path)

  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "dh_params" {
  key = data.template_file.dh_params_object_key.rendered
  bucket = var.secrets_bucket_name
  source = local.dh_params_local_path
  etag = filemd5(local.dh_params_local_path)

  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "crl" {
  key = data.template_file.crl_file_object_key.rendered
  bucket = var.secrets_bucket_name
  source = local.crl_local_path
  etag = filemd5(local.crl_local_path)

  server_side_encryption = "AES256"
}
