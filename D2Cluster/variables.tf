#######################################################
#### Variables to configure (or be prompted about) ####
#######################################################

# Your IP address, so that you will be whitelisted against security groups
variable "trusted_network" {
  description = "CIDR formatted IP (<IP Address>/32) or network that will be allowed access (you can use 0.0.0.0/0 for unrestricted access)"
}

# General name tag that will be given to spun up instances
variable "project_name" {
  description = "An idenfitying name used for names of cloud resources"
}

variable "aws_access_key" {
  description = "AWS access key"
}

variable "aws_secret_key" {
  description = "AWS secret key"
}

#######################################################
######### Variables you may want to configure #########
#######################################################

# Region to set up ece in
variable "aws_region" {
  # default = "us-east-1"
}

# The name of the AMI in the AWS Marketplace
variable "aws_ami_name" {
  # default = "CentOS Linux 7 x86_64 HVM*"
  # For ubuntu, uncomment this
  default = "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
}

# The owner of the AMI
variable "aws_ami_owner" {
  # default = "679593333241" # centos.org
  # For ubuntu, uncomment this
  default = "099720109477" # Canonical
}

# User to log in to instances and perform install
# This is dependent upon the AMI you use, so make sure these are in sync. For example, an Ubuntu AMI would use the ubuntu user
variable "remote_user" {
  # default = "centos"
  # For ubuntu, uncomment this
  default = "ubuntu"
}

# Desired AZs, must have 3.
variable "zones" {
  type    = list(string)
  default = ["a","b","c"]
}

# Path to your public key, which will be used to log in to ece instances
variable "public_key" {
  default = "~/.ssh/id_rsa.pub"
}

# Path to your private key that matches your public from ^^
variable "private_key" {
  default = "~/.ssh/id_rsa"
}

#######################################################
#### Editable ECE installation-specific variables #####
#######################################################

# Ece version to be installed by ansible
# Must be supported by the ansible playbook
variable "ece-version" {
  default="2.5.0"
}

# Time (sec) to wait for cloud instances to come
# up before running the ece installer (ansible)
variable "sleep-timeout" {
  default="30"
}

# ECE instances's VPC & Subnet cidr
variable "cidr" {
  default = "192.168.0.0/16"
}

variable "cidr-public" {
  default = "192.168.0.0/17"
}

variable "cidr-private" {
  default = "192.168.128.0/17"
}

# ECE instance type
variable "aws_instance_type" {
  default = "i3.xlarge"
}

# The device name of the non-root volume that will be used by ECE
# For i3 instances, this is nvme0n1.
# If you use a different instance type, this value will change and might also require changes to the resource definition in servers.tf
variable "cluster_name" {
  description = "An idenfitying name used for names of eks cluster resources"
}

variable "cluster_version" {
  description = "Kubernets version to be used for creating EKS cluster"
}

variable "fargate_profile_name" {
  description = "Kubernets fargate profile name to be used for creating fargate configs in EKS cluster"
}

variable "fargate_profile_namespace" {
  description = "Kubernets fargate profile namespace to be used for creating fargate configs in EKS cluster"
}

variable "accesspoints" {
  type    = list(string)
  default = ["dcs","dbr","dcc"]
}

# Aurora DB instance name
variable "aurora_instance_name" {
  default = "postgres15"
}

# RDS DB instance name
variable "rds_instance_name" {
  default = "postgres15"
}

# RDS DB  name
variable "rds_db_name" {
  default = "postgres"
}

# RDS DB user name
variable "rds_user_name" {
  default = "postgres"
}

# RDS DB password
variable "rds_password_name" {
  default = "Password_123"
}

# RDS DB instance class
variable "rds_instance_class" {
  default = "db.t3.micro"
}






