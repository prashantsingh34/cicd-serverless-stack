resource "aws_lambda_function" "generate_presigned_url_lambda" {

  function_name    = "presigned_url-lambda"
  role             = aws_iam_role.generate_presigned_url_lambda_role.arn
  handler          = "presigned_url.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 128
  layers           = [aws_lambda_layer_version.python_deps_layer.arn]
  filename         = data.archive_file.presigned_url_zip.output_path
  source_code_hash = data.archive_file.presigned_url_zip.output_base64sha256
  SOURCE_BUCKET    = aws_s3_bucket.file_to_be_processed.bucket

}

data "archive_file" "presigned_url_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/presigned_url.py"
  output_path = "/tmp/presigned_url.zip"
}

resource "aws_lambda_layer_version" "python_deps_layer" {
  filename            = "layer.zip"
  layer_name          = "dependency_layer"
  source_code_hash    = filebase64sha256("layer.zip")
  compatible_runtimes = ["python3.11"]
}