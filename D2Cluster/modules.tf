module "attach_efs_csi_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "efs-csi"
  attach_efs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }
}

################
#  EKS MODULE  #
################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version


  cluster_endpoint_public_access = true

  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  vpc_id                   = aws_vpc.main.id
  subnet_ids               = aws_subnet.private[*].id
  control_plane_subnet_ids = aws_subnet.private[*].id
}


#########################
#  EKS Fargate profile  #
#########################



module "fargate_profile" {
  source = "terraform-aws-modules/eks/aws//modules/fargate-profile"

  name         = var.fargate_profile_name
  cluster_name = module.eks.cluster_name

  subnet_ids = aws_subnet.private[*].id
  selectors = [{
    namespace = var.fargate_profile_namespace
  }]

  tags = {
    Environment = "dev"
    Terraform   = "true"
    project     = var.project_name
  }
}

########################################################################################################################################
#  EKS Fargate profile for core dns- You must enable it if you are only using fargate profile and not using the manged eks node group -#
#########################


module "fargate_profile_coredns" {
  source = "terraform-aws-modules/eks/aws//modules/fargate-profile"

  create       = var.enable_coredns_fargate
  name         = "coredns"
  cluster_name = module.eks.cluster_name

  subnet_ids = aws_subnet.private[*].id
  selectors = [{
    namespace = "kube-system"
  }]

  # depends_on = [
  #   module.fargate_profile.fargate_profile_id
  # ]

  tags = {
    Environment = "dev"
    Terraform   = "true"
    project     = var.project_name
  }
}

module "eks_managed_node_group" {
  source                     = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  create                     = var.create_managed_node_for_eks
  name                       = "separate-eks-mng"
  cluster_name               = module.eks.cluster_name
  cluster_version            = var.cluster_version
  enable_monitoring          = false
  ami_type                   = "AL2_x86_64"
  iam_role_attach_cni_policy = true

  create_launch_template = true

  subnet_ids = aws_subnet.private[*].id

  // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
  // Without it, the security groups of the nodes are empty and thus won't join the cluster.
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]

  // Note: `disk_size`, and `remote_access` can only be set when using the EKS managed node group default launch template
  // This module defaults to providing a custom launch template to allow for custom security groups, tag propagation, etc.
  // use_custom_launch_template = false
  // disk_size = 50
  //
  //  # Remote access cannot be specified with a launch template
  //  remote_access = {
  //    ec2_ssh_key               = module.key_pair.key_pair_name
  //    source_security_group_ids = [aws_security_group.remote_access.id]
  //  }

  min_size     = 1
  max_size     = 3
  desired_size = 2

  instance_types = [var.manged_nodes_instance_type]
  capacity_type  = "SPOT"

  labels = {
    Environment = "test"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  # taints = {
  #   dedicated = {
  #     key    = "dedicated"
  #     value  = "gpuGroup"
  #     effect = "NO_SCHEDULE"
  #   }
  # }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}




################################
#  ROLES FOR SERVICE ACCOUNTS  #
################################

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}


################################
#  RDS Instance  #
################################


module "db" {
  source = "terraform-aws-modules/rds/aws"

  # Disable creation of RDS instance(s)
  create_db_instance = true

  # Disable creation of option group - provide an option group or default AWS default
  create_db_option_group = false

  # Disable creation of parameter group - provide a parameter group or default to AWS default
  create_db_parameter_group = false

  # Enable creation of subnet group (disabled by default)
  create_db_subnet_group = true

  # Enable creation of monitoring IAM role
  create_monitoring_role = true

  identifier                  = var.rds_instance_name
  engine                      = "postgres"
  engine_version              = "15.3"
  family                      = "postgres15" # DB parameter group
  major_engine_version        = "15.6"       # DB option group
  instance_class              = var.rds_instance_class
  allocated_storage           = 5
  max_allocated_storage       = 10
  publicly_accessible         = false
  manage_master_user_password = false

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name  = var.rds_db_name
  username = var.rds_user_name
  password = var.rds_password_name
  port     = 5432


  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.db.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  monitoring_interval  = "30"
  monitoring_role_name = "MyRDSMonitoringRole"


  tags = {
    Environment = "dev"
    Terraform   = "true"
    project     = var.project_name
  }
  subnet_ids = aws_subnet.private[*].id

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]
}


################################
#  Aurora serverless  #
################################



# module "cluster" {
#   source  = "terraform-aws-modules/rds-aurora/aws"

#   create = true

#   #Creation of subnet group - provide a subnet group
#   create_db_subnet_group = true

