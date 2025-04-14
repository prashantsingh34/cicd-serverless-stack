import csv
import boto3
import logging
import json
import os
from datetime import datetime


dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')

logger = logging.getLogger()
logger.setLevel(logging.INFO)



def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event, indent=2)}")

    return {
        'statusCode': 200,
        'body': json.dumps('Hello From Lambda')
    }
