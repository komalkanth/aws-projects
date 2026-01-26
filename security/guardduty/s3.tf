# S3 bucket for storing "secure" data
# Configured with encryption and strict access policies
resource "aws_s3_bucket" "secure" {
  bucket_prefix = "${var.stack_name}-secure-"

  tags = {
    Name = "${var.stack_name}-SecureBucket"
  }
}

# Enable server-side encryption with AES256
resource "aws_s3_bucket_server_side_encryption_configuration" "secure" {
  bucket = aws_s3_bucket.secure.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Configure ownership controls for the bucket
resource "aws_s3_bucket_ownership_controls" "secure" {
  bucket = aws_s3_bucket.secure.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "secure" {
  bucket = aws_s3_bucket.secure.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy to deny insecure connections
# Enforces HTTPS/TLS for all S3 operations
resource "aws_s3_bucket_policy" "secure" {
  bucket = aws_s3_bucket.secure.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.secure.arn,
          "${aws_s3_bucket.secure.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.secure]
}
