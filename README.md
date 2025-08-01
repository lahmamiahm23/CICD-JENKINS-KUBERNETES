# Complete YouTube Script: Kubernetes CI/CD Pipeline Using Jenkins for MERN Stack Beginners
We're building a complete CI/CD pipeline using Jenkins and Kubernetes that will automate everything from code commit to live deployment. And I'm going to show you every single step, even if you're a complete beginner.

**[What We'll Cover]**
"Here's exactly what we'll build together:
- Complete MERN stack application setup
- Jenkins pipeline configuration
- Docker containerization
- Kubernetes deployment
- Automatic deployments on code changes

### What is CI/CD?
"Before we jump into coding, let's understand what CI/CD actually means:

**Continuous Integration (CI):** Every time you push code to your repository, it automatically builds and tests your application. Think of it as a safety net that catches bugs before they reach production.

**Continuous Deployment (CD):** Once your code passes all tests, it automatically deploys to your live environment without any manual intervention."

### Our Complete Workflow Diagram

[Developer] → [Git Push] → [GitHub/GitLab]
                              ↓
[Jenkins Pipeline Triggered]
                              ↓
[Build MERN App] → [Run Tests] → [Build Docker Images]
                              ↓
[Push to Registry] → [Deploy to Kubernetes] → [Live Application]

### Tools We'll Use
"Here are all the tools in our pipeline and why we need each one:

1. **Git/GitHub:** Version control and trigger point
2. **Jenkins:** Our automation server that orchestrates everything
3. **Docker:** Containerizes our application for consistency
4. **Kubernetes:** Manages and scales our containers
5. **MERN Stack:** MongoDB, Express, React, Node.js - our application stack"

### Installing Required Tools

## Prerequisites Installation (Don't Skip This!)

### 1. Install Docker Desktop
1. Go to https://www.docker.com/products/docker-desktop
2. Download and install for your OS
3. Start Docker Desktop
4. Verify installation:
->bash
docker --version
# Should show: Docker version 20.x.x

### 2. Install kubectl (Kubernetes CLI)
```bash
# Windows (using chocolatey)
choco install kubernetes-cli

# Mac (using homebrew)
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify
kubectl version --client


### Method 2: Create a Dedicated Service Account (Recommended for Jenkins)
```bash
# Create a service account for Jenkins
kubectl create serviceaccount jenkins-sa

# Create cluster role binding
kubectl create clusterrolebinding jenkins-sa-binding --clusterrole=cluster-admin --serviceaccount=default:jenkins-sa

kubectl create clusterrolebinding jenkins-sa-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=default:jenkins-sa

# Get the service account token (Kubernetes 1.24+)
kubectl create token jenkins-sa > jenkins-token.txt

# For older Kubernetes versions:
# kubectl get secret $(kubectl get serviceaccount jenkins-sa -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode
```

### Method 3: Create Kubeconfig for Jenkins
->bash
# Get cluster info
CLUSTER_NAME=$(kubectl config current-context)
CLUSTER_SERVER=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CERT=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

# Create kubeconfig file for Jenkins[Use Git Bash or WSL for windows]
cat > jenkins-kubeconfig.yaml << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CLUSTER_CERT}
    server: ${CLUSTER_SERVER}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: jenkins-sa
  name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
users:
- name: jenkins-sa
  user:
    token: $(cat jenkins-token.txt)
EOF

echo "Kubeconfig created: jenkins-kubeconfig.yaml"

## STEP 3: Create Your MERN Application[Checkout my git repo:https://github.com/CodeEaseWithAnu/CI-CD-Jenkins-Pipeline]

### Project Structure

mern-k8s-app/
├── backend/
├── frontend/
├── k8s/
├── jenkins/
└── docker-compose.yml

## STEP 4: Create Kubernetes Configurations[Already exist in git repo, you can modify according to your requirement]
### MongoDB Deployment[k8s/mongo-deployment.yaml]
### Backend Deployment[k8s/backend-deployment.yaml]
### Frontend Deploymentk8s/frontend-deployment.yaml
## STEP 5: Set Up Jenkins in Kubernetes[Already exist in git repo, you can modify according to your requirement]
### Jenkins Deployment[jenkins/jenkins-deployment.yaml]
### Deploy Jenkins[You ca use default name space or change name space name if you want]
->bash
kubectl create namespace jenkins
kubectl create serviceaccount jenkins-sa -n jenkins
kubectl apply -f jenkins/jenkins-deployment.yaml -n jenkins
# Wait for Jenkins to start (this takes 2-3 minutes)
kubectl wait --for=condition=ready pod -l app=jenkins --timeout=300s
or
kubectl get pods -n jenkins -w

# Get Jenkins URL
minikube service jenkins-service -n jenkins --url
# Copy this URL - you'll need it!

# Get initial admin password
kubectl exec -it -n jenkins $(kubectl get pod -n jenkins -l app=jenkins -o jsonpath="{.items[0].metadata.name}") -- cat /var/jenkins_home/secrets/initialAdminPassword

or 
#powershell
kubectl exec -it -n <pod-name>
 kubectl port-forward svc/jenkins-service -n jenkins 8080:8080 -c jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword

 ## STEP 6: Configure Jenkins (The Complete Setup)

### 1. Initial Jenkins Setup
1. Open the Jenkins URL from previous step
2. Enter the admin password
3. Click "Install suggested plugins"
4. Wait for plugins to install (5-10 minutes)
5. Create your admin user

### 2. Install Additional Plugins
1. Go to "Manage Jenkins" → "Manage Plugins"
2. Click "Available" tab
3. Search and install these plugins:
   - Docker Pipeline
   - Kubernetes CLI Plugin
   - Git Plugin (should already be installed)
   - Pipeline Plugin (should already be installed)
4. Restart Jenkins when prompted

### 3. Add Credentials

#### Add Docker Hub Credentials
1. Go to "Manage Jenkins" → "Manage Credentials"
2. Click "System" → "Global credentials"
3. Click "Add Credentials"
4. Select "Username with password"
5. Enter your Docker Hub username/password
6. ID: `docker-hub-credentials`
7. Click "OK"

#### Add Kubeconfig Credentials
1. Click "Add Credentials" again
2. Select "Secret file"
3. Upload the `jenkins-kubeconfig.yaml` file we created earlier
4. ID: `kubeconfig`
5. Description: "Kubernetes config for Jenkins"
6. Click "OK"

### 4. Create Your First Pipeline

#### Create New Pipeline Job
1. Click "New Item"
2. Enter name: `mern-k8s-pipeline`
3. Select "Pipeline"
4. Click "OK"

#### Configure Pipeline
1. Scroll down to "Pipeline" section
2. Select "Pipeline script from SCM"
3. SCM: Git
4. Repository URL: Your GitHub repo URL
5. Credentials: Add your GitHub credentials if private repo
6. Branch: `*/main` or `*/master`
7. Script Path: `Jenkinsfile`
8. Click "Save"

## STEP 7: Create the Jenkinsfile
Jenkinsfile` in your project root

## STEP 8: Test Your Complete Pipeline

### 1. Push Your Code to GitHub
```bash
# Initialize git repo
git init
git add .
git commit -m "Initial MERN K8s CI/CD setup"

# Add your GitHub repo (create one first!)
git remote add origin https://github.com/your-username/mern-k8s-app.git
git branch -M main
git push -u origin main
```

### 2. Update Jenkinsfile and Kubernetes Files
Before running the pipeline, update these files with your actual values:

In `Jenkinsfile`, change:
```groovy
DOCKER_REGISTRY = 'your-dockerhub-username'  // Your actual Docker Hub username
```

In `k8s/backend-deployment.yaml` and `k8s/frontend-deployment.yaml`, change:
```yaml
image: your-username/mern-backend:latest  # Your actual Docker Hub username
```

### 3. Trigger Your First Build
1. Go to Jenkins dashboard
2. Click on your `mern-k8s-pipeline` job
3. Click "Build Now"
4. Watch the magic happen!

### 4. Monitor the Build
- Click on the build number to see progress
- Click "Console Output" to see detailed logs
- The build will take 10-15 minutes first time

### 5. Access Your Application
```bash
# Get your app URL
minikube service frontend-service --url

# Copy the URL and open in browser
# You should see your MERN app running!
```

## STEP 9: Testing Continuous Deployment

### Make a Change and See Auto-Deployment
1. Edit `frontend/src/App.tsx`
2. Change the header to "MERN K8s CI/CD Demo v2.0"
3. Commit and push:
```bash
git add .
git commit -m "Update app version to v2.0"
git push origin main
```

4. Watch Jenkins automatically trigger a new build
5. Your changes will be live in 10-15 minutes!

## Troubleshooting Common Issues

### Jenkins Can't Connect to Kubernetes
```bash
# Check if kubeconfig is correct
kubectl config current-context

# Recreate kubeconfig if needed
kubectl config view --raw > jenkins-kubeconfig.yaml
```

### Docker Build Fails
```bash
# Check Docker is running
docker ps

# Check Docker Hub credentials in Jenkins
```

### Pods Stuck in Pending
```bash
# Check resource usage
kubectl top nodes
kubectl describe pod <pod-name>

# Increase minikube resources if needed
minikube stop
minikube start --memory=8192 --cpus=4
```

### Application Not Accessible
```bash
# Check services
kubectl get services

# Check if minikube tunnel is needed
minikube tunnel
```

## What You've Accomplished

Congratulations! You now have:
- ✅ A complete MERN stack application
- ✅ Jenkins running in Kubernetes
- ✅ Automated CI/CD pipeline
- ✅ Automatic testing and deployment
- ✅ Production-ready setup


