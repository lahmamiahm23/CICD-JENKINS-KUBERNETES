FROM jenkins/jenkins:lts

USER root

# Install Docker CLI and Node.js v20
RUN apt-get update && \
    apt-get install -y curl gnupg2 ca-certificates apt-transport-https software-properties-common && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs docker.io && \
    npm install -g npm@latest && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN node -v && npm -v && docker --version
