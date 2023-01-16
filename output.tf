# Outputs file
output "tfe-server-domain" {
  value = "https://${aws_eip.tfe-eip.public_dns}"
}

output "private_pem" {
  value = tls_private_key.tfe-priv-key.private_key_pem
  sensitive = true
}