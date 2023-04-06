"""Run task callback handler function

This AWS Lambda handler function receives a request from our request handler lambda
and executes the requested run task.

Once the run task actions have been executed (a `terraform fmt` here) this lambda
calls back to TFC to report on the result.
"""

import json
import logging
import os
import tarfile
import tempfile
import jsonpickle
import subprocess
import requests


logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def handler(event, context):
    """Handler function which is called by AWS Lambda"""

    # Function defiition required for lambda: https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html
    # JSON request and response format: https://docs.aws.amazon.com/lambda/latest/dg/urls-invocation.html#urls-payloads
    logger.debug('## EVENT\r' + jsonpickle.encode(event))
    logger.debug('## CONTEXT\r' + jsonpickle.encode(context))

    logger.info('Geting the terraform plan output ...')
    TF_TOKEN = os.environ['TF_TOKEN']
    headers = {
        'Authorization': f'Bearer {TF_TOKEN}',
        'Content-type': 'application/vnd.api+json',
    }
    plan = get_tfe_json(event['plan_json_api_url'], headers)
    logger.debug(plan)

    logger.info('Downloading terraform files for this run ...')
    with tempfile.TemporaryDirectory(dir='/tmp/') as tf_location:
        download_tf_files(event['run_id'], headers)

        logger.info('Validating terraform configuration ...')
        execute_terraform(['terraform', '-version'], tf_location)
        completed_process = execute_terraform(
            ['terraform', 'fmt', '-recursive', '-check'],
            tf_location)

    logger.info('Function completed. Calling back to TFC with result ...')

    headers = {
        # Requires passed access token
        'Authorization': f'Bearer {event["access_token"]}',
        'Content-type': 'application/vnd.api+json',
    }
    callback_url = event['task_result_callback_url']

    status = 'passed'
    message = 'Format check passed'
    if completed_process.returncode != 0:
        status = 'failed'
        message = completed_process.stdout.decode('utf-8')

    callback_to_tfc(callback_url, headers, status, message)
    logger.info('Done')


def callback_to_tfc(url: str, headers: str, status: str, msg: str) -> None:
    """Calls back to TFC with the result of the run task"""

    # For details of payload and request see
    # https://developer.hashicorp.com/terraform/cloud-docs/api-docs/run-tasks/run-tasks-integration#run-task-callback
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

    with requests.patch(url, json.dumps(payload), headers=headers) as r:
        logger.debug(r)
        r.raise_for_status()


def get_tfe_json(url: str, headers: str):
    """Downloads json from a TFE / TFC url"""
    with requests.get(url, headers=headers, allow_redirects=True) as r:
        r.raise_for_status()
        return r.json()


def download_tf_files(run_id: str, headers: str, download_dir: str) -> None:
    """Downloads the terraform files used in this run"""

    CV_ARCHIVE = '/tmp/data.tar.gz'

    # Download the configurations files as a `.tar.gz`` file
    # https://developer.hashicorp.com/terraform/cloud-docs/api-docs/configuration-versions#download-configuration-files
    url = f'https://app.terraform.io/api/v2/runs/{run_id}/configuration-version/download'
    with requests.get(url, headers=headers, allow_redirects=True, stream=True) as r:
        r.raise_for_status()
        with open(CV_ARCHIVE, 'wb') as f:
            for chunk in r.iter_content(chunk_size=1048576):
                f.write(chunk)

    # Unzip the configuration file archive into a folder
    with tarfile.open(CV_ARCHIVE) as a:
        a.extractall(download_dir)


def execute_terraform(args, cwd: str) -> subprocess.CompletedProcess:
    """Executes the terraform binary with supplied args"""

    logger.info('Executing: ' + ' '.join(args))
    completed_process = subprocess.run(
        args, timeout=60, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=cwd)

    logger.info('Exit code: ' + str(completed_process.returncode))
    logger.debug('stdout: ' + completed_process.stdout.decode('utf-8'))
    return completed_process
