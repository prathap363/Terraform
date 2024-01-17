provider "aws" {
  region  = var.aws_region

  # You can use access keys
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  # Or specify an aws profile, instead.
  # profile = "<aws profile>"
}

# data "aws_eks_cluster" "this" {
#   name = module.eks.cluster_name
# }

# data "aws_eks_cluster_auth" "this" {
#   name = module.eks.cluster_name
# }

# # data "aws_eks_cluster_auth_certificate "this" {
# #   certificate = module.eks.cluster_certificate_authority_data
# # }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.this.endpoint
#     token                  = data.aws_eks_cluster_auth.this.token
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
#   }
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.this.endpoint
#   token                  = data.aws_eks_cluster_auth.this.token
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.aws_eks_cluster_auth_certificate)
# }


# provider "helm" {
#   kubernetes {
#     host                   = module.eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
#       command     = "aws"
#     }
#   }
# }