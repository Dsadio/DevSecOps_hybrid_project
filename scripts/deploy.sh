#!/bin/bash
# Script pour vérifier la config AWS sans toucher au code

set -e

echo "🔍 Vérification de la configuration AWS..."

# Vérifier si AWS CLI est installé
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI n'est pas installé"
    exit 1
fi

# Vérifier si les credentials existent
if [ ! -f ~/.aws/credentials ]; then
    echo "❌ Credentials AWS manquants"
    echo "👉 Exécute 'aws configure' pour configurer"
    exit 1
fi

# Tester la connexion
if aws sts get-caller-identity &> /dev/null; then
    echo "✅ AWS configuré correctement"
    aws sts get-caller-identity
else
    echo "❌ Problème avec les credentials AWS"
    exit 1
fi

echo "✅ Prêt à déployer Terraform"
