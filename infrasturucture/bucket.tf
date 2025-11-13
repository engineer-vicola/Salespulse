resource "aws_s3_bucket" "transaction" {
  bucket = "sales-project"

  tags = {
    Name        = "transaction"
    Environment = "Production"
  }
}
resource "aws_s3_bucket_versioning" "transaction_versioning" {
  bucket = aws_s3_bucket.transaction.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "transaction_lifecycle" {
  bucket = aws_s3_bucket.transaction.id

  rule {
    id     = "my-bucket-versioning"
    status = "Enabled"

    expiration {
      days = 90
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}