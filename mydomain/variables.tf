variable "default_region" {
  description = "Default AWS region"
  type        = string
  default     = "us-west-1"
}

variable "az1" {
  description = "AWS us-west-1a availabity zone"
  type        = string
  default     = "us-west-1a"
}

variable "public_ip" {
  description = "Your public IP to allow SSH"
  type        = string
}

variable "private_key_path" {
  description = "The directory for the private key"
  type        = string
}

variable "environment" {
  type    = string
  default = "dev"
}

