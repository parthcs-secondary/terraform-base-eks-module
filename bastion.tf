# Find latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 1. IAM Role & Instance Profile for Bastion (SSM + EKS Access)
resource "aws_iam_role" "bastion" {
  name = "hub-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Attach SSM Core policy (enables AWS Session Manager)
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "hub-bastion-instance-profile"
  role = aws_iam_role.bastion.name
}

# 2. Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name        = "hub-bastion-sg"
  description = "Security group for EKS bastion host"
  vpc_id      = module.hub_network.vpc_id

  # Outbound access to fetch packages, talk to AWS APIs, and communicate with EKS
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hub-bastion-sg"
  }
}

# Allow Bastion to communicate with EKS Control Plane (Port 443)
resource "aws_security_group_rule" "bastion_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = module.hub_cluster.cluster_primary_security_group_id
  description              = "Allow HTTPS traffic from Bastion SG to EKS Cluster"
}

# 3. Bastion EC2 Instance
resource "aws_instance" "bastion" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = "c7i-flex.large"
  subnet_id            = module.hub_network.public_subnets[0]
  iam_instance_profile = aws_iam_instance_profile.bastion.name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.bastion.id
  ]

  # Pre-install kubectl, helm, and configure kubeconfig
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y

              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
              rm kubectl

              # Install Helm
              curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

              # Pre-generate kubeconfig for ec2-user and ssm-user
              aws eks update-kubeconfig --region ${var.aws_region} --name ${module.hub_cluster.cluster_name}
              EOF

  tags = {
    Name = "hub-eks-bastion"
  }
}

# 4. EKS Access Entry (Grants Bastion Role Admin Permissions on EKS)
resource "aws_eks_access_entry" "bastion" {
  cluster_name  = module.hub_cluster.cluster_name
  principal_arn = aws_iam_role.bastion.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "bastion_admin" {
  cluster_name  = module.hub_cluster.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.bastion.arn

  access_scope {
    type = "cluster"
  }
}