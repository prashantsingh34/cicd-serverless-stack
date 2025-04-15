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
            "StringEquals": ".png",
            "Variable": "$.body.file_extension"
          }
        }
      ],
      "Default": "Text from image",
      "Type": "Choice"
    },
    "Text from image": {
      "Next": "Check Status Code",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": aws_lambda_function.generate_image_to_text_lambda.arn,
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
    "Check Status Code": {
      "Choices": [
        {
          "Next": "UpdateItem file trsansfer failed",
          "Not": {
            "Variable": "$.statusCode",
            "NumericEquals": 200
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
    "Get File metadata": {
      "Next": "Choice",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": aws_lambda_function.extract_s3_object_metadata_lambda.arn
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
    "UpdateItem file transfer failed": {
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
            "S.$": "$.file_name"
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
