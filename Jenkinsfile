pipeline {
    agent any
    
    environment {        
        DOCKER_REGISTRY = 'anusiju'  
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG_CREDENTIAL = 'kubeconfig'
        DOCKER_CREDENTIAL = 'docker-hub-credentials'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
                echo 'Code checked out successfully!'
            }
        }
        
        stage('Test Backend') {
            steps {
                echo 'Testing backend...'
                dir('backend') {
                    sh 'npm install'
                    sh 'npm test'
                }
                echo 'Backend tests completed!'
            }
        }
        
        stage('Test Frontend') {
            steps {
                echo 'Testing frontend...'
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm test -- --coverage --watchAll=false'
                }
                echo 'Frontend tests completed!'
            }
        }
        
        stage('Build Docker Images') {
            parallel {
                stage('Build Backend Image') {
                    steps {
                        echo 'Building backend Docker image...'
                        script {
                            dir('backend') {
                                def backendImage = docker.build("${DOCKER_REGISTRY}/mern-backend:${IMAGE_TAG}")
                                docker.withRegistry('https://registry.hub.docker.com', "${DOCKER_CREDENTIAL}") {
                                    backendImage.push()
                                    backendImage.push('latest')
                                }
                            }
                        }
                        echo 'Backend image built and pushed!'
                    }
                }
                stage('Build Frontend Image') {
                    steps {
                        echo 'Building frontend Docker image...'
                        script {
                            dir('frontend') {
                                def frontendImage = docker.build("${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG}")
                                docker.withRegistry('https://registry.hub.docker.com', "${DOCKER_CREDENTIAL}") {
                                    frontendImage.push()
                                    frontendImage.push('latest')
                                }
                            }
                        }
                        echo 'Frontend image built and pushed!'
                    }
                }
            }
        }
        
        stage('Update Kubernetes Manifests') {
            steps {
                echo 'Updating Kubernetes deployment files...'
                script {
                    // Update image tags in deployment files
                    sh """
                        sed -i 's|your-username/mern-backend:latest|${DOCKER_REGISTRY}/mern-backend:${IMAGE_TAG}|g' k8s/backend-deployment.yaml
                        sed -i 's|your-username/mern-frontend:latest|${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG}|g' k8s/frontend-deployment.yaml
                    """
                }
                echo 'Kubernetes manifests updated!'
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes...'
                script {
                    withKubeConfig([credentialsId: "${KUBECONFIG_CREDENTIAL}"]) {
                        // Deploy MongoDB first (if not already deployed)
                        sh 'kubectl apply -f k8s/mongo-deployment.yaml'
                        
                        // Deploy backend and frontend
                        sh 'kubectl apply -f k8s/backend-deployment.yaml'
                        sh 'kubectl apply -f k8s/frontend-deployment.yaml'
                        
                        // Wait for deployments to complete
                        sh 'kubectl rollout status deployment/backend-deployment --timeout=300s'
                        sh 'kubectl rollout status deployment/frontend-deployment --timeout=300s'
                    }
                }
                echo 'Deployment completed!'
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo 'Verifying deployment...'
                script {
                    withKubeConfig([credentialsId: "${KUBECONFIG_CREDENTIAL}"]) {
                        sh 'kubectl get pods'
                        sh 'kubectl get services'
                        
                        // Check if pods are ready
                        sh 'kubectl wait --for=condition=ready pod -l app=backend --timeout=300s'
                        sh 'kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s'
                        
                        // Get service URLs
                        sh 'kubectl get service frontend-service'
                    }
                }
                echo 'Deployment verification completed!'
            }
        }
    }
    
    post {
        success {
            echo '🎉 Pipeline completed successfully!'
            echo 'Your MERN app is now deployed to Kubernetes!'
        }
        failure {
            echo '❌ Pipeline failed!'
            echo 'Check the logs above for error details.'
        }
        always {
            echo 'Cleaning up...'
            sh 'docker system prune -f || true'
        }
    }
}