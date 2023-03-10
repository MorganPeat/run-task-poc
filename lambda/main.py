import json


# Function defiition required for lambda
# See https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html
def lambda_handler(event, context):
    print("Hello from Lambda!")
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
    