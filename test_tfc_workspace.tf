#
# A temporary TFE workspace that is used to test the
# custom run task.
#
resource "tfe_workspace" "run_task_tester" {
  name              = "run-task-tester"
  description       = "Workspace that executes our custom run task"
  terraform_version = "~> 1.3.0"

  allow_destroy_plan  = true
  auto_apply          = true
  assessments_enabled = true
}

#
# Configures the temporary testing TFE workspace to use our
# custom run task.
#
# The `tfe_organization_run_task` resource can assign the run task
# to all workspaces in an org.
#
resource "tfe_workspace_run_task" "example" {
  workspace_id      = tfe_workspace.run_task_tester.id
  task_id           = tfe_organization_run_task.custom.id
  stage             = "post_plan"
  enforcement_level = "advisory"
}