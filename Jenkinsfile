pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 60, unit: 'MINUTES')
  }

  environment {
    TF_IN_AUTOMATION = "true"
    ONPREM_IP   = "192.168.1.77"
    ONPREM_USER = "on_prem"
    AWS_USER    = "ubuntu"
    AWS_REGION  = "eu-west-3"
  }

  stages {

    stage('Checkout') {
      steps {
        git url: 'https://github.com/Dsadio/DevSecOps_hybrid_project.git', branch: 'main'
      }
    }

    stage('Security - tfsec (Terraform)') {
      steps {
        sh '''
          mkdir -p security/tfsec
          tfsec terraform/ --no-color | tee security/tfsec/report.txt || true
        '''
      }
    }

    stage('Quality - ansible-lint') {
      steps {
        sh '''
          mkdir -p security/ansible-lint
          ansible-lint ansible/playbook.yml | tee security/ansible-lint/report.txt || true
        '''
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                          usernameVariable: 'AWS_ACCESS_KEY_ID',
                          passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            export AWS_DEFAULT_REGION="${AWS_REGION}"
            cd terraform
            terraform init -no-color
          '''
        }
      }
    }

       stage('Terraform Apply') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                          usernameVariable: 'AWS_ACCESS_KEY_ID',
                          passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            export AWS_DEFAULT_REGION="${AWS_REGION}"
            cd terraform
            # Ajout des variables ici
            terraform apply -auto-approve -no-color \
              -var="key_name=devops-hybrid-key" \
              -var="my_ip=0.0.0.0/0"
          '''
        }
      }
    }

    stage('Get EC2 Public IP') {
      steps {
        script {
          env.AWS_IP = sh(
            script: "cd terraform && terraform output -raw public_ip",
            returnStdout: true
          ).trim()
          
          if (!env.AWS_IP) {
            error("IP publique EC2 vide : vérifiez l'output Terraform 'public_ip'.")
          }
        }
        echo "✅ AWS EC2 Public IP: ${env.AWS_IP}"
      }
    }

    stage('Build Ansible Inventory') {
      steps {
        // ⚠️ CORRECTION IMPORTANTE : Utilisation des 2 clés SSH
        withCredentials([
          sshUserPrivateKey(credentialsId: 'ssh-key-aws', keyFileVariable: 'AWS_KEY_FILE'),
          sshUserPrivateKey(credentialsId: 'ssh-key-onprem', keyFileVariable: 'ONPREM_KEY_FILE')
        ]) {
          sh '''
            # IMPORTANT : Permissions SSH obligatoires
            chmod 600 ${AWS_KEY_FILE}
            chmod 600 ${ONPREM_KEY_FILE}
            
            # Création de l'inventaire avec les 2 clés
            cat > ansible/inventory/all.ini <<EOF
[aws]
${AWS_IP} ansible_user=${AWS_USER} ansible_ssh_private_key_file=${AWS_KEY_FILE} ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'

[onprem]
${ONPREM_IP} ansible_user=${ONPREM_USER} ansible_ssh_private_key_file=${ONPREM_KEY_FILE} ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'

[all:children]
aws
onprem
EOF
            
            echo "===== Inventory generated ====="
            cat ansible/inventory/all.ini
          '''
        }
      }
    }

    stage('Ansible Connectivity Test') {
      steps {
        sh '''
          cd ansible
          ansible -i inventory/all.ini all -m ping
        '''
      }
    }

    stage('Ansible Deploy') {
      steps {
        sh '''
          cd ansible
          ansible-playbook -i inventory/all.ini playbook.yml
        '''
      }
    }

    stage('Validation HTTP') {
      steps {
        sh '''
          echo "🔍 Testing AWS HTTP..."
          curl -fsS http://${AWS_IP} | head -n 5

          echo "🔍 Testing On-prem HTTP..."
          curl -fsS http://${ONPREM_IP} | head -n 5
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'security/**/report.txt', allowEmptyArchive: true
    }
    success {
      echo """
        ✅ Déploiement réussi !
        
        URLs d'accès :
        - AWS        : http://${env.AWS_IP}
        - On-Premise : http://${ONPREM_IP}
      """
    }
    failure {
      echo '❌ Pipeline échoué - Consultez les logs'
    }
  }
}
