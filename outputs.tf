# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "region" {
  description = "AWS region for all resources."
  value       = var.region
}

output "rds_hostname" {
  description = "RDS instance hostname."
  value       = null_resource.rds_instance.triggers.endpoint
}

output "rds_port" {
  description = "RDS instance port."
  value       = "5432"
  sensitive   = true
}

output "rds_dbname" {
  description = "RDS instance database name."
  value       = var.db_name
  sensitive   = true
}

output "rds_username" {
  description = "RDS instance root username."
  value       = var.db_username
  sensitive   = true
}

output "vpc_id" {
  description = "Mock VPC ID."
  value       = null_resource.vpc.triggers.vpc_id
}

output "security_group_id" {
  description = "Mock Security Group ID."
  value       = null_resource.security_group.triggers.sg_id
}

output "subnet_ids" {
  description = "Mock Subnet IDs."
  value       = jsondecode(null_resource.vpc.triggers.subnet_ids)
}
