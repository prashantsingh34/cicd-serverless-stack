import os
import json
import boto3

# Initialize the S3 client and Rekognition client
s3_client = boto3.client('s3')
rekognition_client = boto3.client('rekognition')
source_bucket = os.environ['SOURCE_BUCKET']
dest_bucket = os.environ['DEST_BUCKET']

def lambda_handler(event, context):
    try:
        # Get the source bucket, object key, and file extension from the event
        object_key = f"{event['body']['file_name']}{event['body']['file_extension']}"
        
        # Fetch the object from the source bucket
        response = s3_client.get_object(Bucket=source_bucket, Key=object_key)
        file_content = response['Body'].read()

        print("object_key:", object_key)

        # Send the image to Rekognition for text detection
        rekognition_response = rekognition_client.detect_text(
            Image={'Bytes': file_content}
        )

        # Extract the detected text from Rekognition's response
        detected_text = ""
        for item in rekognition_response['TextDetections']:
            detected_text += item['DetectedText'] + "\n"

        print("Detected text:", detected_text)

        # Create a text file with the detected text to upload to the destination bucket
        text_file_key = f"{event['body']['file_name']}_ocr.txt"
        s3_client.put_object(
            Bucket=dest_bucket,
            Key=text_file_key,
            Body=detected_text,
            ContentType='text/plain'
        )

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'OCR text extracted and uploaded successfully.',
                'destination_bucket': dest_bucket,
                'ocr_text_key': text_file_key
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
