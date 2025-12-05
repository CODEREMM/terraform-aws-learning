import json
import boto3
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    try:
        item_id = str(int(datetime.now().timestamp() * 1000))
        
        item = {
            'id': item_id,
            'message': 'Hello from Terraform Lambda!',
            'timestamp': datetime.now().isoformat(),
            'environment': os.environ.get('ENVIRONMENT', 'unknown')
        }
        
        table.put_item(Item=item)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Item written to DynamoDB successfully!',
                'item_id': item_id,
                'table_name': os.environ['TABLE_NAME']
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'message': 'Failed to write to DynamoDB'
            })
        }