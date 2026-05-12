output "public_ip" {
  description = "IP publique de l'instance EC2"
  value       = aws_instance.web.public_ip
}

output "ssh_command" {
  description = "Commande SSH prête à l'emploi"
  value       = "ssh -i /chemin/vers/ma-cle.pem ubuntu@${aws_instance.web.public_ip}"
}
