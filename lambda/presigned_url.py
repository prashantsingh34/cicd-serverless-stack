import json
import uuid
import boto3
from botocore.client import Config  
from datetime import datetime
import os


s3 = boto3.client('s3', 
    region_name='us-east-1',  
    config=Config(signature_version='s3v4')
)

dynamodb = boto3.resource('dynamodb')
stepfunctions = boto3.client('stepfunctions')

BUCKET = os.environ.get('SOURCE_BUCKET')
TABLE_NAME = os.environ.get('TABLE_NAME')

def lambda_handler(event, context):
    job_id = str(uuid.uuid4())
    key = f"uploads/{job_id}.jpg"


    presigned_url = s3.generate_presigned_url(
        'put_object',
        Params={
            'Bucket': BUCKET,
            'Key': key,
            'ContentType': 'image/png',
            'ServerSideEncryption': 'aws:kms'
        },
        ExpiresIn=600
    )

    # Record in DynamoDB
    table = dynamodb.Table(TABLE_NAME)
    table.put_item(Item={
        'job_id': job_id,
        'status': 'upload_pending',
        'uploaded_at': datetime.utcnow().isoformat(),
        'image_key': key
    })

    return {
        'statusCode': 200,
        'body': json.dumps({
            'upload_url': presigned_url,
            'job_id': job_id
        }), 
        'headers': {'Content-Type': 'application/json'}
    }