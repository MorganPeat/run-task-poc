# A string that is used as the HMAC key for the run task.
# When TFC calls the custom run task it hashes the JSON payload using the key and 
# provides the digest in the request header.
# The run task uses the same key to authenticate the payload which proves that
# - TFC sent the run task request
# - The payload hasn't been tampered with
resource "random_pet" "hmac_key" {
  length    = 4
  separator = "-"
}