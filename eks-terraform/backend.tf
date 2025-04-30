terraform {
  backend "s3" {
    bucket         = aws_s3_bucket.tfstate_bucket.bucket
    key            = "eks/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = aws_dynamodb_table.tfstate_lock_table.name
    encrypt        = true
  }
}
