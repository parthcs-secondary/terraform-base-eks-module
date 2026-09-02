module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  # Ingests values directly from external variables
  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.intra_subnets

  cluster_endpoint_public_access = true

  # Managed Node Group
  eks_managed_node_groups = {
    default = {
      min_size       = var.min_nodes
      max_size       = var.max_nodes
      desired_size   = var.desired_nodes
      instance_types = [var.node_instance_type]
    }
  }

  # Enable OIDC Provider for ServiceAccounts / IRSA
  enable_irsa = true
}