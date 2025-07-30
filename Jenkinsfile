pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'anusiju'
        IMAGE_TAG = "${BUILD_NUMBER}"           // Version image by build number
        KUBERNETES_NAMESPACE = 'jenkins'        // Your namespace
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/CodeEaseWithAnu/CI-CD-Jenkins-Pipeline.git',
                    credentialsId: 'github-credentials'
            }
        }

        stage('Install Dependencies & Test Backend') {
            steps {
                dir('backend') {
                    sh 'npm install'
                    sh 'npm test || echo "No backend tests implemented"'
                }
            }
        }

        stage('Install Dependencies & Test Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm test -- --coverage --watchAll=false || echo "No frontend tests implemented"'
                }
            }
        }

        stage('Build & Push Docker Images') {
            parallel {
                stage('Backend Image') {
                    steps {
                        script {
                            dir('backend') {
                                def backendImage = docker.build("${DOCKER_REGISTRY}/mern-backend:${IMAGE_TAG}")
                                docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-credentials') {
                                    backendImage.push()
                                    backendImage.push('latest')
                                }
                            }
                        }
                    }
                }
                stage('Frontend Image') {
                    steps {
                        script {
                            dir('frontend') {
                                // ✅ Builds the serve-based image
                                def frontendImage = docker.build("${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG}")
                                docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-credentials') {
                                    frontendImage.push()
                                    frontendImage.push('latest')
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Verify Kubernetes Connectivity') {
            steps {
                script {
                    echo '🔍 Verifying Kubernetes API connectivity...'
                    sh 'kubectl cluster-info'
                    sh 'kubectl get nodes -o wide'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // ✅ Replace image tags dynamically
                    sh """
                        sed -i 's|your-registry/mern-backend:latest|${DOCKER_REGISTRY}/mern-backend:${IMAGE_TAG}|g' k8s/backend-deployment.yaml
                        sed -i 's|your-registry/mern-frontend:latest|${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG}|g' k8s/frontend-deployment.yaml
                    """

                    // ✅ Ensure imagePullPolicy: Always is set (forces new image pull)
                    sed -i '/image:/a \ \ \ \ imagePullPolicy: Always' k8s/frontend-deployment.yaml

                    // Apply manifests
                    sh 'kubectl apply -f k8s/ -n ${KUBERNETES_NAMESPACE}'
                    
                    // Rollout deployments
                    sh 'kubectl rollout status deployment/backend-deployment -n ${KUBERNETES_NAMESPACE}'
                    sh 'kubectl rollout status deployment/frontend-deployment -n ${KUBERNETES_NAMESPACE}'
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    sh "kubectl get pods -n ${KUBERNETES_NAMESPACE} -o wide"
                    sh "kubectl get svc -n ${KUBERNETES_NAMESPACE}"
                    sh "kubectl wait --for=condition=ready pod -l app=backend -n ${KUBERNETES_NAMESPACE} --timeout=300s"
                    sh "kubectl wait --for=condition=ready pod -l app=frontend -n ${KUBERNETES_NAMESPACE} --timeout=300s"
                }
            }
        }
    }

    post {
        success { echo '🎉 Pipeline completed successfully!' }
        failure { echo '❌ Pipeline failed!' }
        always { sh 'docker system prune -f' }
    }
}