#   # Disable creation of security group - provide a security group
#   create_security_group = true

#   # Disable creation of monitoring IAM role - provide a role ARN
#   create_monitoring_role = false
#   name           = "aurora-db-postgres"
#   engine         = "aurora-postgresql"
#   engine_version = "15.3"
#   instance_class = "db.t3.micro"
#   instances = {
#     one = {}
#     2 = {
#       instance_class = "db.r6g.large"
#     }
#   }
#   autoscaling_enabled      = true
#   autoscaling_min_capacity = 2
#   autoscaling_max_capacity = 5
#   master_password               = "Password_123"
#   master_username               = "devdbadmin"
#   database_name                 = "postgres"
#   port                          = 5432
#   vpc_id                        = aws_vpc.main.id


#  # db_subnet_group_name = "db-subnet-group"
#   manage_master_user_password = false

#  # subnet_ids             = aws_subnet.private[*].id


#   security_group_rules = {
#     ex1_ingress = {
#       cidr_blocks = [var.cidr]
#     }
#     # ex1_ingress = {
#     #   source_security_group_id = "sg-12345678"
#     # }
#   }

#   storage_encrypted   = true
#   apply_immediately   = true
#   monitoring_interval = 10

#   enabled_cloudwatch_logs_exports = ["postgresql"]

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#     project = var.project_name
#   }
# }



module "aurora" {
  source = "terraform-aws-modules/rds-aurora/aws"

  create = false

  # #Creation of subnet group - provide a subnet group
  # create_db_subnet_group = true

  # Disable creation of security group - provide a security group
  create_security_group = true

  # Disable creation of monitoring IAM role - provide a role ARN
  create_monitoring_role = false

  name                        = var.aurora_instance_name
  engine                      = "aurora-postgresql"
  engine_version              = "15.3"
  master_username             = "devdbadmin"
  master_password             = "Password_123"
  manage_master_user_password = false
  instances = {
    1 = {
      instance_class          = "db.r5.large"
      publicly_accessible     = true
      db_parameter_group_name = "default.aurora-postgresql15"
    }
    #     2 = {
    # #      identifier     = "static-member-1"
    #       instance_class = "db.r5.2xlarge"
    #       publicly_accessible     = true
    #       db_parameter_group_name = "default.aurora-postgresql15"
    #     }
    #     3 = {
    # #      identifier     = "excluded-member-1"
    #       instance_class = "db.r5.2xlarge"
    #       publicly_accessible     = true
    #       db_parameter_group_name = "default.aurora-postgresql15"
    #     }
  }

  # endpoints = {
  #   static = {
  #     identifier     = "static-custom-endpt"
  #     type           = "ANY"
  #     static_members = ["static-member-1"]
  #     tags           = { Endpoint = "static-members" }
  #   }
  #   excluded = {
  #     identifier       = "excluded-custom-endpt"
  #     type             = "READER"
  #     excluded_members = ["excluded-member-1"]
  #     tags             = { Endpoint = "excluded-members" }
  #   }
  # }

  vpc_id               = aws_vpc.main.id
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name

  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = [var.cidr]
    }
    egress_example = {
      cidr_blocks = ["0.0.0.0/0"]
      description = "Egress to outside world"
    }
  }

  apply_immediately   = true
  skip_final_snapshot = true

  create_db_cluster_parameter_group = true

  db_cluster_parameter_group_family      = "aurora-postgresql15"
  db_cluster_parameter_group_description = "${var.aurora_instance_name} example cluster parameter group"
  db_cluster_parameter_group_parameters = [
    {
      name         = "log_min_duration_statement"
      value        = 4000
      apply_method = "immediate"
      }, {
      name         = "rds.force_ssl"
      value        = 1
      apply_method = "immediate"
    }
  ]

  create_db_parameter_group      = true
  db_parameter_group_name        = var.aurora_instance_name
  db_parameter_group_family      = "aurora-postgresql15"
  db_parameter_group_description = "${var.aurora_instance_name} example DB parameter group"
  db_parameter_group_parameters = [
    {
      name         = "log_min_duration_statement"
      value        = 4000
      apply_method = "immediate"
    }
  ]

  enabled_cloudwatch_logs_exports = ["postgresql"]
  create_cloudwatch_log_group     = false

  create_db_cluster_activity_stream = false
  # db_cluster_activity_stream_kms_key_id = module.kms.key_id
  # db_cluster_activity_stream_mode       = "async"

  tags = {
    Environment = "dev"
    Terraform   = "true"
    project     = var.project_name
  }
}
