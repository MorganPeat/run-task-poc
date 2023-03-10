# run-task-poc

Creates a custom Terraform Run Task which executes a AWS Lambda.

## Lambda

[lambda.tf](./lambda.tf) deploys a AWS Lambda function which executes a python script stored in [lambda/main.py](./lambda/main.py).
