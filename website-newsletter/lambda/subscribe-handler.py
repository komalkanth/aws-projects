"""
AWS Lambda function for newsletter email subscription
Stores email in DynamoDB and sends a sample SES email.
"""

import json
import logging
import os
import re
from datetime import datetime
import boto3
from botocore.exceptions import ClientError

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
ses = boto3.client('ses')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Configuration from environment variables
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
SES_SOURCE_EMAIL = os.environ.get('SES_SOURCE_EMAIL')
SES_DESTINATION_EMAIL = os.environ.get('SES_DESTINATION_EMAIL')


def store_email_in_dynamodb(email):
    table = dynamodb.Table(DYNAMODB_TABLE_NAME)
    table.put_item(
        Item={
            'email': email.strip().lower(),
            'subscription_date': datetime.utcnow().isoformat() + 'Z',
            'source': 'web'
        },
        ConditionExpression='attribute_not_exists(email)'
    )


def send_sample_email(subscriber_email):
    response = ses.send_email(
        Source=SES_SOURCE_EMAIL,
        Destination={'ToAddresses': [SES_DESTINATION_EMAIL]},
        Message={
            'Subject': {
                'Data': f'[{ENVIRONMENT}] New Newsletter Subscription',
                'Charset': 'UTF-8'
            },
            'Body': {
                'Text': {
                    'Data': (
                      "Hello from awsconsult.kkoncloud.net!\n\n"
                      "Thank you for subscribing to the newsletter—expect concise AWS insights, cost-conscious reminders, "
                      "and delivery notes tailored to fast-moving teams. We're excited to have you in the community.\n\n"
                      f"Subscriber: {subscriber_email}\n"
                      f"Environment: {ENVIRONMENT}\n\n"
                      "If you ever need a specific pattern or want an architecture review, just reply to this note."
                    ),

                    'Charset': 'UTF-8'
                }
            }
        }
    )
    logger.info(f'SES email sent. MessageId: {response["MessageId"]}')


def lambda_handler(event, context):
    # Log the entire event for debugging
    logger.info(f'Received event: {json.dumps(event)}')

    cors_headers = {
        'Access-Control-Allow-Origin': os.environ.get('ALLOWED_ORIGIN', '*'),
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Content-Type': 'application/json'
    }

    if event.get('httpMethod') == 'OPTIONS':
        return {'statusCode': 200, 'headers': cors_headers, 'body': json.dumps({'message': 'OK'})}

    # Handle both API Gateway proxy and direct invocation formats
    body = event.get('body', '{}')

    # If body is None or not a string, try direct event
    if not body or body == '{}':
        # Direct invocation format (testing) or misconfigured API Gateway
        payload = event
    else:
        # API Gateway proxy integration format
        payload = json.loads(body) if isinstance(body, str) else body

    email = payload.get('email', '').strip()

    logger.info(f'Email input received: {email}')
    logger.info(f'Full payload: {payload}')

    # Validate email is not empty
    if not email:
        return {
            'statusCode': 400,
            'headers': cors_headers,
            'body': json.dumps({'error': 'INVALID_EMAIL', 'message': 'Email address is required.'})
        }

    # Validate email format
    email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if not re.match(email_pattern, email):
        return {
            'statusCode': 400,
            'headers': cors_headers,
            'body': json.dumps({'error': 'INVALID_EMAIL', 'message': 'Please provide a valid email address.'})
        }

    try:
        store_email_in_dynamodb(email)
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            return {
                'statusCode': 400,
                'headers': cors_headers,
                'body': json.dumps({'error': 'EMAIL_EXISTS', 'message': 'This email is already subscribed.'})
            }
        raise

    if SES_SOURCE_EMAIL and SES_DESTINATION_EMAIL:
        send_sample_email(email)

    return {
        'statusCode': 200,
        'headers': cors_headers,
        'body': json.dumps({'success': True, 'message': 'You have been successfully subscribed!', 'email': email})
    }

