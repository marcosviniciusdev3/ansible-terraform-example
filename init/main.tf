resource "aws_s3_bucket" "terraform" {
  bucket              = "tf-remote-state-files-abc"
  object_lock_enabled = true
  tags = {
    Name        = "remote-state-files"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}
