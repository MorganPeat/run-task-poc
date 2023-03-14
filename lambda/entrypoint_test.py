import unittest
import json
import logging
import os
import sys
from entrypoint import lambda_handler

HMAC_KEY="centrally-deeply-humble-mammoth"
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)

class LambdaTest(unittest.TestCase):
    
    def test_lambda_handler(self):

        with open('event.json') as f:
            event = json.JSONDecoder().decode(f.read())

        os.environ['HMAC_KEY'] = HMAC_KEY
        context = {'requestid' : '1234'}
        
        response = lambda_handler(event, context)
        EXPECTED = {'statusCode': 400, 'body': '{\"status\": \"ok\"}'}
        self.assertEqual(response, EXPECTED)

if __name__ == '__main__':
    unittest.main()