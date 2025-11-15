import json
import boto3
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    #Write a test item
    table.put_item(
        Item={
            'id': str(datetime.now().timestamp()),
            'message': 'Hello from Terraform Lambda!',
            'timestamp': datetime.now().isoformat()
        }
    )

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Item written to DynamoDB'})
    }
    

