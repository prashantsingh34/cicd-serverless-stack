resource "aws_iam_role" "generate_presigned_url_lambda_role" {
  name        = "generate_presigned_url_lambda_role"
  description = "Role that allow to gernerrate presigned url and logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })


}

resource "aws_iam_role_policy" "generate_presigned_url_lambda_cloudwatch_logs" {
  name = "generate-presigned-url-lambda-cloudwatch-logs"
  role = aws_iam_role.generate_presigned_url_lambda_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:log-group:*:log-stream:*"
      },
      {
        "Effect" : "Allow",
        "Action" : "logs:CreateLogGroup",
        "Resource" : "arn:aws:logs:*:*:log-group:*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "generate_presigned_url_lambda_s3_access" {
  name = "generate-presigned-url-lambda-s3-access"
  role = aws_iam_role.generate_presigned_url_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.file_to_be_processed.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.file_to_be_processed.bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "generate_presigned_url_lambda_dynamo_put_item" {
  name = "generate-presigned-url-lambda-dynamo-put"
  role = aws_iam_role.generate_presigned_url_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
         "dynamodb:PutItem"
        ],
        Resource = [
          aws_dynamodb_table.image_upload_jobs.arn
        ]
      }
    ]
  })
}



resource "aws_iam_role" "presigned_url_role" {
  name = "presigned_url_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "presigned_url_api_invocation_policy" {
  name = "presigned-url-api-invocation-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = [
          aws_lambda_function.generate_presigned_url_lambda.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_presigned_url_role" {
  role       = aws_iam_role.presigned_url_role.name
  policy_arn = aws_iam_policy.presigned_url_api_invocation_policy.arn
}

