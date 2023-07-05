# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default     = "10.1.0.0/16"
}
variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default     = "10.1.0.0/24"
}

variable "environment_tag" {
  description = "Environment tag"
  default     = "Production"
}

variable "region"{
  description = "The region Terraform deploys instance"
  default = "eu-north-1"
  # default = "us-east-2"  
}

variable "availability_zone" {
  default = "eu-north-1a"    
  # default = "us-east-2a"  
}

