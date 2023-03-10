resource "random_pet" "hmac_key" {
  length    = 4
  separator = "-"
}