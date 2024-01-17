resource "aws_efs_file_system" "dctmefs" {
  creation_token = "eks-efs"
}

resource "aws_efs_mount_target" "mount" {
    count = length(aws_subnet.private.*.id)
    file_system_id = aws_efs_file_system.dctmefs.id
    subnet_id = aws_subnet.private[count.index].id
    security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "access-point" {
  file_system_id = aws_efs_file_system.dctmefs.id

  count = length(var.accesspoints)

  
  tags = {
    Name       = element(var.accesspoints, count.index)
    managed-by = "terraform"
  }
  

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/${element(var.accesspoints, count.index)}"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0777"
    }
  }
}




# resource "helm_release" "aws_efs_csi_driver" {
#   chart      = "aws-efs-csi-driver"
#   name       = "aws-efs-csi-driver"
#   namespace  = "kube-system"
#   repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"

#   set {
#     name  = "image.repository"
#     value = "602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-efs-csi-driver"
#   }

#   set {
#     name  = "controller.serviceAccount.create"
#     value = true
#   }

#   set {
#     name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = module.attach_efs_csi_role.iam_role_arn
#   }

#   set {
#     name  = "controller.serviceAccount.name"
#     value = "efs-csi-controller-sa"
#   }
# }