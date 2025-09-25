#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: havardthom
# License: MIT | https://github.com/Dbz9/OpenWebUI-AMD-6600/raw/main/LICENSE
# Source: https://openwebui.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git \
  ffmpeg
msg_ok "Installed Dependencies"

msg_info "Setup Python3"
$STD apt-get install -y --no-install-recommends \
  python3 \
  python3-pip \
  python3-setuptools \
  python3-wheel
msg_ok "Setup Python3"

NODE_VERSION="22" setup_nodejs

msg_info "Installing Open WebUI (Patience)"
$STD git clone https://github.com/open-webui/open-webui.git /opt/open-webui
cd /opt/open-webui/backend
$STD pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
$STD pip3 install -r requirements.txt -U
cd /opt/open-webui
cp .env.example .env
cat <<EOF >/opt/open-webui/.env
ENV=prod
ENABLE_OLLAMA_API=false
OLLAMA_BASE_URL=http://0.0.0.0:11434
EOF
$STD npm install --force
export NODE_OPTIONS="--max-old-space-size=3584"
$STD npm run build
msg_ok "Installed Open WebUI"

read -r -p "${TAB3}Would you like to add Ollama? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Ollama"
  wget -c --tries=5 --waitretry=10 --timeout=7200 -O ollama-linux-amd64.tgz https://ollama.com/download/ollama-linux-amd64.tgz
  tar -C /usr -xzf ollama-linux-amd64.tgz
  rm -rf ollama-linux-amd64.tgz

  cat <<EOF >/etc/systemd/system/ollama.service
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
Type=exec
ExecStart=/usr/bin/ollama serve
Environment=HOME=$HOME
Environment=OLLAMA_HOST=0.0.0.0
Environment=HSA_OVERRIDE_GFX_VERSION=10.3.0
Environment=ROCR_VISIBLE_DEVICES=0
Environment=HIP_VISIBLE_DEVICES=0
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

  systemctl enable -q --now ollama
  sed -i 's/ENABLE_OLLAMA_API=false/ENABLE_OLLAMA_API=true/g' /opt/open-webui/.env
  msg_ok "Installed Ollama"

  # --- AMD ROCm installation ---
  msg_info "Installing ROCm for AMD GPU"
  wget -c --tries=5 --waitretry=10 --timeout=7200 -O ollama-linux-amd64-rocm.tgz https://ollama.com/download/ollama-linux-amd64-rocm.tgz
  tar -C /usr -xzf ollama-linux-amd64-rocm.tgz
  rm -rf ollama-linux-amd64-rocm.tgz
  msg_ok "ROCm libraries installed for AMD GPU"

  # --- ROCm GPU permissions ---
  msg_info "Configuring permissions for ROCm GPU access"
  $STD sudo usermod -a -G render,video $LOGNAME
  $STD echo 'ADD_EXTRA_GROUPS=1' | sudo tee -a /etc/adduser.conf
  $STD echo 'EXTRA_GROUPS=video' | sudo tee -a /etc/adduser.conf
  $STD echo 'EXTRA_GROUPS=render' | sudo tee -a /etc/adduser.conf
  msg_ok "ROCm GPU permissions configured"
fi

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/open-webui.service
[Unit]
Description=Open WebUI Service
After=network.target

[Service]
Type=exec
WorkingDirectory=/opt/open-webui
EnvironmentFile=/opt/open-webui/.env
ExecStart=/opt/open-webui/backend/start.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now open-webui
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
