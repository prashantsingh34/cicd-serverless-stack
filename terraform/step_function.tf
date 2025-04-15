resource "aws_sfn_state_machine" "s3_event_triggered" {
  name     = "ProcessS3ObjectStateMachine"
  role_arn = aws_iam_role.step_fn_exec_role.arn

  definition = jsonencode({
  "Comment": "Triggered by S3 events",
  "StartAt": "Get File metadata",
  "States": {
    "Get File metadata": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": aws_lambda_function.extract_s3_object_metadata_lambda.arn
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2,
          "JitterStrategy": "FULL"
        }
      ],
      "Next": "Choice"
    },
    "Choice": {
      "Type": "Choice",
      "Choices": [
        {
          "Next": "UpdateItem file trsanfer failed",
          "Variable": "$.statusCode",
          "NumericEquals": 500
        }
      ],
      "Default": "Check File type"
    },
    "UpdateItem file trsanfer failed": {
      "Type": "Task",
      "Resource": "arn:aws:states:::dynamodb:updateItem",
      "Parameters": {
        "TableName": "MyDynamoDBTable",
        "Key": {
          "Column": {
            "S": "MyEntry"
          }
        },
        "UpdateExpression": "SET MyKey = :myValueRef",
        "ExpressionAttributeValues": {
          ":myValueRef": {
            "S": "MyValue"
          }
        }
      },
      "End": true
    },
    "Check File type": {
      "Type": "Choice",
      "Choices": [
        {
          "Not": {
            "Variable": "$.file.type",
            "StringEquals": "png"
          },
          "Next": "Pass-> can't modify file"
        }
      ],
      "Default": "Check file size"
    },
    "Pass-> can't modify file": {
      "Type": "Pass",
      "Next": "UpdateItem incorrect extension"
    },
    "UpdateItem incorrect extension": {
      "Type": "Task",
      "Resource": "arn:aws:states:::dynamodb:updateItem",
      "Parameters": {
        "TableName": "MyDynamoDBTable",
        "Key": {
          "Column": {
            "S": "MyEntry"
          }
        },
        "UpdateExpression": "SET MyKey = :myValueRef",
        "ExpressionAttributeValues": {
          ":myValueRef": {
            "S": "MyValue"
          }
        }
      },
      "End": true
    },
    "Check file size": {
      "Type": "Choice",
      "Choices": [
        {
          "Next": "Modify File and upload to s3",
          "Variable": "$.file.size",
          "NumericGreaterThan": 50
        }
      ],
      "Default": "CopyObject-> No modification reqd"
    },
    "CopyObject-> No modification reqd": {
      "Type": "Task",
      "Parameters": {
        "Bucket": "MyData",
        "CopySource": "MyData",
        "Key": "MyData"
      },
      "Resource": "arn:aws:states:::aws-sdk:s3:copyObject",
      "Next": "UpdateItem File transfer successfull"
    },
    "UpdateItem File transfer successfull": {
      "Type": "Task",
      "Resource": "arn:aws:states:::dynamodb:updateItem",
      "Parameters": {
        "TableName": "MyDynamoDBTable",
        "Key": {
          "Column": {
            "S": "MyEntry"
          }
        },
        "UpdateExpression": "SET MyKey = :myValueRef",
        "ExpressionAttributeValues": {
          ":myValueRef": {
            "S": "MyValue"
          }
        }
      },
      "End": true
    },
    "Modify File and upload to s3": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": aws_lambda_function.modify_file_size_lambda.arn
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2,
          "JitterStrategy": "FULL"
        }
      ],
      "Next": "Check statusCode"
    },
    "Check statusCode": {
      "Type": "Choice",
      "Choices": [
        {
          "Next": "UpdateItem file trsansfer failed",
          "Not": {
            "Variable": "$.modifyFile.statusCode",
            "NumericEquals": 200
          }
        }
      ],
      "Default": "UpdateItem File transfer successfull"
    },
    "UpdateItem file trsansfer failed": {
      "Type": "Task",
      "Resource": "arn:aws:states:::dynamodb:updateItem",
      "Parameters": {
        "TableName": "MyDynamoDBTable",
        "Key": {
          "Column": {
            "S": "MyEntry"
          }
        },
        "UpdateExpression": "SET MyKey = :myValueRef",
        "ExpressionAttributeValues": {
          ":myValueRef": {
            "S": "MyValue"
          }
        }
      },
      "End": true
    }
  }
})
}
