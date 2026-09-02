# providers.tf (Root Directory)

terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket = "tf-state-brightedge"
    key    = "eks/terraform.tfstate"
    region = "ap-south-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "~> 7.0"
    } 
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
}

# Helm Provider Configuration (Uses Hub EKS connection data)
provider "helm" {
  kubernetes {
    host                   = module.hub_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.hub_cluster.cluster_certificate_authority_data)

    # Executes AWS CLI locally to fetch dynamic auth tokens for Hub EKS
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.hub_cluster.cluster_name]
    }
  }
}

# Kubectl Provider Configuration (Used for applying CRDs directly via TF)
provider "kubectl" {
  host                   = module.hub_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.hub_cluster.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.hub_cluster.cluster_name]
  }
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = module.hub_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.hub_cluster.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.hub_cluster.cluster_name]
  }
}