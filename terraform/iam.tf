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
          "arn:aws:s3:::${aws_s3_bucket.file_to_be_processed.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.processed_file_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.processed_file_bucket.bucket}/*",
        ]
      }
    ]
  })
}



resource "aws_iam_role_policy" "rekognition_s3_policy" {
  name        = "RekognitionS3AccessPolicy"
  role = aws_iam_role.generate_presigned_url_lambda_role.id

  # Define the policy in JSON format
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "rekognition:DetectText",
          "rekognition:DetectLabels",
          "rekognition:DetectModerationLabels",
          "rekognition:IndexFaces",
          "rekognition:SearchFaces",
          "rekognition:CompareFaces"
        ],
        "Resource" : "*"
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



resource "aws_iam_role" "eventbridge_invoke_stepfn_role" {
  name = "eventbridge-start-stepfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_invoke_stepfn_role_policy" {
  name = "eventbridge-start-stepfn-role-policy"
  role = aws_iam_role.eventbridge_invoke_stepfn_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
         "states:StartExecution"
        ],
        Resource = [
          aws_sfn_state_machine.s3_event_triggered.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "step_fn_exec_role" {
  name = "step_fn_s3_event_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "step_Fn_invoke_lambda_policy" {
  name = "step_fn_invoke_lambda-role-policy"
  role = aws_iam_role.step_fn_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
         "lambda:InvokeFunction"
        ],
        Resource = [
          aws_lambda_function.extract_s3_object_metadata_lambda.arn,
          aws_lambda_function.generate_image_to_text_lambda.arn,
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy" "step_fn_s3_access" {
  name = "Step_fn-s3-access"
  role = aws_iam_role.step_fn_exec_role.id

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
          "arn:aws:s3:::${aws_s3_bucket.file_to_be_processed.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.processed_file_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.processed_file_bucket.bucket}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "step_fn_dynamo_put_item" {
  name = "step_fn-dynamo-put"
  role = aws_iam_role.step_fn_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
         "dynamodb:UpdateItem"
        ],
        Resource = [
          aws_dynamodb_table.image_upload_jobs.arn
        ]
      }
    ]
  })
}
