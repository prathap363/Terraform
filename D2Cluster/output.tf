output "cluster-endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster-certificate-authority-data" {
  value = module.eks.cluster_certificate_authority_data
}

output "EFSID" {
  value = aws_efs_file_system.dctmefs.id
}

output "RDSDBAddress" {
  value = module.db.db_instance_address
}

output "RDSDBEndPoint" {
  value = module.db.db_instance_endpoint
}

output "AuroraEndPoint" {
  value = module.aurora.cluster_endpoint
}

output "AuroraDBName" {
  value = module.aurora.cluster_database_name
}

output "AccessPoint-Mapping" {
  value = { for s in aws_efs_access_point.access-point : substr(s.root_directory[0].path, 1, -1) => s.id }
}