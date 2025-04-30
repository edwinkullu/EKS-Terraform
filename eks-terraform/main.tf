provider "aws" {
  region = "ap-south-1"
}

locals {
  cluster_name = "fastapi-cluster"
}

# Create S3 bucket for storing Terraform state
resource "aws_s3_bucket" "tfstate_bucket" {
  bucket = "my-fastapi-tfstate-bucket-123456" # Make sure the name is globally unique
  acl    = "private"

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Dev"
  }
}

# Create DynamoDB table for state locking
resource "aws_dynamodb_table" "tfstate_lock_table" {
  name           = "fastapi-terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

# VPC setup (unchanged)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name                 = "fastapi-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["ap-south-1a"]
  private_subnets      = ["10.0.1.0/24"]
  public_subnets       = ["10.0.101.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

# EKS Cluster setup (unchanged)
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = local.cluster_name
  cluster_version = "1.27"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
    }
  }
}

# EKS kubeconfig generation (unchanged)
module "eks_kubeconfig" {
  source     = "hyperbadger/eks-kubeconfig/aws"
  version    = "1.0.0"
  cluster_id = module.eks.cluster_id
  depends_on = [module.eks]
}

resource "local_file" "kubeconfig" {
  content  = module.eks_kubeconfig.kubeconfig
  filename = "kubeconfig_${local.cluster_name}"
}
