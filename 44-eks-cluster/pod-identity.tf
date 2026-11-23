# One IAM role per controller. EKS Pod Identity hands the role to the pods of one service account.
locals {
  pod_roles = {
    ebs-csi          = { namespace = "kube-system", service_account = "ebs-csi-controller-sa" }
    lb-controller    = { namespace = "kube-system", service_account = "aws-load-balancer-controller" }
    external-secrets = { namespace = "external-secrets", service_account = "external-secrets" }
    ssm-reader       = { namespace = "default", service_account = "ssm-reader" }
    karpenter        = { namespace = "kube-system", service_account = "karpenter" }
  }
  parameter_arn = "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/roboshop/*"
}

resource "aws_iam_role" "pod" {
  for_each = local.pod_roles
  name     = "${var.cluster_name}-${each.key}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = ["sts:AssumeRole", "sts:TagSession"]
      Principal = { Service = "pods.eks.amazonaws.com" }
    }]
  })
}

# ebs-csi gets its association from the add-on itself (main.tf)
resource "aws_eks_pod_identity_association" "main" {
  for_each        = { for k, v in local.pod_roles : k => v if k != "ebs-csi" }
  cluster_name    = aws_eks_cluster.main.name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = aws_iam_role.pod[each.key].arn
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.pod["ebs-csi"].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "http" "lb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.6.3/docs/install/iam_policy.json"
}

resource "aws_iam_role_policy" "lb_controller" {
  name   = "lb-controller"
  role   = aws_iam_role.pod["lb-controller"].id
  policy = data.http.lb_controller_policy.response_body
}

resource "aws_iam_role_policy" "ssm_read" {
  for_each = toset(["external-secrets", "ssm-reader"])
  name     = "ssm-read"
  role     = aws_iam_role.pod[each.value].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
      Resource = local.parameter_arn
    }]
  })
}

# A shorter version of the policy in Karpenter's getting-started CloudFormation.
# Fine for a lab; production should use the scoped one from the Karpenter docs.
resource "aws_iam_role_policy" "karpenter" {
  name = "karpenter"
  role = aws_iam_role.pod["karpenter"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances", "ec2:CreateFleet", "ec2:CreateLaunchTemplate", "ec2:CreateTags",
          "ec2:TerminateInstances", "ec2:DeleteLaunchTemplate",
          "ec2:DescribeCapacityReservations", "ec2:DescribeImages", "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus", "ec2:DescribeInstanceTypeOfferings", "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates", "ec2:DescribePlacementGroups", "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory", "ec2:DescribeSubnets", "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter", "pricing:GetProducts", "eks:DescribeCluster",
          "iam:CreateInstanceProfile", "iam:TagInstanceProfile", "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile", "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile", "iam:ListInstanceProfiles",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.node.arn
      },
    ]
  })
}
