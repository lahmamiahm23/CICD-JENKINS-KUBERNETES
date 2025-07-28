FROM jenkins/jenkins:lts

USER root

# Install prerequisites, Node.js, npm, and Docker CLI
RUN apt-get update && \
    apt-get install -y curl gnupg2 lsb-release apt-transport-https ca-certificates software-properties-common && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs docker.io && \
    npm install -g npm@latest && \
    apt-get clean

# Verify installations
RUN node -v && npm -v && docker --version

# Switch back to Jenkins user
USER jenkins
