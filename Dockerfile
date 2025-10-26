# Utiliser l'image officielle Jenkins LTS
FROM jenkins/jenkins:lts

# Passer en utilisateur root pour installer des packages
USER root

# Installer Node.js v20 et npm
RUN apt-get update && \
    apt-get install -y curl gnupg2 ca-certificates apt-transport-https lsb-release && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Vérifier les versions installées
RUN node -v && npm -v
