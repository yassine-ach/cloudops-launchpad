
variable "region" {
  type        = string
  description = "AWS region where all resources are created"
  default     = "eu-central-1"
}

variable "cidr_block" {
  type        = string
  description = "IP address range (CIDR block) for the VPC, for example 10.0.0.0/16"
  default     = "10.0.0.0/16"
}

variable "project_name" {
  type        = string
  description = "Project name, used as a prefix in resource names and tags"
  default     = "cloudops-launchpad"
}