pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    TF_IN_AUTOMATION = "true"
    ONPREM_IP   = "192.168.1.6"
    ONPREM_USER = "sadio"
    AWS_USER    = "ubuntu"
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
          tfsec terraform/ --no-color | tee security/tfsec/report.txt
        '''
      }
    }

    stage('Quality - ansible-lint') {
      steps {
        sh '''
          mkdir -p security/ansible-lint
          ansible-lint ansible/playbook.yml | tee security/ansible-lint/report.txt
        '''
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                          usernameVariable: 'AWS_ACCESS_KEY_ID',
                          passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
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
            cd terraform
            terraform apply -auto-approve -no-color
          '''
        }
      }
    }

    stage('Get EC2 Public IP (Terraform output)') {
      steps {
        script {
          env.AWS_IP = sh(
            script: "cd terraform && terraform output -raw public_ip",
            returnStdout: true
          ).trim()
        }
        echo "AWS EC2 Public IP detected: ${env.AWS_IP}"
      }
    }

    stage('Build Ansible Inventory (AWS + On-prem)') {
      steps {
        sh '''
          cat > ansible/inventory/all.ini <<EOF
[aws]
${AWS_IP} ansible_user=${AWS_USER} ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[onprem]
${ONPREM_IP} ansible_user=${ONPREM_USER} ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[all:children]
aws
onprem
EOF
          echo "===== Inventory generated ====="
          cat ansible/inventory/all.ini
        '''
      }
    }

    stage('Ansible Deploy') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-key-hybrid',
                          keyFileVariable: 'SSH_KEY_FILE',
                          usernameVariable: 'SSH_USER')]) {
          sh '''
            cd ansible
            export ANSIBLE_PRIVATE_KEY_FILE=${SSH_KEY_FILE}
            ansible-playbook -i inventory/all.ini playbook.yml
          '''
        }
      }
    }

    stage('Validation (HTTP)') {
      steps {
        sh '''
          echo "Testing AWS HTTP..."
          curl -fsS http://${AWS_IP} | head -n 5

          echo "Testing On-prem HTTP..."
          curl -fsS http://${ONPREM_IP} | head -n 5
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'security/**/report.txt', fingerprint: true
    }
    success {
      echo 'Deployment completed successfully.'
    }
    failure {
      echo 'Pipeline failed.'
    }
  }
}
