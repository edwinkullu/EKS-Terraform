terraform {
  backend "s3" {
    bucket         = "my-fastapi-tfstate-bucket-123456"
    key            = "eks/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "fastapi-terraform-locks"
    encrypt        = true
  }
}
