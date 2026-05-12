variable "region" {
  description = "Région AWS (ex: eu-west-1)"
  type        = string
  default     = "eu-west-1"
}

variable "key_name" {
  description = "Nom exact de ta clé SSH dans AWS"
  type        = string
  sensitive   = true # Masqué dans les logs et les plans
}

variable "my_ip" {
  description = "Ton adresse IP publique au format CIDR (ex: 1.2.3.4/32)"
  type        = string
  sensitive   = true
}
