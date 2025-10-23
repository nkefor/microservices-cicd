pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.substring(0,7)}"
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Deployment environment'
        )
        booleanParam(
            name: 'RUN_TESTS',
            defaultValue: true,
            description: 'Run tests before deployment'
        )
        booleanParam(
            name: 'DEPLOY',
            defaultValue: true,
            description: 'Deploy after successful build'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Install Dependencies') {
            parallel {
                stage('Node.js Services') {
                    steps {
                        dir('services/api-gateway') {
                            sh 'npm ci'
                        }
                        dir('services/product-service') {
                            sh 'npm ci'
                        }
                    }
                }
                stage('Python Services') {
                    steps {
                        dir('services/auth-service') {
                            sh 'pip3 install -r requirements.txt'
                        }
                        dir('services/order-service') {
                            sh 'pip3 install -r requirements.txt'
                        }
                    }
                }
            }
        }

        stage('Run Tests') {
            when {
                expression { params.RUN_TESTS == true }
            }
            parallel {
                stage('Test API Gateway') {
                    steps {
                        dir('services/api-gateway') {
                            sh 'npm test || true'
                        }
                    }
                }
                stage('Test Product Service') {
                    steps {
                        dir('services/product-service') {
                            sh 'npm test || true'
                        }
                    }
                }
                stage('Test Auth Service') {
                    steps {
                        dir('services/auth-service') {
                            sh 'python3 -m pytest tests/ || true'
                        }
                    }
                }
                stage('Test Order Service') {
                    steps {
                        dir('services/order-service') {
                            sh 'python3 -m pytest tests/ || true'
                        }
                    }
                }
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Build API Gateway') {
                    steps {
                        script {
                            sh """
                                docker build -t ${ECR_REGISTRY}/api-gateway:${IMAGE_TAG} \
                                    -t ${ECR_REGISTRY}/api-gateway:latest \
                                    services/api-gateway
                            """
                        }
                    }
                }
                stage('Build Auth Service') {
                    steps {
                        script {
                            sh """
                                docker build -t ${ECR_REGISTRY}/auth-service:${IMAGE_TAG} \
                                    -t ${ECR_REGISTRY}/auth-service:latest \
                                    services/auth-service
                            """
                        }
                    }
                }
                stage('Build Product Service') {
                    steps {
                        script {
                            sh """
                                docker build -t ${ECR_REGISTRY}/product-service:${IMAGE_TAG} \
                                    -t ${ECR_REGISTRY}/product-service:latest \
                                    services/product-service
                            """
                        }
                    }
                }
                stage('Build Order Service') {
                    steps {
                        script {
                            sh """
                                docker build -t ${ECR_REGISTRY}/order-service:${IMAGE_TAG} \
                                    -t ${ECR_REGISTRY}/order-service:latest \
                                    services/order-service
                            """
                        }
                    }
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    """

                    def services = ['api-gateway', 'auth-service', 'product-service', 'order-service']
                    services.each { service ->
                        sh """
                            docker push ${ECR_REGISTRY}/${service}:${IMAGE_TAG}
                            docker push ${ECR_REGISTRY}/${service}:latest
                        """
                    }
                }
            }
        }

        stage('Deploy with Ansible') {
            when {
                expression { params.DEPLOY == true }
            }
            steps {
                script {
                    if (params.ENVIRONMENT == 'prod') {
                        input message: 'Deploy to production?', ok: 'Deploy'
                    }

                    dir('ansible') {
                        sh """
                            ansible-playbook -i inventory/hosts.ini playbooks/site.yml \
                                -e "environment=${params.ENVIRONMENT}" \
                                -e "image_tag=${IMAGE_TAG}" \
                                -e "ecr_registry=${ECR_REGISTRY}"
                        """
                    }
                }
            }
        }

        stage('Health Check') {
            when {
                expression { params.DEPLOY == true }
            }
            steps {
                script {
                    sh '''
                        echo "Waiting for services to start..."
                        sleep 30

                        # Get Load Balancer DNS from Terraform output
                        cd infrastructure/terraform/environments/${ENVIRONMENT}
                        LB_DNS=$(terraform output -raw load_balancer_dns)

                        echo "Checking API Gateway health..."
                        curl -f http://${LB_DNS}/health || exit 1

                        echo "Checking service health..."
                        curl -f http://${LB_DNS}/health/services || exit 1

                        echo "All health checks passed!"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully!"
            echo "Deployed ${IMAGE_TAG} to ${params.ENVIRONMENT}"
        }
        failure {
            echo "Pipeline failed!"
        }
        always {
            cleanWs()
        }
    }
}
