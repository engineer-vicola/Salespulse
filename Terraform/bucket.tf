#create a s3 bucket

resource "aws_s3_bucket" "transaction" {
  bucket = "faker-project"

  tags = {
    Name        = "transaction"
    Environment = "Production"
  }
}