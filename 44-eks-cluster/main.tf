data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

# us-east-1e does not support EKS, so stay in a, b and c
data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c"]
  }
}

resource "aws_ec2_tag" "elb" {
  for_each    = toset(data.aws_subnets.main.ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "karpenter_subnet" {
  for_each    = toset(data.aws_subnets.main.ids)
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.k8s_version
  role_arn = aws_iam_role.cluster.arn

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = data.aws_subnets.main.ids
  }

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

resource "aws_ec2_tag" "karpenter_sg" {
  resource_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = data.aws_subnets.main.ids
  capacity_type   = "SPOT"
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  depends_on = [aws_iam_role_policy_attachment.node]
}

resource "aws_eks_addon" "main" {
  for_each     = toset(["vpc-cni", "coredns", "kube-proxy", "eks-pod-identity-agent", "metrics-server"])
  cluster_name = aws_eks_cluster.main.name
  addon_name   = each.value
  depends_on   = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "ebs" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"

  pod_identity_association {
    role_arn        = aws_iam_role.pod["ebs-csi"].arn
    service_account = "ebs-csi-controller-sa"
  }

  depends_on = [aws_eks_addon.main]
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "node_role_name" {
  value = aws_iam_role.node.name
}
