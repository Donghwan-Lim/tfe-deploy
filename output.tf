# Outputs file
output "tfe-server-domain" {
  value = "https://${aws_eip.tfe-eip.public_dns}"
}