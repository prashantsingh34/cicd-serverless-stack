import json
import os
import boto3
from urllib.parse import unquote_plus

# Initialize the S3 client
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    try:
        # Extract the bucket name and object key from the event
        bucket_name = event['detail']['bucket']['name']
        object_key = event['detail']['object']['key']
        
        # Decode the object key (to handle special characters in the key)
        object_key = unquote_plus(object_key)
        
        # Get object metadata from S3
        response = s3_client.head_object(Bucket=bucket_name, Key=object_key)
        
        # Extract the file name, extension, and size
        file_name, file_extension = os.path.splitext(object_key)
        file_size = response['ContentLength']
        
        # Return the file details
        return {
            'statusCode': 200,
            'body': json.dumps({
                'file_name': file_name,
                'file_extension': file_extension,
                'file_size': file_size
            })
        }
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
