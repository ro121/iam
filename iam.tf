
data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

locals {

  rds_monitoring_iam_path = "/tenant_iac_bound/"

  rds_monitoring_role_name = "${var.env}-rds-enhanced-monitoring-role"

  rds_permissions_boundary_arn = var.permissions_boundary_policy_name == null ? null : (
    "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary_policy_name}"
  )

  rds_enhanced_monitoring_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

##############################
# Assume-role policy document
##############################

data "aws_iam_policy_document" "rds_monitoring_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

##############################
# The external IAM role
##############################

resource "aws_iam_role" "rds_monitoring_external" {
  name               = local.rds_monitoring_role_name
  description        = "External RDS Enhanced Monitoring execution role"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume_role.json

  path = local.rds_monitoring_iam_path


  tags = merge(
    {
      "Name" = local.rds_monitoring_role_name
    },
    var.common_tags
  )
}

##############################
# Attach AWS-managed policy
##############################

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_monitoring_external.name
  policy_arn = local.rds_enhanced_monitoring_policy_arn
}

##############################
# OPTIONAL – attach custom policy
##############################

# Custom policy (content from policies/rds-monitoring-custom.json)
resource "aws_iam_policy" "rds_monitoring_custom" {
  name        = "${var.env}-rds-monitoring-custom"
  description = "Custom additional permissions for RDS monitoring role"
  policy      = file("${path.module}/policies/rds-monitoring-custom.json")
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_custom_attachment" {
  role       = aws_iam_role.rds_monitoring_external.name
  policy_arn = aws_iam_policy.rds_monitoring_custom.arn
}

##############################
# Output – used by Aurora module
##############################

output "rds_monitoring_role_arn" {
  description = "ARN of the external RDS monitoring role"
  value       = aws_iam_role.rds_monitoring_external.arn
}




variable "secret_arns" {
  description = "List of Secrets Manager ARNs that Tenant_DevOps_Engineer can read"
  type        = list(string)
}


secret_arns = [
  "arn:aws-us-gov:secretsmanager:us-gov-west-1:109342086299:secret:lakehouse/db/password-*",
  "arn:aws-us-gov:secretsmanager:us-gov-west-1:109342086299:secret:lakehouse/api/key-*"
]


resource "aws_iam_policy" "tenant_secretsmanager_read" {
  name        = "tenant-devops-engineer-secrets-read"
  description = "Read-only access to specific Secrets Manager secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadSpecificSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secret_arns
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = "Tenant_DevOps_Engineer"
  policy_arn = aws_iam_policy.tenant_secretsmanager_read.arn
}

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadSpecificSecret",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws-us-gov:secretsmanager:us-gov-west-1:109342086299:secret:globaltenant1-mssql-dev-db-Creds-*"
    }
  ]
}



resource "aws_iam_role" "tenant_devops_role" {
  count = length(data.aws_iam_role.tenant_devops_role.id) == 0 ? 1 : 0  # Only create if not found

  name               = "Tenant_DevOps_Engineer"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAssumeRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  lifecycle {
    prevent_destroy = true  # Prevent Terraform from destroying the role
  }
}
