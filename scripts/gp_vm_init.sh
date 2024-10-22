#!/bin/bash

sudo apt-get update -y
sudo apt update -y

# ========== Install build-essential ========== #
sudo apt install -y build-essential

# ========== Install Docker ========== #
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y
apt-cache policy docker-ce | grep "Candidate"
sudo apt install -y docker-ce

sudo usermod -aG docker ${USER}
newgrp docker <<EOF
groups
docker ps -a
EOF

# ========== Install Nvm and Node20 ========== #
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install 20

# ========== Install Miniconda ========== #
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b
source "$HOME/miniconda3/bin/activate"
conda init
# Exit and re-enter the shell to activate conda
# Default Python version is 3.12

# ========== Install Pipx and Poetry ========== #
python -m pip install --user pipx
python -m pipx ensurepath
source ~/.bashrc
pipx install poetry

