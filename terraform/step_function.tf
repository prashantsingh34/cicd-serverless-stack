resource "aws_sfn_state_machine" "s3_event_triggered" {
  name     = "ProcessS3ObjectStateMachine"
  role_arn = aws_iam_role.step_fn_exec_role.arn

  definition = jsonencode({
  "Comment": "Triggered by S3 events",
  "StartAt": "Get File metadata",
  "States": {
    "Check File type": {
      "Choices": [
        {
          "Next": "UpdateItem incorrect extension",
          "Not": {
            "Variable": "$.body.file_extension",
            "StringEquals": ".png"
          }
        }
      ],
      "Default": "Check file size",
      "Type": "Choice"
    },
    "Check file size": {
      "Choices": [
        {
          "Next": "Modify File and upload to s3",
          "Variable": "$.body.file_size",
          "NumericGreaterThan": 50
        }
      ],
      "Default": "CopyObject-> No modification reqd",
      "Type": "Choice"
    },
    "Check statusCode": {
      "Choices": [
        {
          "Next": "UpdateItem file trsansfer failed",
          "Not": {
            "NumericEquals": 200,
            "Variable": "$.modifyFile.statusCode"
          }
        }
      ],
      "Default": "UpdateItem File transfer successfull",
      "Type": "Choice"
    },
    "Choice": {
      "Choices": [
        {
          "Next": "UpdateItem file trsanfer failed",
          "NumericEquals": 500,
          "Variable": "$.statusCode"
        }
      ],
      "Default": "Check File type",
      "Type": "Choice"
    },
    "CopyObject-> No modification reqd": {
      "Next": "UpdateItem File transfer successfull",
      "Parameters": {
        "Bucket": "MyData",
        "CopySource": "MyData",
        "Key": "MyData"
      },
      "Resource": "arn:aws:states:::aws-sdk:s3:copyObject",
      "Type": "Task"
    },
    "Get File metadata": {
      "Next": "Choice",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": aws_lambda_function.extract_s3_object_metadata_lambda.arn,
        "Payload.$": "$"
      },
      "Resource": "arn:aws:states:::lambda:invoke",
      "Retry": [
        {
          "BackoffRate": 2,
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 1,
          "JitterStrategy": "FULL",
          "MaxAttempts": 3
        }
      ],
      "Type": "Task"
    },
    "Modify File and upload to s3": {
      "Next": "Check statusCode",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": aws_lambda_function.modify_file_size_lambda.arn
        "Payload.$": "$"
      },
      "Resource": "arn:aws:states:::lambda:invoke",
      "Retry": [
        {
          "BackoffRate": 2,
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 1,
          "JitterStrategy": "FULL",
          "MaxAttempts": 3
        }
      ],
      "Type": "Task"
    },
    "UpdateItem File transfer successfull": {
      "End": true,
      "Parameters": {
        "ExpressionAttributeValues": {
          ":myValueRef": {
            "S": "success"
          }
        },
        "Key": {
          "job_id": {
            "S.$": "$.body.file_name"
          }
        },
        "TableName": aws_dynamodb_table.image_upload_jobs.name,
        "UpdateExpression": "SET job_status = :myValueRef"
      },
      "Resource": "arn:aws:states:::dynamodb:updateItem",
      "Type": "Task"
    },
    "UpdateItem file trsanfer failed": {
      "End": true,
      "Parameters": {
        "ExpressionAttributeValues": {
          ":myValueRef": {
            "S": "Error while getting metadata of file"
          }
        },
        "Key": {
          "job_id": {
            "S.$": "$.file_name"
          }
        },
        "TableName": aws_dynamodb_table.image_upload_jobs.name,
        "UpdateExpression": "SET job_status = :myValueRef"
      },
      "Resource": "arn:aws:states:::dynamodb:updateItem",
      "Type": "Task"
    },
    "UpdateItem file trsansfer failed": {
      "End": true,
      "Parameters": {
        "ExpressionAttributeValues": {
          ":myValueRef": {
            "S": "Error while modifying file size"
          }
        },
        "Key": {
          "job_id": {
            "S.$": "$.body.file_name"
          }
        },
        "TableName": aws_dynamodb_table.image_upload_jobs.name,
        "UpdateExpression": "SET job_status = :myValueRef"
      },
      "Resource": "arn:aws:states:::dynamodb:updateItem",
      "Type": "Task"
    },
    "UpdateItem incorrect extension": {
      "End": true,
      "Parameters": {
        "ExpressionAttributeValues": {
          ":myValueRef": {
            "S": "Incorrect File Extension"
          }
        },
        "Key": {
          "job_id": {
            "S.$": "$.body.file_name"
          }
        },
        "TableName": aws_dynamodb_table.image_upload_jobs.name,
        "UpdateExpression": "SET job_status = :myValueRef"
      },
      "Resource": "arn:aws:states:::dynamodb:updateItem",
      "Type": "Task"
    }
  }
})
}
