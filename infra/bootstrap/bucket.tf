module "state_bucket" {
  source = "infrablocks/encrypted-bucket/aws"
  version = "1.5.0"

  bucket_name = var.storage_bucket_name

  tags = {
    DeploymentIdentifier = var.deployment_identifier
  }
}
