# 1. Provision Network for Hub Cluster
module "hub_network" {
  source = "./modules/network"

  vpc_name           = "hub-vpc"
  vpc_cidr           = var.hub_vpc_cidr
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  intra_subnets      = ["10.0.201.0/24", "10.0.202.0/24"]
}

# 2. Provision Hub EKS Cluster
module "hub_cluster" {
  source = "./modules/eks"

  cluster_name       = var.hub_cluster_name
  kubernetes_version = "1.36"
  vpc_id             = module.hub_network.vpc_id
  private_subnets    = module.hub_network.private_subnets
  intra_subnets      = module.hub_network.intra_subnets
  node_instance_type = "c7i-flex.large"
  min_nodes          = 1
  max_nodes          = 3
  desired_nodes      = 2
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }

  depends_on = [module.hub_cluster]
}

# 3. Deploy cert-manager for cluster webhook certificate management
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "oci://quay.io/jetstack/charts"
  chart            = "cert-manager"
  version          = var.cert_manager_chart_version
  namespace        = "cert-manager"
  create_namespace = true

  depends_on = [module.hub_cluster]

  values = [
    <<-EOT
    crds:
      enabled: true
    EOT
  ]
}

# 4. Deploy ArgoCD Control Plane onto Hub Cluster via Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true

  # Ensure chart installation waits for EKS node group readiness
  depends_on = [module.hub_cluster]

  values = [
    <<-EOT
    global:
      domain: argocd.internal.local
    server:
      service:
        type: ClusterIP
    configs:
      params:
        server.insecure: true
    EOT
  ]
}

# STEP 4: Register GitHub Repository via GitHub App
# resource "kubernetes_secret" "github_app_org_credentials" {
#   metadata {
#     name      = "org-github-app-creds"
#     namespace = "argocd"
#     labels = {
#       "argocd.argoproj.io/secret-type" = "repo-creds" # Org-wide credential template
#     }
#   }

#   data = {
#     type                    = "git"
#     url                     = var.github_org_url
#     githubAppID             = var.github_app_id
#     githubAppInstallationID = var.github_app_installation_id
#     githubAppPrivateKey     = var.github_app_private_key
#   }

#   depends_on = [helm_release.argocd]
# }
