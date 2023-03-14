import hmac
import hashlib
import os
import logging
import jsonpickle
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('lambda')


def lambda_handler(event, context):
    # Function defiition required for lambda
    # See https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html

    logger.info('## ENVIRONMENT VARIABLES\r' +
                jsonpickle.encode(dict(**os.environ)))
    logger.info('## EVENT\r' + jsonpickle.encode(event))
    logger.info('## CONTEXT\r' + jsonpickle.encode(context))

    key = os.environ['HMAC_KEY']
    payload = event['body']
    signature = event['headers']['x-tfc-task-signature']
    status = 400
    response = "ok"

    if not hmac_digest_is_valid(key, payload, signature):
        status = 401
        response = 'HMAC digest does not match signature'
        logger.error(response)

    # Payload format: https://docs.aws.amazon.com/lambda/latest/dg/urls-invocation.html#urls-payloads

    return {
        'statusCode': status,
        'body': jsonpickle.encode({'status': response})
    }


def hmac_digest_is_valid(key: str, payload: str, signature: str) -> bool:
    # Returns true if the signature matches the SHA512 digest of the payload with key
    h = hmac.new(bytes(key, 'UTF-8'), bytes(payload, 'UTF-8'), hashlib.sha512)
    digest = h.hexdigest()
    return hmac.compare_digest(digest, signature)
