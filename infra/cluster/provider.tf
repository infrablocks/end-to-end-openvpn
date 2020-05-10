provider "aws" {
  region = var.region
  version = "~> 2.61"
}

provider "template" {
  version = "~> 2.1"
}

provider "null" {
  version = "~> 2.1"
}
