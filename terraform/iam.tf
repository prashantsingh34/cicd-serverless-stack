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

  tags = module.tags.tags

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
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.file_to_be_processed.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.file_to_be_processed.bucket}/*"
        ]
      }
    ]
  })
}

