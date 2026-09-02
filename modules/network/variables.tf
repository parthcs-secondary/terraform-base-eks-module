variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones"
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR ranges for private subnets"
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR ranges for public subnets"
}

variable "intra_subnets" {
  type        = list(string)
  description = "CIDR ranges for control plane intra subnets"
}