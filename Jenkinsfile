 pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                git 'https://github.com/Dsadio/DevSecOps_hybrid_project.git'
            }
        }

        stage('Terraform Security Scan') {
            steps {
                sh 'tfsec terraform/ > security/tfsec/report.txt'
            }
        }

        stage('Ansible Lint') {
            steps {
                sh 'ansible-lint ansible/playbook.yml > security/ansible-lint/report.txt'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'cd terraform && terraform init'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'cd terraform && terraform apply -auto-approve'
            }
        }

        stage('Ansible Deploy') {
            steps {
                sh 'cd ansible && ansible-playbook -i inventory/all.ini playbook.yml'
            }
        }

        stage('Validation') {
            steps {
                sh 'curl -f http://<IP_AWS>'
            }
        }
    }

    post {
        success {
            echo 'Deployment completed successfully.'
        }

        failure {
            echo 'Pipeline failed.'
        }
    }
}
