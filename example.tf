module "aurora_postgres" {
  source = "git::https://git.web.boeing.com/ecs-catalog/iac/terraform-aws-rds-aurora-postgres.git//.?ref=1.4.0"

  # ... your existing variables ...

  # IMPORTANT: this is what disables IAM creation inside the Aurora module
  # and makes it use our external role instead.
  monitoring_role_arn = module.aurora_rds_monitoring_iam.role_arns[local.aurora_rds_monitoring_role_name]
}
