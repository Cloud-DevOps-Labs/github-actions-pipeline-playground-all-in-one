terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.68"
    }
  }

  backend "s3" {
    # Estos valores deben ser proporcionados durante terraform init
    bucket         = "NOMBRE_BUCKET_ESTADO" # <<<<<<<<<<<<<<<<<<<<<<<<<  ACTUALIZAR
    region         = "eu-west-1"            # <<<<<<<<<<<<<<<<<<<<<<<<<  ACTUALIZAR (acorde con variables.tf)
    key            = "terraform.tfstate"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Obtener el ID de la cuenta de AWS actual
data "aws_caller_identity" "current" {}

# Bucket para el sitio web
resource "aws_s3_bucket" "website" {
  bucket = "github-actions-pipeline-web-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.bucket

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website" {
  depends_on = [aws_s3_bucket_public_access_block.website]

  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
    ]
  })
}

# Bucket para artefactos
resource "aws_s3_bucket" "artifacts" {
  bucket = "github-actions-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}