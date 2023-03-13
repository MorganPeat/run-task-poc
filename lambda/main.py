import os
import logging
import jsonpickle


logger = logging.getLogger()
logger.setLevel(logging.INFO)


# Function defiition required for lambda
# See https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html
def lambda_handler(event, context):

    logger.info('ENVIRONMENT VARIABLES\r' +
                jsonpickle.encode(dict(**os.environ)))
    logger.info('## EVENT\r' + jsonpickle.encode(event))
    logger.info('## CONTEXT\r' + jsonpickle.encode(context))
        
    # Payload format: https://docs.aws.amazon.com/lambda/latest/dg/urls-invocation.html#urls-payloads

    return {
        'statusCode': 200,
        'body': jsonpickle.encode({'status' : 'ok'})
    }
    