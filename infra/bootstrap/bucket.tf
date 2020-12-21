module "storage_bucket" {
  source = "infrablocks/encrypted-bucket/aws"
  version = "1.5.0"

  bucket_name = var.storage_bucket_name

  allow_destroy_when_objects_present = "yes"

  tags = {
    DeploymentIdentifier = var.deployment_identifier
  }
}
