import os
import json
import boto3
from PIL import Image
import io

# Initialize the S3 client
s3_client = boto3.client('s3')
dest_bucket = os.environ['DEST_BUCKET']
def lambda_handler(event, context):
    try:
        # Get the source bucket, object key, and file extension from the event
        source_bucket = event['detail']['bucket']['name']
        object_key = event['detail']['object']['key']
        file_extension = event['body']['file_extension']  # Extracted from the previous Lambda response
        file_name = event['body']['file_name']
        file_size = event['body']['file_size']
        
        # Get the destination bucket from environment variables
        
        
        # Only process if the file is larger than 50KB (in bytes)
            # Fetch the object from the source bucket
        response = s3_client.get_object(Bucket=source_bucket, Key=object_key)
        file_content = response['Body'].read()

        # Open the image using Pillow
        image = Image.open(io.BytesIO(file_content))

        # Compress the image until it's below 50KB
        quality = 90  # Start with 90% quality and reduce as needed
        while file_size > 50 * 1024 and quality > 10:
            # Save to a BytesIO object with reduced quality
            image_io = io.BytesIO()
            image.save(image_io, format="PNG", quality=quality)
            image_io.seek(0)

            # Check the new size and reduce quality if necessary
            file_size = len(image_io.getvalue())
            quality -= 5

        # Upload the compressed file to the destination bucket
        image_io.seek(0)  # Reset the pointer to the start of the BytesIO object
        s3_client.put_object(Bucket=dest_bucket, Key=object_key, Body=image_io, ContentType='image/png')
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'File processed and uploaded successfully.',
                'destination_bucket': dest_bucket,
                'object_key': object_key
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
