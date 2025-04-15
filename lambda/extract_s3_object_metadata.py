import json
import os
import boto3
from urllib.parse import unquote_plus

# Initialize the S3 client
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    bucket_name = event.get('detail').get('bucket').get('name')
    object_key = event.get('detail').get('object').get('key')
    file_name=object_key.split('/')[1].split('.')[0]
    try:
        # Extract the bucket name and object key from the event

        
        # Decode the object key (to handle special characters in the key)
        object_key = unquote_plus(object_key)
        
        # Get object metadata from S3
        response = s3_client.head_object(Bucket=bucket_name, Key=object_key)
        
        # Extract the file name, extension, and size
        file_name, file_extension = os.path.splitext(object_key)
        file_size = response['ContentLength']/1024
        result = {
            "file_name": file_name,
            "file_extension": file_extension,
            "file_size": file_size
        }        
        # Return the file details
        return {
            'statusCode': 200,
            'body': result
        }
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            }),
            'file_name': file_name
        }
