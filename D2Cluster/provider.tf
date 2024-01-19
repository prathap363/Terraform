terraform {
  required_version = "1.6.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.32.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}


provider "aws" {
  region = var.aws_region
  # You can use access keys
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
  # Or specify an aws profile, instead.
  # profile = "<aws profile>"
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}
