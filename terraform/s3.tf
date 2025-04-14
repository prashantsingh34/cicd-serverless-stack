
resource "aws_s3_bucket" "file_to_be_processed" {
  bucket = "file-to-be-processed-bucket-8874"

}

resource "aws_s3_bucket_server_side_encryption_configuration" "file_to_be_processed_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.file_to_be_processed.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = "alias/aws/s3"
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "cfile_to_be_processed_ownership_control" {
  bucket = aws_s3_bucket.file_to_be_processed.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "file_to_be_processed_public_access_block" {
  bucket = aws_s3_bucket.file_to_be_processed.id

  block_public_acls = true

  ignore_public_acls = true


  block_public_policy = true


  restrict_public_buckets = true
}



## processed bucket

resource "aws_s3_bucket" "processed_file_bucket" {
  bucket = "processed-file-bucket-8874"

}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed_file_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.processed_file_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = "alias/aws/s3"
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "processed_file_bucket_ownership_control" {
  bucket = aws_s3_bucket.processed_file_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "processed_file_bucket_public_access_block" {
  bucket = aws_s3_bucket.processed_file_bucket.id

  block_public_acls = true

  ignore_public_acls = true


  block_public_policy = true


  restrict_public_buckets = true
}
