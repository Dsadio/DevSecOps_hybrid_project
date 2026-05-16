output "public_ip" {
  description = "IP publique de l'instance EC2"
  value       = aws_instance.web.public_ip
}
