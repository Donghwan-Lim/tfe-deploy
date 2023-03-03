# Outputs file
output "private_pem" {
  value = tls_private_key.tfe-priv-key.private_key_pem
  sensitive = true
}