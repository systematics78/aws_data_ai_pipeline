
provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "pharma_inbound" {
  bucket = "pharma-inbound-data"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.pharma_kms.key_id
      }
    }
  }

  tags = {
    GxP       = "True"
    DataType  = "Clinical"
    Retention = "10y"
  }
}

resource "aws_kms_key" "pharma_kms" {
  description             = "KMS key for encrypting pharma S3 data"
  enable_key_rotation     = true
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "pharma_kms_alias" {
  name          = "alias/pharma-data-key"
  target_key_id = aws_kms_key.pharma_kms.id
}
