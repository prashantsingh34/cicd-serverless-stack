resource "aws_cloudwatch_event_bus" "file_transfer_event_bus" {
  name = "file-process-event-bus"
}

resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name        = "s3-object-created-event"
  event_bus_name = aws_cloudwatch_event_bus.file_transfer_event_bus.name
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
  depends_on=[aws_cloudwatch_event_bus.file_transfer_event_bus]
}

resource "aws_cloudwatch_event_target" "start_step_function" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  event_bus_name = aws_cloudwatch_event_bus.file_transfer_event_bus.name
  target_id = "StartStepFunction"
  arn       = aws_sfn_state_machine.s3_event_triggered.arn
  role_arn  = aws_iam_role.eventbridge_invoke_stepfn_role.arn
  depends_on=[aws_cloudwatch_event_bus.file_transfer_event_bus]
}



resource "aws_cloudwatch_log_group" "eventbridge_logs" {
  name = "/aws/events/s3-debug"
}

resource "aws_cloudwatch_event_target" "log_target" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "LogTarget"
  event_bus_name = aws_cloudwatch_event_bus.file_transfer_event_bus.name
  arn       = aws_cloudwatch_log_group.eventbridge_logs.arn
}


resource "aws_cloudwatch_log_resource_policy" "eventbridge_logs_policy" {
  policy_name = "AllowEventBridgeToPutLogs"
  policy_document = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Effect = "Allow",
        Principal: {
          Service: "events.amazonaws.com"
        },
        Action: "logs:PutLogEvents",
        Resource: "*"
      }
    ]
  })
}
