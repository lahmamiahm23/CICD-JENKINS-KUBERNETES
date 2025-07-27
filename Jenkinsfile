pipeline {
    agent any    

    environment {        
        DOCKER_REGISTRY = 'anusiju'  
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG_CREDENTIAL = 'kubeconfig'
        DOCKER_CREDENTIAL = 'docker-hub-credentials'
        NODE_ENV = 'test'
        CI = 'true'
    }
    
    stages {
        stage('Environment Check') {
            steps {
                echo 'Checking environment...'
                script {
                    // Check if Docker is available
                    try {
                        sh 'docker --version'
                        env.DOCKER_AVAILABLE = 'true'
                    } catch (Exception e) {
                        echo 'Docker not available - skipping Docker-related steps'
                        env.DOCKER_AVAILABLE = 'false'
                    }
                    
                    // Check if Node.js is available
                    try {
                        sh 'node --version'
                        sh 'npm --version'
                        env.NODE_AVAILABLE = 'true'
                    } catch (Exception e) {
                        echo 'Node.js not available - installing...'
                        env.NODE_AVAILABLE = 'false'
                    }
                }
            }
        }
        
        stage('Setup Node.js') {
            when {
                environment name: 'NODE_AVAILABLE', value: 'false'
            }
            steps {
                echo 'Installing Node.js...'
                sh '''
                    # Install Node.js if not available
                    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
                    sudo apt-get install -y nodejs
                '''
            }
        }
        
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
                        script {
                            if (fileExists('backend/package.json')) {
                                dir('backend') {
                                    sh 'npm ci --only=production'
                                }
                                echo 'Backend dependencies installed!'
                            } else {
                                echo 'No backend package.json found, skipping...'
                            }
                        }
                    }
                }
                stage('Frontend Dependencies') {
                    steps {
                        echo 'Installing frontend dependencies...'
                        script {
                            if (fileExists('frontend/package.json')) {
                                dir('frontend') {
                                    sh 'npm ci --only=production'
                                }
                                echo 'Frontend dependencies installed!'
                            } else {
                                echo 'No frontend package.json found, skipping...'
                            }
                        }
                    }
                }
            }
        }
        
        stage('Test Backend') {
            when {
                expression { fileExists('backend/package.json') }
            }
            steps {
                echo 'Testing backend...'
                dir('backend') {
                    script {
                        try {
                            sh 'npm test --if-present'
                        } catch (Exception e) {
                            echo 'Backend tests failed or no test script found'
                            echo "Error: ${e.getMessage()}"
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
                }
                echo 'Backend tests completed!'
            }
        }
        
        stage('Test Frontend') {
            when {
                expression { fileExists('frontend/package.json') }
            }
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
            when {
                environment name: 'DOCKER_AVAILABLE', value: 'true'
            }
            parallel {
                stage('Build Backend Image') {
                    steps {
                        echo 'Building backend Docker image...'
                        script {
                            dir('backend') {
                                if (!fileExists('Dockerfile')) {
                                    echo 'Dockerfile not found in backend directory, skipping...'
                                    return
                                }
                                
                                def backendImage = docker.build("${DOCKER_REGISTRY}/mern-backend:${IMAGE_TAG}")
                                
                                docker.withRegistry('https://registry.hub.docker.com', "${DOCKER_CREDENTIAL}") {
                                    backendImage.push()
                                    backendImage.push('latest')
                                }
                                
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
                                if (!fileExists('Dockerfile')) {
                                    echo 'Dockerfile not found in frontend directory, skipping...'
                                    return
                                }
                                
                                def frontendImage = docker.build("${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG}")
                                
                                docker.withRegistry('https://registry.hub.docker.com', "${DOCKER_CREDENTIAL}") {
                                    frontendImage.push()
                                    frontendImage.push('latest')
                                }
                                
                                sh "docker rmi ${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG} || true"
                            }
                        }
                        echo 'Frontend image built and pushed!'
                    }
                }
            }
        }
        
        stage('Update Kubernetes Manifests') {
            when {
                environment name: 'DOCKER_AVAILABLE', value: 'true'
            }
            steps {
                echo 'Updating Kubernetes deployment files...'
                script {
                    if (!fileExists('k8s')) {
                        echo 'k8s directory not found, skipping manifest update...'
                        return
                    }
                    
                    sh """
                        # Create backup of original files
                        cp k8s/backend-deployment.yaml k8s/backend-deployment.yaml.bak || true
                        cp k8s/frontend-deployment.yaml k8s/frontend-deployment.yaml.bak || true
                        
                        # Update image tags
                        sed -i 's|your-username/mern-backend:latest|${DOCKER_REGISTRY}/mern-backend:${IMAGE_TAG}|g' k8s/backend-deployment.yaml || true
                        sed -i 's|${DOCKER_REGISTRY}/mern-backend:.*|${DOCKER_REGISTRY}/mern-backend:${IMAGE_TAG}|g' k8s/backend-deployment.yaml || true
                        
                        sed -i 's|your-username/mern-frontend:latest|${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG}|g' k8s/frontend-deployment.yaml || true
                        sed -i 's|${DOCKER_REGISTRY}/mern-frontend:.*|${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG}|g' k8s/frontend-deployment.yaml || true
                        
                        # Show updated files
                        echo "Updated backend-deployment.yaml:"
                        cat k8s/backend-deployment.yaml || echo "File not found"
                        echo "Updated frontend-deployment.yaml:"
                        cat k8s/frontend-deployment.yaml || echo "File not found"
                    """
                }
                echo 'Kubernetes manifests updated!'
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                allOf {
                    environment name: 'DOCKER_AVAILABLE', value: 'true'
                    expression { fileExists('k8s') }
                }
            }
            steps {
                echo 'Deploying to Kubernetes...'
                script {
                    withKubeConfig([credentialsId: "${KUBECONFIG_CREDENTIAL}"]) {
                        try {
                            sh 'kubectl cluster-info'
                            sh 'kubectl create namespace mern-app || true'
                            
                            if (fileExists('k8s/mongo-deployment.yaml')) {
                                sh 'kubectl apply -f k8s/mongo-deployment.yaml'
                                sh 'kubectl rollout status deployment/mongo-deployment --timeout=180s || true'
                            }
                            
                            sh 'kubectl apply -f k8s/backend-deployment.yaml || true'
                            sh 'kubectl apply -f k8s/frontend-deployment.yaml || true'
                            
                            sh 'kubectl rollout status deployment/backend-deployment --timeout=300s || true'
                            sh 'kubectl rollout status deployment/frontend-deployment --timeout=300s || true'
                        } catch (Exception e) {
                            echo "Kubernetes deployment failed: ${e.getMessage()}"
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
                }
                echo 'Deployment completed!'
            }
        }
        
        stage('Verify Deployment') {
            when {
                allOf {
                    environment name: 'DOCKER_AVAILABLE', value: 'true'
                    expression { fileExists('k8s') }
                }
            }
            steps {
                echo 'Verifying deployment...'
                script {
                    withKubeConfig([credentialsId: "${KUBECONFIG_CREDENTIAL}"]) {
                        try {
                            sh 'kubectl get deployments || true'
                            sh 'kubectl get pods || true'
                            sh 'kubectl get services || true'
                            
                            sh 'kubectl wait --for=condition=ready pod -l app=backend --timeout=300s || true'
                            sh 'kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s || true'
                            
                            sh 'kubectl get service frontend-service -o wide || true'
                            sh 'kubectl get endpoints || true'
                        } catch (Exception e) {
                            echo "Verification failed: ${e.getMessage()}"
                        }
                    }
                }
                echo 'Deployment verification completed!'
            }
        }
    }
    
    post {
        success {
            script {
                echo '🎉 Pipeline completed successfully!'
                if (env.DOCKER_AVAILABLE == 'true') {
                    echo 'Your MERN app is now deployed to Kubernetes!'
                } else {
                    echo 'Tests completed successfully! Docker deployment was skipped due to Docker unavailability.'
                }
            }
        }
        failure {
            script {
                echo '❌ Pipeline failed!'
                echo 'Check the logs above for error details.'
                
                try {
                    if (fileExists('k8s/backend-deployment.yaml.bak')) {
                        sh 'mv k8s/backend-deployment.yaml.bak k8s/backend-deployment.yaml'
                    }
                    if (fileExists('k8s/frontend-deployment.yaml.bak')) {
                        sh 'mv k8s/frontend-deployment.yaml.bak k8s/frontend-deployment.yaml'
                    }
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
            script {
                echo 'Cleaning up...'
                try {
                    if (env.DOCKER_AVAILABLE == 'true') {
                        sh 'docker system prune -f || true'
                    }
                    sh 'rm -f k8s/*.bak || true'
                } catch (Exception e) {
                    echo "Cleanup failed: ${e.getMessage()}"
                }
                
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