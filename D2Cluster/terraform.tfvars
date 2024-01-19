## See variables.tf for descriptions

project_name = "d2cluster-terraform"

trusted_network = "172.17.0.3/32"
# AWS  settings
aws_region                = "us-east-1"
cluster_name              = "prathapeks"
cluster_version           = "1.26"
fargate_profile_name      = "prathapfargateprofile"
fargate_profile_namespace = "prathapfg"
# No need to put any values for efs_csi_driver for EFS CSI driver if you are using only fargate and not managed node group. else enter value as "enabled"
efs_csi_drive = "enabled"
# You must enable core dns if you are only using fargate profile and not using the manged eks node group 
enable_coredns_fargate      = false
create_managed_node_for_eks = true
manged_nodes_instance_type  = "t3.small"
accesspoints                = ["d2classic-vct", "d2config-vct", "d2rest-vct", "d2smartview-vct", "dctm-workflow-designer", "records", "rqm", "d2classic-shared-logs", "d2config-shared-logs", "d2rest-shared-logs", "d2smartview-shared-logs", "dcc", "dtr", "xplore", "ijms"]
rds_db_name                 = "Postgres"
rds_user_name               = "devdbadmin"
rds_password_name           = "Password_123"
rds_instance_class          = "db.t3.micro"


#public_key = "~/.ssh/id_rsa.pub"
#private_key = "~/.ssh/id_rsa"
