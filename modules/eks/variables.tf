variable "cluster_name" {
  type        = string
  description = "Name of the EKS Cluster"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.36"
  description = "Kubernetes control plane version"
}

variable "node_instance_type" {
  type        = string
  default     = "c7i-flex.large"
  description = "EC2 instance type for worker nodes"
}

variable "min_nodes" {
  type        = number
  default     = 1
}

variable "max_nodes" {
  type        = number
  default     = 3
}

variable "desired_nodes" {
  type        = number
  default     = 2
}

# Network Ingestion Inputs
variable "vpc_id" {
  type        = string
  description = "VPC ID where the cluster will be created"
}

variable "private_subnets" {
  type        = list(string)
  description = "Subnet IDs where worker nodes will reside"
}

variable "intra_subnets" {
  type        = list(string)
  description = "Subnet IDs where EKS control plane ENIs will reside"
}