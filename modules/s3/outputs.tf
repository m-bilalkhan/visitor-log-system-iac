output "s3_bucket_id" {
  description = "The ID of the S3 bucket"
  value       = data.aws_s3_bucket.this.id
}