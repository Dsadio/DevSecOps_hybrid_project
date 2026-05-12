# ─── Provider AWS ─────────────────────────────────────
# Dit à Terraform qu'on travaille avec Amazon Web Services
# La région sera définie dans les variables.
# Pas de credentials ici : on utilise "aws configure" en local.

provider "aws" {
  region = var.region
}
