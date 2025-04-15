import os
import json
import boto3
import imageio
import io

# Initialize the S3 client
s3_client = boto3.client('s3')
source_bucket = os.environ['SOURCE_BUCKET']
dest_bucket = os.environ['DEST_BUCKET']

def lambda_handler(event, context):
    try:
        # Get the source bucket, object key, and file extension from the event
        object_key = f"{event['body']['file_name']}{event['body']['file_extension']}"
        file_size = event['body']['file_size']
        
        # Fetch the object from the source bucket
        response = s3_client.get_object(Bucket=source_bucket, Key=object_key)
        file_content = response['Body'].read()

        print("object_key:", object_key)
        print("file_size:", file_size)

        # Read the image using imageio
        img = imageio.imread(io.BytesIO(file_content))

        # Create a thumbnail by resizing the image (for example, 128x128)
        thumbnail_size = (128, 128)
        img_resized = img[:thumbnail_size[0], :thumbnail_size[1]]  # Basic resizing

        # Convert the resized image to a BytesIO object to upload to S3
        image_io = io.BytesIO()
        imageio.imwrite(image_io, img_resized, format='PNG')
        image_io.seek(0)

        # Upload the thumbnail to the destination bucket
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
