# Some nonsense - doesn't matter what this is!
# The custom run task checks that the code is properly formatted
# (i.e. `terraform fmt` has been run).
# Change the formatting of this file to cause the run task to fail

resource "local_file" "foo" {
  content  = "foo!"
  filename   = "${path.module}/foo.bar"
}