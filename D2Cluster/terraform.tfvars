## See variables.tf for descriptions

project_name = "d2cluster-terraform"

trusted_network = "172.17.0.3/32"
# AWS provider settings
aws_access_key = "AKIAVDGOWVBNY2E366ON"
aws_secret_key = "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"
aws_region = "us-east-1"
cluster_name = "prathapeks"
cluster_version = "1.26"
fargate_profile_name = "prathapfargateprofile"
fargate_profile_namespace = "prathapfg"
create_managed_node_for_eks = true 
manged_nodes_instance_type = "t3.small"
accesspoints = ["d2classic-vct","d2config-vct","d2rest-vct" , "d2smartview-vct" , "dctm-workflow-designer" ,"records" , "rqm" , "d2classic-shared-logs" , "d2config-shared-logs" , "d2rest-shared-logs" , "d2smartview-shared-logs" , "dcc" , "dtr" , "xplore" , "ijms" ]
rds_db_name = "Postgres"
rds_user_name = "devdbadmin"
rds_password_name = "Password_123"
rds_instance_class = "db.t3.micro"


#public_key = "~/.ssh/id_rsa.pub"
#private_key = "~/.ssh/id_rsa"
