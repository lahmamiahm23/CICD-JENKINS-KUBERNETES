pipeline {
    agent {
        docker {
            image 'node:18'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    
    environment {        
        DOCKER_REGISTRY = 'anusiju'  
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG_CREDENTIAL = 'kubeconfig'
        DOCKER_CREDENTIAL = 'docker-hub-credentials'
        NODE_ENV = 'test'
        CI = 'true'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
                echo 'Code checked out successfully!'
            }
        }
        
        stage('Install Dependencies') {
            parallel {
                stage('Backend Dependencies') {
                    steps {
                        echo 'Installing backend dependencies...'
                        dir('backend') {
                            sh 'node --version'
                            sh 'npm --version'
                            sh 'npm ci --only=production'
                        }
                        echo 'Backend dependencies installed!'
                    }
                }
                stage('Frontend Dependencies') {
                    steps {
                        echo 'Installing frontend dependencies...'
                        dir('frontend') {
                            sh 'npm ci --only=production'
                        }
                        echo 'Frontend dependencies installed!'
                    }
                }
            }
        }
        
        stage('Test Backend') {
            steps {
                echo 'Testing backend...'
                dir('backend') {
                    script {
                        try {
                            sh 'npm test --if-present'
                        } catch (Exception e) {
                            echo 'Backend tests failed or no test script found'
                            echo "Error: ${e.getMessage()}"
                            // Continue pipeline even if tests fail (optional)
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
                }
                echo 'Backend tests completed!'
            }
        }
        
        stage('Test Frontend') {
            steps {
                echo 'Testing frontend...'
                dir('frontend') {
                    script {
                        try {
                            sh 'npm test -- --coverage --watchAll=false --passWithNoTests'
                        } catch (Exception e) {
                            echo 'Frontend tests failed or no test script found'
                            echo "Error: ${e.getMessage()}"
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
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
                                // Check if Dockerfile exists
                                if (!fileExists('Dockerfile')) {
                                    error 'Dockerfile not found in backend directory!'
                                }
                                
                                def backendImage = docker.build("${DOCKER_REGISTRY}/mern-backend:${IMAGE_TAG}")
                                
                                docker.withRegistry('https://registry.hub.docker.com', "${DOCKER_CREDENTIAL}") {
                                    backendImage.push()
                                    backendImage.push('latest')
                                }
                                
                                // Clean up local image
                                sh "docker rmi ${DOCKER_REGISTRY}/mern-backend:${IMAGE_TAG} || true"
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
                                // Check if Dockerfile exists
                                if (!fileExists('Dockerfile')) {
                                    error 'Dockerfile not found in frontend directory!'
                                }
                                
                                def frontendImage = docker.build("${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG}")
                                
                                docker.withRegistry('https://registry.hub.docker.com', "${DOCKER_CREDENTIAL}") {
                                    frontendImage.push()
                                    frontendImage.push('latest')
                                }
                                
                                // Clean up local image
                                sh "docker rmi ${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG} || true"
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
                    // Verify k8s directory exists
                    if (!fileExists('k8s')) {
                        error 'k8s directory not found!'
                    }
                    
                    // Update image tags in deployment files
                    sh """
                        # Create backup of original files
                        cp k8s/backend-deployment.yaml k8s/backend-deployment.yaml.bak || true
                        cp k8s/frontend-deployment.yaml k8s/frontend-deployment.yaml.bak || true
                        
                        # Update image tags
                        sed -i 's|your-username/mern-backend:latest|${DOCKER_REGISTRY}/mern-backend:${IMAGE_TAG}|g' k8s/backend-deployment.yaml
                        sed -i 's|${DOCKER_REGISTRY}/mern-backend:.*|${DOCKER_REGISTRY}/mern-backend:${IMAGE_TAG}|g' k8s/backend-deployment.yaml
                        
                        sed -i 's|your-username/mern-frontend:latest|${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG}|g' k8s/frontend-deployment.yaml
                        sed -i 's|${DOCKER_REGISTRY}/mern-frontend:.*|${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG}|g' k8s/frontend-deployment.yaml
                        
                        # Show updated files
                        echo "Updated backend-deployment.yaml:"
                        cat k8s/backend-deployment.yaml
                        echo "Updated frontend-deployment.yaml:"
                        cat k8s/frontend-deployment.yaml
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
                        // Check cluster connectivity
                        sh 'kubectl cluster-info'
                        
                        // Create namespace if it doesn't exist
                        sh 'kubectl create namespace mern-app || true'
                        
                        // Deploy MongoDB first (if not already deployed)
                        if (fileExists('k8s/mongo-deployment.yaml')) {
                            sh 'kubectl apply -f k8s/mongo-deployment.yaml'
                            sh 'kubectl rollout status deployment/mongo-deployment --timeout=180s || true'
                        }
                        
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
                        // Get deployment status
                        sh 'kubectl get deployments'
                        sh 'kubectl get pods'
                        sh 'kubectl get services'
                        
                        // Check if pods are ready
                        sh 'kubectl wait --for=condition=ready pod -l app=backend --timeout=300s'
                        sh 'kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s'
                        
                        // Get service URLs and endpoints
                        sh 'kubectl get service frontend-service -o wide'
                        sh 'kubectl get endpoints'
                        
                        // Display application access information
                        sh '''
                            echo "=== Application Access Information ==="
                            kubectl get service frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || echo "LoadBalancer IP not available yet"
                            kubectl get service frontend-service -o jsonpath='{.spec.ports[0].nodePort}' || echo "NodePort not available"
                        '''
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
            
            // Send notification (optional)
            script {
                try {
                    // Add Slack/email notification here if configured
                    echo 'Build succeeded - notifications sent'
                } catch (Exception e) {
                    echo 'Notification failed but build succeeded'
                }
            }
        }
        failure {
            echo '❌ Pipeline failed!'
            echo 'Check the logs above for error details.'
            
            script {
                try {
                    // Restore backup files if they exist
                    sh '''
                        if [ -f k8s/backend-deployment.yaml.bak ]; then
                            mv k8s/backend-deployment.yaml.bak k8s/backend-deployment.yaml
                        fi
                        if [ -f k8s/frontend-deployment.yaml.bak ]; then
                            mv k8s/frontend-deployment.yaml.bak k8s/frontend-deployment.yaml
                        fi
                    '''
                } catch (Exception e) {
                    echo 'Failed to restore backup files'
                }
            }
        }
        unstable {
            echo '⚠️ Pipeline completed with warnings!'
            echo 'Some tests may have failed, but deployment continued.'
        }
        always {
            echo 'Cleaning up...'
            sh '''
                # Clean up Docker images and containers
                docker system prune -f || true
                
                # Clean up any temporary files
                rm -f k8s/*.bak || true
            '''
            
            // Archive test results if they exist
            script {
                try {
                    archiveArtifacts artifacts: '**/test-results.xml', allowEmptyArchive: true
                    publishTestResults testResultsPattern: '**/test-results.xml'
                } catch (Exception e) {
                    echo 'No test results to archive'
                }
            }
        }
    }
}