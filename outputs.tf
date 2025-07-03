
output "s3_bucket_name" {
  value = aws_s3_bucket.pharma_inbound.id
}

output "transfer_server_endpoint" {
  value = aws_transfer_server.sftp_server.endpoint
}
