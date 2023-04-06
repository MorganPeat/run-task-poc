"""Run task callback handler function

This AWS Lambda handler function receives a request from our request handler lambda
and executes the requested run task.

Once the run task actions have been executed (a `terraform fmt` here) this lambda
calls back to TFC to report on the result.
"""

import json
import logging
import jsonpickle
import subprocess
import requests


logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    """Handler function which is called by AWS Lambda"""

    # Function defiition required for lambda: https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html
    # JSON request and response format: https://docs.aws.amazon.com/lambda/latest/dg/urls-invocation.html#urls-payloads

    logger.info('## EVENT\r' + jsonpickle.encode(event))
    logger.info('## CONTEXT\r' + jsonpickle.encode(context))

    completed_process = subprocess.run(
        ['terraform', '-version'], check=True, timeout=60, capture_output=True, cwd='/var/task')

    logger.info('Exit code: ' + str(completed_process.returncode))
    logger.info('stdout: ' + completed_process.stdout.decode('utf-8'))
    logger.info('stderr: ' + completed_process.stderr.decode('utf-8'))

    logger.info('Function completed. Calling back to TFC with result ...')
    callback_url = event['task_result_callback_url']
    auth_token = event["access_token"]
    callback_to_tfc(callback_url, auth_token, "passed",
                    "Another message about the run task")

    logger.info('Done')


def callback_to_tfc(url: str, auth_token: str, status: str, msg: str) -> None:
    """Calls back to TFC with the result of the run task"""

    # For details of payload and request see
    # https://developer.hashicorp.com/terraform/cloud-docs/api-docs/run-tasks/run-tasks-integration#run-task-callback

    # Double quotes needed to be valid JSON
    headers = {
        "Authorization": f"Bearer {auth_token}",
        "Content-type": "application/vnd.api+json",
    }

    payload = {
        "data": {
            "attributes": {
                "status": status,
                "message": msg,
                "url": "http://www.google.com/"
            },
            "type": "task-results",
        }
    }

    logger.info(url)
    logger.info(json.dumps(payload))
    logger.info(headers)

    response = requests.patch(url, json.dumps(payload), headers=headers)
    logger.info(response)
