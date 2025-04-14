resource "aws_dynamodb_table" "image_upload_jobs" {
  name           = "image-upload-jobs"
  billing_mode   = "PAY_PER_REQUEST" 
  hash_key       = "job_id"

  attribute {
    name = "job_id"
    type = "S"
  }

}
