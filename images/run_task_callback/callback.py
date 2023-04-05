"""Run task callback handler function

This AWS Lambda handler function receives a request from our request handler lambda
and executes the requested run task.

Once the run task actions have been executed (a `terraform fmt` here) this lambda
calls back to TFC to report on the result.
"""

import logging
import jsonpickle
import subprocess


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
