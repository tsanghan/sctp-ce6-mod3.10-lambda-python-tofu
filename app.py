import os
import json
import boto3
from botocore.exceptions import ClientError

REGION = "ap-southeast-1"
DEFAULT_SNS_ARN = "arn:aws:sns:ap-southeast-1:255945442255:MyCustomTopic-node"
sns_client = boto3.client('sns', region_name=REGION)

# Initialize environment variables
def initialize_env():
    os.environ['SNS_ARN'] = os.getenv('SNS_ARN', DEFAULT_SNS_ARN)
    os.environ['CLASS_NAME'] = os.getenv('CLASS_NAME', 'DefaultClassName')

# Utility function to create standard responses
def create_response(status_code, message, additional_data=None):
    if additional_data is None:
        additional_data = {}
    return {
        'statusCode': status_code,
        'body': json.dumps({
            'message': message,
            'class_name': os.environ['CLASS_NAME'],
            **additional_data,
        })
    }

# Function to send SNS message
def send_sns_message(params):
    try:
        response = sns_client.publish(**params)
        return create_response(200, 'Go Serverless v4.0! Your function executed successfully!', {'snsResponse': response})
    except ClientError as err:
        return create_response(500, 'Error publishing message', {'error': str(err)})

# Lambda handler functions
def hello(event, context):
    initialize_env()
    print("*****HELLO*****")

    params = {
        'Message': json.dumps(event, indent=2),
        'Subject': "Test SNS From Lambda",
        'TopicArn': os.environ['SNS_ARN'],
    }

    return send_sns_message(params)

def hello2(event, context):
    initialize_env()
    print("*****HELLO-2*****")
    return create_response(200, 'Go Serverless v4.0! Your function executed successfully! Function 2')

def hello3(event, context):
    initialize_env()
    print("*****HELLO-3*****")
    return create_response(200, 'Go Serverless v4.0! Your function executed successfully! Function 3')
