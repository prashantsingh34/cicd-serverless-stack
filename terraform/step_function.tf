resource "aws_sfn_state_machine" "s3_event_triggered" {
  name     = "ProcessS3ObjectStateMachine"
  role_arn = aws_iam_role.step_fn_exec_role.arn

  definition = jsonencode({
    Comment = "Triggered by S3 events",
    StartAt = "PassState",
    States = {
      PassState = {
        Type = "Pass",
        ResultPath = "$.result",
        Result = "Step Function triggered by S3",
        End = true
      }
    }
  })
}
