# Outputs file
output "private_pem" {
  value = tls_private_key.tfe-priv-key.private_key_pem
  sensitive = true
}

output "instance_dns" {
  value = aws_instance.tfe-server.public_dns
  sensitive = false
}