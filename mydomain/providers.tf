provider "aws" {
  region = var.default_region
}

terraform {
  backend "s3" {
    bucket = "tf-remote-state-files-abc"
    key    = "k8s.tf"
  }
}

