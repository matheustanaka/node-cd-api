resource "aws_s3_bucket" "server-infra-backup" {
  bucket = "server-infra-backup"

  force_destroy = true

  tags = {
    IAC = true
  }
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.server-infra-backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

