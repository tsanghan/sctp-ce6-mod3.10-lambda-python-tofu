import os
import json
import pytest
from unittest.mock import patch
from botocore.exceptions import ClientError
from app import initialize_env, create_response, send_sns_message, hello, hello2, hello3

# Mock boto3 SNS client with moto
from moto import mock_aws
import boto3

REGION = "ap-southeast-1"
DEFAULT_SNS_ARN = "arn:aws:sns:ap-southeast-1:255945442255:MyCustomTopic-node"

@pytest.fixture
def sns_client():
    with mock_aws():
        client = boto3.client('sns', region_name=REGION)
        # Create a mock SNS topic
        client.create_topic(Name="MyCustomTopic-node")
        yield client

def test_initialize_env():
    # Test initializing environment variables
    initialize_env()
    assert os.environ['SNS_ARN'] == DEFAULT_SNS_ARN
    assert os.environ['CLASS_NAME'] == "DefaultClassName"

def test_create_response():
    # Test creating a standard response
    response = create_response(200, "Success", {"key": "value"})
    expected_response = {
        'statusCode': 200,
        'body': json.dumps({
            'message': "Success",
            'class_name': "DefaultClassName",
            'key': "value"
        })
    }
    assert response == expected_response

def test_create_response_no_additional_data():
    # Test creating a standard response without additional data
    response = create_response(200, "Success")
    expected_response = {
        'statusCode': 200,
        'body': json.dumps({
            'message': "Success",
            'class_name': "DefaultClassName"
        })
    }
    assert response == expected_response

@patch('app.sns_client')
def test_send_sns_message_success(mock_sns_client, sns_client):
    # Mock SNS publish method
    mock_sns_client.publish.return_value = {'MessageId': '12345'}

    params = {
        'Message': json.dumps({"test": "data"}, indent=2),
        'Subject': "Test SNS From Lambda",
        'TopicArn': DEFAULT_SNS_ARN,
    }

    response = send_sns_message(params)
    assert response['statusCode'] == 200
    assert 'snsResponse' in json.loads(response['body'])

@patch('app.sns_client')
def test_send_sns_message_failure(mock_sns_client):
    # Mock SNS publish method to raise an exception
    mock_sns_client.publish.side_effect = ClientError(
        error_response={'Error': {'Code': '500', 'Message': 'Internal Server Error'}},
        operation_name='Publish'
    )

    params = {
        'Message': json.dumps({"test": "data"}, indent=2),
        'Subject': "Test SNS From Lambda",
        'TopicArn': DEFAULT_SNS_ARN,
    }

    response = send_sns_message(params)
    assert response['statusCode'] == 500
    assert 'Error publishing message' in json.loads(response['body'])['message']

@patch('app.send_sns_message')
def test_hello(mock_send_sns_message):
    # Mock send_sns_message function
    mock_send_sns_message.return_value = create_response(200, "Success")

    event = {"key": "value"}
    response = hello(event, None)
    assert response['statusCode'] == 200
    assert 'Success' in json.loads(response['body'])['message']

def test_hello2():
    # Test hello2 function
    event = {"key": "value"}
    response = hello2(event, None)
    assert response['statusCode'] == 200
    assert 'Function 2' in json.loads(response['body'])['message']

def test_hello3():
    # Test hello3 function
    event = {"key": "value"}
    response = hello3(event, None)
    assert response['statusCode'] == 200
    assert 'Function 3' in json.loads(response['body'])['message']
