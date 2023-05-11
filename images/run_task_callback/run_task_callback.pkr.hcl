###########################################################################
# Builds a docker image containing a AWS Lambda handling python function
###########################################################################

packer {
  required_plugins {
    docker = {
      version = "~> 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}


# AWS base images can be found at https://docs.aws.amazon.com/lambda/latest/dg/python-image.html#python-image-base
variable "docker_image" {
  type        = string
  description = "The AWS Lambda base python image to use"

  default = "public.ecr.aws/lambda/python:3.9"
}

variable "ecr_url" {
  type        = string
  description = "The URL of the ECR repository to push the image to"

  default = "303871294183.dkr.ecr.eu-west-2.amazonaws.com/run-task-poc-callback"
}



source "docker" "base" {
  image  = var.docker_image
  commit = true

  # I build on a mac but the Lambda runs on a different platform
  platform = "linux/amd64"

  changes = [
    # This is the name of the handler function python script. See https://docs.aws.amazon.com/lambda/latest/dg/python-image.html#python-image-create
    "CMD [ \"callback.handler\" ]",
    # Seems that some of the base image parameters are removed when packer builds, so
    # I add them back here. They came from https://github.com/aws/aws-lambda-base-images/blob/python3.9/Dockerfile.python3.9
    "WORKDIR /var/task",
    "ENTRYPOINT [ \"/lambda-entrypoint.sh\" ]",
  ]
}

build {
  name = "lambda"
  sources = [
    "source.docker.base"
  ]

  # Handler script must be in WORKDIR
  provisioner "shell" {
    inline = ["mkdir -p /var/task"]
  }

  # Copy the required python files into the image
  provisioner "file" {
    destination = "/var/task/"
    sources = [
      "requirements.txt",
      "callback.py",
    ]
  }

  # Install python requirements then install the terraform binary
  provisioner "shell" {
    inline = [
      "cd /var/task",
      "pip3 install -r requirements.txt --target .",
      "yum -y install wget unzip",
      "wget https://releases.hashicorp.com/terraform/1.3.9/terraform_1.3.9_linux_amd64.zip",
      "unzip terraform_1.3.9_linux_amd64.zip -d /usr/local/bin/",
      "terraform --version",
    ]
  }


  # Tag and push the image to my ECR repository (created earlier)
  # See https://developer.hashicorp.com/packer/plugins/builders/docker#amazon-ec2-container-registry
  # Credentials are read from AWS_ environment variables
  post-processors {
    post-processor "docker-tag" {
      repository = var.ecr_url
      tags       = ["latest"]
    }

    post-processor "docker-push" {
      ecr_login    = true
      login_server = "https://${var.ecr_url}"
    }
  }
}