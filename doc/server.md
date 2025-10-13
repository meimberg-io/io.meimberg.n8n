## Prepare Repo

```bash
# Add Dockers official GPG key:
apt-get update
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
```
## Install Docker
```bash
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
# Home und User
```sh
mkdir /srv/n8n
useradd -d /srv/n8n -s /bin/bash n8n
usermod -g docker n8n
chown -R n8n:n8n /srv/n8n
su - n8n
```
## SSH

```sh
cd ~
mkdir .ssh && chmod 700 .ssh
touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys
vim .ssh/authorized_keys   #### user github deploy und oli
```

# n8n App

## Volume erzeugen
```bash
# als user n8n
cd ~
docker volume create n8n_data
# docker run -it --rm --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n # nur für manuellen start
```
## Service

**Erstelle eine neue Systemd-Unit-Datei für n8n**
```bash
# ab hier als root oder sudo 
sudo vim /etc/systemd/system/n8n.service
```

**Füge den folgenden Inhalt ein**
```config
[Unit]
Description=n8n Workflow Automation
After=network.target docker.service
Requires=docker.service

[Service]
Restart=always
ExecStartPre=-/usr/bin/docker rm -f n8n

ExecStart=/usr/bin/docker run --name n8n  \
  -e WEBHOOK_URL="https://n8n.meimberg.io" \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -v /srv/n8n/backup:/home/node/backup \
  --user 1000:1000 \
  n8n-custom
ExecStop=/usr/bin/docker stop n8n

[Install]
WantedBy=multi-user.target
```

**systemd Service aktivieren und starten:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable n8n
sudo systemctl start n8n

sudo systemctl status n8n   # optional status prüfen
```

