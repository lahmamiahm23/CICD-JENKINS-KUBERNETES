pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'anusiju'
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG_CREDENTIAL = 'kubeconfig'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/CodeEaseWithAnu/CI-CD-Jenkins-Pipeline.git',
                    credentialsId: 'github-credentials'
                echo 'Code checked out successfully'
            }
        }

        stage('Install Dependencies & Test Backend') {
            steps {
                dir('backend') {
                    sh 'npm install'
                    sh 'npm test'
                }
            }
        }

        stage('Install Dependencies & Test Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm test -- --coverage --watchAll=false'
                }
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Build Backend Image') {
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
                stage('Build Frontend Image') {
                    steps {
                        script {
                            dir('frontend') {
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

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Fetch the current Minikube API server dynamically
                    def KUBE_API = sh(script: "kubectl config view -o jsonpath='{.clusters[0].cluster.server}'", returnStdout: true).trim()

                    // Update image references in YAML files
                    sh """
                        sed -i 's|your-registry/mern-backend:latest|${DOCKER_REGISTRY}/mern-backend:${IMAGE_TAG}|g' k8s/backend-deployment.yaml
                        sed -i 's|your-registry/mern-frontend:latest|${DOCKER_REGISTRY}/mern-frontend:${IMAGE_TAG}|g' k8s/frontend-deployment.yaml
                    """

                    // Use dynamic API endpoint for deployment
                    withKubeConfig([credentialsId: 'kubeconfig', serverUrl: "${KUBE_API}", skipTlsVerify: true]) {
                        sh 'kubectl apply --validate=false -f k8s/'
                        sh 'kubectl rollout status deployment/backend-deployment'
                        sh 'kubectl rollout status deployment/frontend-deployment'
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    def KUBE_API = sh(script: "kubectl config view -o jsonpath='{.clusters[0].cluster.server}'", returnStdout: true).trim()

                    withKubeConfig([credentialsId: 'kubeconfig', serverUrl: "${KUBE_API}", skipTlsVerify: true]) {
                        sh 'kubectl get pods'
                        sh 'kubectl get services'
                        sh 'kubectl wait --for=condition=ready pod -l app=backend --timeout=300s'
                        sh 'kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s'
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            sh 'docker system prune -f'
        }
    }
}
