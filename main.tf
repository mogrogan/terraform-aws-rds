# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "random" {}
provider "null" {}

resource "random_pet" "random" {}

# Mock availability zones
locals {
  mock_azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  region   = var.region
}

# Mock VPC
resource "null_resource" "vpc" {
  triggers = {
    name        = "${random_pet.random.id}-education"
    cidr        = "10.0.0.0/16"
    azs         = jsonencode(local.mock_azs)
    vpc_id      = "vpc-${random_pet.random.id}"
    subnet_ids  = jsonencode([
      "subnet-${random_pet.random.id}-1",
      "subnet-${random_pet.random.id}-2",
      "subnet-${random_pet.random.id}-3"
    ])
  }

  provisioner "local-exec" {
    command = "echo 'Mock VPC created: ${self.triggers.vpc_id}'"
  }
}

# Mock DB subnet group
resource "null_resource" "db_subnet_group" {
  triggers = {
    name       = "${random_pet.random.id}-education"
    subnet_ids = null_resource.vpc.triggers.subnet_ids
  }

  provisioner "local-exec" {
    command = "echo 'Mock DB Subnet Group created: ${self.triggers.name}'"
  }
}

# Mock security group
resource "null_resource" "security_group" {
  triggers = {
    name   = "${random_pet.random.id}-education_rds"
    vpc_id = null_resource.vpc.triggers.vpc_id
    ingress_from_port = 5432
    ingress_to_port   = 5432
    ingress_protocol  = "tcp"
    ingress_cidr      = "192.80.0.0/16"
    sg_id = "sg-${random_pet.random.id}"
  }

  provisioner "local-exec" {
    command = "echo 'Mock Security Group created: ${self.triggers.sg_id}'"
  }
}

# Mock DB parameter group
resource "null_resource" "db_parameter_group" {
  triggers = {
    name   = "${random_pet.random.id}-education"
    family = "postgres16"
    log_connections = "1"
  }

  provisioner "local-exec" {
    command = "echo 'Mock DB Parameter Group created: ${self.triggers.name}'"
  }

  lifecycle {
    create_before_destroy = true
  }
}

ephemeral "random_password" "db_password" {
  length  = 16
  special = false
}

locals {
  db_password_version = 1
}

# Mock RDS instance
resource "null_resource" "rds_instance" {
  triggers = {
    identifier             = "${var.db_name}-${random_pet.random.id}"
    instance_class         = "db.t3.micro"
    allocated_storage      = "5"
    engine                 = "postgres"
    engine_version         = "16"
    username               = var.db_username
    password_version       = local.db_password_version
    db_subnet_group_name   = null_resource.db_subnet_group.triggers.name
    vpc_security_group_ids = null_resource.security_group.triggers.sg_id
    parameter_group_name   = null_resource.db_parameter_group.triggers.name
    endpoint               = "${var.db_name}-${random_pet.random.id}.mock-rds.amazonaws.com:5432"
  }

  provisioner "local-exec" {
    command = "echo 'Mock RDS Instance created: ${self.triggers.endpoint}'"
  }
}

# Mock SSM parameter
resource "null_resource" "ssm_parameter" {
  triggers = {
    name             = "/education/database/${var.db_name}/password/master"
    description      = "Password for RDS database."
    type             = "SecureString"
    value_version    = local.db_password_version
    # Note: We don't store the actual password in triggers for security
    parameter_arn    = "arn:aws:ssm:${local.region}:123456789012:parameter/education/database/${var.db_name}/password/master"
  }

  provisioner "local-exec" {
    command = "echo 'Mock SSM Parameter created: ${self.triggers.name}'"
  }
}

