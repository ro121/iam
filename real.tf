locals {
  iam_scope                          = "tenant"
  env                                = var.env
  aurora_rds_monitoring_role_name    = "${local.env}-aurora-rds-enhanced-monitoring"
  policy_config_path                 = "iam"
  default_tags = {
    Application = "aurora"
    Component   = "rds-monitoring"
    Environment = local.env
  }
}

module "aurora_rds_monitoring_iam" {
  source        = "git::https://git.web.boeing.com/bds-data-platform/aws/reusable-code/terraform-modules/aws-iam-module.git?ref=main"
  aws_iam_scope = local.iam_scope

  roles = [
    {
      name               = local.aurora_rds_monitoring_role_name
      description        = "RDS Enhanced Monitoring role for Aurora (${local.env})"
      assume_role_services = ["monitoring.rds.amazonaws.com"]
      assume_role_arns   = []
      custom_policies    = ["aurora-rds-monitoring-policy"]
      managed_policies   = ["AmazonRDSEnhancedMonitoringRole"]
      tags               = local.default_tags
    }
  ]

  policies = [
    {
      name        = "aurora-rds-monitoring-policy"
      description = "Additional CloudWatch/SSM permissions for Aurora RDS monitoring"
      file        = "${local.policy_config_path}/aurora-rds-monitoring-policy.json"
      variables   = {}
      tags        = merge(local.default_tags, { Purpose = "aurora-rds-monitoring" })
    }
  ]
}
