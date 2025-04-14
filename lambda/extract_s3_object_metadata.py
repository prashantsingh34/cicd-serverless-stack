import json
import uuid
import boto3
from datetime import datetime
import os


s3 = boto3.client('s3', region_name='us-east-1')

stepfunctions = boto3.client('stepfunctions')

BUCKET = os.environ.get('SOURCE_BUCKET')

def lambda_handler(event, context):

    return {
        'statusCode': 200,
        'body': json.dumps('Hello from lambda')
    }