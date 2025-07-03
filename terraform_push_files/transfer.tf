
resource "aws_iam_role" "transfer_family_role" {
  name = "TransferS3AccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "transfer.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "transfer_family_policy" {
  name = "TransferAccessPolicy"
  role = aws_iam_role.transfer_family_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
        Resource = [
          aws_s3_bucket.pharma_inbound.arn,
          "${aws_s3_bucket.pharma_inbound.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"],
        Resource = aws_kms_key.pharma_kms.arn
      }
    ]
  })
}

resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED"
  protocols               = ["SFTP"]
  endpoint_type           = "PUBLIC"
  tags = {
    Environment = "Clinical"
  }
}

resource "aws_transfer_user" "clinical_user" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = "clinicaluser"
  role      = aws_iam_role.transfer_family_role.arn
  home_directory = "/${aws_s3_bucket.pharma_inbound.bucket}/raw"

  tags = {
    UserType = "ClinicalUploader"
  }
}
