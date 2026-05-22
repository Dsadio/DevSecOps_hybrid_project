pipeline {
  agent any

  parameters {
    booleanParam(
      name: 'DESTROY_INFRASTRUCTURE',
      defaultValue: false,
      description: '⚠️ Cocher pour DÉTRUIRE l\'infrastructure AWS'
    )
  }

  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 60, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  environment {
    // Terraform & AWS
    TF_IN_AUTOMATION = "true"
    AWS_REGION = "eu-west-3"
    AWS_DEFAULT_REGION = "eu-west-3"
    
    // Servers
    ONPREM_IP = "192.168.1.77"
    ONPREM_USER = "on_prem"
    AWS_USER = "ubuntu"
    
    // Directories
    TF_DIR = "terraform"
    ANSIBLE_DIR = "ansible"
    SECURITY_DIR = "security"
    
    // Ansible
    ANSIBLE_HOST_KEY_CHECKING = "False"
    ANSIBLE_FORCE_COLOR = "true"
  }

  stages {

    stage('📥 Checkout') {
      steps {
        script {
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "📥 Checkout du code source depuis GitHub"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
        git url: 'https://github.com/Dsadio/DevSecOps_hybrid_project.git', branch: 'main'
      }
    }

    stage('🔒 Security - tfsec') {
      when {
        expression { params.DESTROY_INFRASTRUCTURE == false }
      }
      steps {
        script {
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "🔒 Analyse de sécurité Terraform avec tfsec"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
        sh """
          mkdir -p ${SECURITY_DIR}/tfsec
          tfsec ${TF_DIR}/ --no-color | tee ${SECURITY_DIR}/tfsec/report.txt || true
        """
      }
    }

    stage('✅ Quality - ansible-lint') {
      when {
        expression { params.DESTROY_INFRASTRUCTURE == false }
      }
      steps {
        script {
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "✅ Analyse qualité Ansible avec ansible-lint"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
        sh """
          mkdir -p ${SECURITY_DIR}/ansible-lint
          ansible-lint ${ANSIBLE_DIR}/playbook.yml | tee ${SECURITY_DIR}/ansible-lint/report.txt || true
        """
      }
    }

    stage('🏗️ Terraform Init') {
      steps {
        script {
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "🏗️ Initialisation Terraform"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
        withCredentials([
          usernamePassword(
            credentialsId: 'aws-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
          )
        ]) {
          sh """
            cd ${TF_DIR}
            terraform init -no-color
          """
        }
      }
    }

    stage('🚀 Terraform Apply') {
      when {
        expression { params.DESTROY_INFRASTRUCTURE == false }
      }
      steps {
        script {
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "🚀 Déploiement de l'infrastructure AWS"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
        withCredentials([
          usernamePassword(
            credentialsId: 'aws-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
          )
        ]) {
          sh """
            cd ${TF_DIR}
            terraform apply -auto-approve -no-color \\
              -var="key_name=devops-hybrid-key" \\
              -var="my_ip=\$(curl -s ifconfig.me)/32"
          """
        }
      }
    }

    stage('🗑️ Terraform Destroy') {
      when {
        expression { params.DESTROY_INFRASTRUCTURE == true }
      }
      steps {
        script {
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "🗑️ DESTRUCTION DE L'INFRASTRUCTURE AWS"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
        input message: '⚠️ Confirmer la destruction de l\'infrastructure ?', ok: 'DÉTRUIRE'
        withCredentials([
          usernamePassword(
            credentialsId: 'aws-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
          )
        ]) {
          sh """
            cd ${TF_DIR}
            terraform destroy -auto-approve -no-color \\
              -var="key_name=devops-hybrid-key" \\
              -var="my_ip=0.0.0.0/0"
          """
        }
      }
    }

    stage('📍 Get EC2 Public IP') {
      when {
        expression { params.DESTROY_INFRASTRUCTURE == false }
      }
      steps {
        script {
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "📍 Récupération de l'IP publique EC2"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          
          env.AWS_IP = sh(
            script: "cd ${TF_DIR} && terraform output -raw public_ip",
            returnStdout: true
          ).trim()
          
          if (!env.AWS_IP) {
            error("❌ IP publique EC2 vide : vérifiez terraform output 'public_ip'")
          }
          
          echo "✅ AWS EC2 Public IP: ${env.AWS_IP}"
        }
      }
    }

    stage('⚙️ Ansible Deploy') {
      when {
        expression { params.DESTROY_INFRASTRUCTURE == false }
      }
      steps {
        script {
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "⚙️ Configuration Apache avec Ansible"
          echo "   AWS: ${env.AWS_IP}"
          echo "   On-Premise: ${ONPREM_IP}"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
        withCredentials([
          sshUserPrivateKey(credentialsId: 'ssh-key-aws', keyFileVariable: 'AWS_KEY_FILE'),
          sshUserPrivateKey(credentialsId: 'ssh-key-onprem', keyFileVariable: 'ONPREM_KEY_FILE')
        ]) {
          sh """
            # Sécurisation des clés SSH
            chmod 600 \${AWS_KEY_FILE}
            chmod 600 \${ONPREM_KEY_FILE}
            
            # Configuration Ansible
            cat > ${ANSIBLE_DIR}/ansible.cfg <<EOF
[defaults]
host_key_checking = False
timeout = 30
inventory = inventory/all.ini

[privilege_escalation]
become_ask_pass = False

[ssh_connection]
pipelining = False
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
EOF
            
            # Génération de l'inventaire
            cat > ${ANSIBLE_DIR}/inventory/all.ini <<EOF
[aws]
\${AWS_IP} ansible_user=\${AWS_USER} ansible_ssh_private_key_file=\${AWS_KEY_FILE}

[onprem]
\${ONPREM_IP} ansible_user=\${ONPREM_USER} ansible_ssh_private_key_file=\${ONPREM_KEY_FILE}

[all:children]
aws
onprem

[all:vars]
ansible_ssh_common_args=-o StrictHostKeyChecking=no
ansible_python_interpreter=/usr/bin/python3
EOF

            echo "📋 Inventaire Ansible généré:"
            cat ${ANSIBLE_DIR}/inventory/all.ini
            
            # Test de connectivité
            echo ""
            echo "🔌 Test de connectivité..."
            cd ${ANSIBLE_DIR}
            ansible -i inventory/all.ini all -m ping
            
            # Déploiement
            echo ""
            echo "🚀 Déploiement Apache..."
            ansible-playbook -i inventory/all.ini playbook.yml -v
          """
        }
      }
    }

    stage('✅ Validation HTTP') {
      when {
        expression { params.DESTROY_INFRASTRUCTURE == false }
      }
      steps {
        script {
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "✅ Validation du déploiement HTTP"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
        sh """
          echo "📡 Test AWS EC2 (${env.AWS_IP})..."
          curl -I http://\${AWS_IP} || echo "❌ AWS HTTP check failed"
          
          echo ""
          echo "📡 Test On-Premise (${ONPREM_IP})..."
          curl -I http://\${ONPREM_IP} || echo "❌ On-Premise HTTP check failed"
          
          echo ""
          echo "📄 Contenu page AWS:"
          curl -fsS http://\${AWS_IP} | head -n 10 || true
          
          echo ""
          echo "📄 Contenu page On-Premise:"
          curl -fsS http://\${ONPREM_IP} | head -n 10 || true
        """
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: "${SECURITY_DIR}/**/report.txt", allowEmptyArchive: true
    }
    
    success {
      script {
        if (params.DESTROY_INFRASTRUCTURE) {
          echo """
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ INFRASTRUCTURE DÉTRUITE AVEC SUCCÈS !
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💰 Vérifiez AWS Console pour confirmer
   https://eu-west-3.console.aws.amazon.com/ec2/
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          """
        } else {
          echo """
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ DÉPLOIEMENT RÉUSSI !
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌐 URLs d'accès :
   • AWS EC2      : http://${env.AWS_IP}
   • On-Premise   : http://${ONPREM_IP}

📊 Rapports de sécurité :
   • tfsec        : ${SECURITY_DIR}/tfsec/report.txt
   • ansible-lint : ${SECURITY_DIR}/ansible-lint/report.txt
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          """
        }
      }
    }
    
    failure {
      echo """
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ PIPELINE ÉCHOUÉ
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Consultez les logs ci-dessus pour identifier l'erreur
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      """
    }
  }
}
