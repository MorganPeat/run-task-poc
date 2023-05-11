"""Run task request handler function

This AWS Lambda handler function receives a request from Terraform Cloud to 
execute a run task. 

First, it validates that the run task is valid by checking the HMAC digest using an
environment variable which holds the HMAC key.
If the request is genuine it triggers the Run Task Callback lambda function (which actually
executes the run task) then returns a 200 OK to Terraform Cloud.
"""

import hmac
import hashlib
import os
import logging
import jsonpickle
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('lambda')


def handler(event, context):
    """Handler function which is called by AWS Lambda"""

    # Function defiition required for lambda: https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html
    # JSON request and response format: https://docs.aws.amazon.com/lambda/latest/dg/urls-invocation.html#urls-payloads

    logger.info('## EVENT\r' + jsonpickle.encode(event))
    logger.info('## CONTEXT\r' + jsonpickle.encode(context))

    key = os.environ['HMAC_KEY']
    payload = event['body']
    signature = event['headers']['x-tfc-task-signature']
    status = 200
    msg = "ok"

    # The HMAC digest for the payload must be valid.
    # TFC will calculate it using a key stored with the run task. Use
    # the same key here to validate the integrity of the payload.
    logger.info('Checking HMAC digest ...')
    if not hmac_digest_is_valid(key, payload, signature):
        status = 400
        msg = 'HMAC digest does not match signature'
        logger.error('HMAC digest does not match signature')

    logger.info('HMAC digest is OK.')

    # The payload is valid, invoke the next link in the chain - the
    # callback lambda.
    logger.info('Invoking callback lambda ...')
    callback_response = client.invoke(
        FunctionName='run_task_callback',
        InvocationType='Event',
        Payload=payload)
    logger.info(callback_response)
    logger.info('Callback lambda invoked. Returning ...')
    
    response = {
        'statusCode': status,
        'body': jsonpickle.encode({'status': msg})
    }
    logger.info(response)
    return response


def hmac_digest_is_valid(key: str, payload: str, signature: str) -> bool:
    """Returns true if the signature matches the SHA512 digest of the payload"""

    h = hmac.new(bytes(key, 'UTF-8'), bytes(payload, 'UTF-8'), hashlib.sha512)
    digest = h.hexdigest()
    return hmac.compare_digest(digest, signature)
