terraform {
  cloud {
    organization = "mp-demo-org"

    workspaces {
      name = "run-task-poc"
    }
  }
}