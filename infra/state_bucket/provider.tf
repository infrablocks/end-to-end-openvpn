provider "aws" {
  region = var.region
  version = "~> 2.61"
}

provider "template" {
  version = "~> 2.1"
}
