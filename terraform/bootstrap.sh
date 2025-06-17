#!/bin/bash

LOG_FILE="/var/log/strapi-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

error_exit() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1"
    exit 1
}

log "Starting Strapi Bootstrap Script..."

log "Updating system..."
sudo apt update -y && sudo apt upgrade -y || error_exit "System update failed."

log "Installing dependencies..."
sudo apt install -y git curl unzip apt-transport-https ca-certificates software-properties-common gnupg lsb-release \
    || error_exit "Failed to install base dependencies."

log "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    || error_exit "Docker GPG key fetch failed."

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || error_exit "Failed to add Docker repo."

sudo apt update -y && sudo apt install -y docker-ce docker-ce-cli containerd.io \
    || error_exit "Docker installation failed."

log "Starting Docker service..."
sudo systemctl enable docker && sudo systemctl start docker || error_exit "Failed to start Docker."

log "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose || error_exit "Failed to download Docker Compose."
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || error_exit "Docker Compose installation failed."

log "Adding 'ubuntu' user to docker group..."
sudo usermod -aG docker ubuntu || log "Warning: Failed to add user to Docker group."

log "Cloning Strapi repository..."
sudo mkdir -p /home/ubuntu/app && cd /home/ubuntu/app || error_exit "Failed to create app directory."
sudo git clone https://github.com/Siddhant00Tiwari/strapi.git || error_exit "Git clone failed."
cd strapi || error_exit "Failed to enter strapi directory."

log "Creating required upload directories..."
sudo mkdir -p ./public/uploads && sudo chown -R ubuntu:ubuntu ./public || error_exit "Failed to prepare upload directory."

log "Starting Docker containers using Compose..."
sudo docker compose up -d || error_exit "Docker Compose failed to start containers."

log "✅ Bootstrap completed successfully."
