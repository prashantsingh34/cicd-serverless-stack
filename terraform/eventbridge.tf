

resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name        = "s3-object-created-event"
  description = "Trigger Step Function on S3 object upload"
  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": {
      "bucket": {
        "name": [aws_s3_bucket.file_to_be_processed.bucket]
      },
      "object": {
        "key": [{ "prefix": "uploads/" }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "start_step_function" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "StartStepFunction"
  arn       = aws_sfn_state_machine.s3_event_triggered.arn
  role_arn  = aws_iam_role.eventbridge_invoke_stepfn_role.arn
}



