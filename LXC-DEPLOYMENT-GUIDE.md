# 🐧 LXC Container Deployment Guide
## Girlfriend Alert App

This guide will help you deploy the Girlfriend Alert app as an LXC container, making it accessible from anywhere on your network with better security and isolation.

## 📋 Prerequisites

### On Your Host System (Windows/Linux)
- **LXC/LXD installed** (or access to a Linux server with LXC)
- **Network access** to the container host
- **Basic terminal/SSH knowledge**

### Quick LXC Setup Options

#### Option 1: Windows with WSL2
```powershell
# Install WSL2 if not already installed
wsl --install Ubuntu

# Enter WSL2
wsl

# Install LXD in WSL2
sudo snap install lxd
sudo lxd init --auto
```

#### Option 2: Linux Server/VPS
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install lxd
sudo lxd init --auto

# Add your user to lxd group
sudo usermod -a -G lxd $USER
newgrp lxd
```

#### Option 3: Using Proxmox/TrueNAS/Other Virtualization
- Create an Ubuntu 22.04 LXC container through your web interface
- Allocate at least 1GB RAM, 10GB storage
- Enable nesting if available

## 🚀 Deployment Steps

### Step 1: Create the Container

```bash
# Create Ubuntu 22.04 container
lxc launch ubuntu:22.04 girlfriend-alert

# Wait for container to start
lxc exec girlfriend-alert -- cloud-init status --wait

# Enter the container
lxc exec girlfriend-alert -- bash
```

### Step 2: Install Dependencies in Container

```bash
# Update system
apt update && apt upgrade -y

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs git

# Alternative if the above doesn't work:
# apt install -y nodejs npm git

# If npm is still missing, install it separately:
# apt install -y npm

# Verify installation
node --version
npm --version

# If npm command is still not found, try:
# ln -s /usr/bin/nodejs /usr/bin/node (if needed)
# apt install npm --fix-missing
```

### Step 3: Copy Your App to Container

#### Method A: Direct Copy (from host)
```bash
# From your Windows/host system
# Copy entire project to container
lxc file push -r "c:\Users\Jakob\Documents\GitHub\girlfriend-alert" girlfriend-alert/home/appuser/app/ --create-dirs

# Set permissions
lxc exec girlfriend-alert -- chown -R appuser:appuser /home/appuser/app
```

#### Method B: Git Clone (recommended for updates)
```bash
# Inside container, switch to app user
su - appuser
cd /home/appuser/app

# Clone your repository (you'll need to push to GitHub first)
git clone https://github.com/YOUR-USERNAME/girlfriend-alert.git
cd girlfriend-alert

# Or create the files manually if no git repo
mkdir girlfriend-alert && cd girlfriend-alert
```

### Step 4: Setup App in Container

```bash
# As appuser in container
cd /home/appuser/app/girlfriend-alert

# Install dependencies
npm install
cd client && npm install && cd ..

# Build React app
cd client && npm run build && cd ..

# Generate VAPID keys
npx web-push generate-vapid-keys > vapid-keys.txt

# Create environment file
cat > .env << EOF
VAPID_PUBLIC_KEY=YOUR_PUBLIC_KEY_HERE
VAPID_PRIVATE_KEY=YOUR_PRIVATE_KEY_HERE
PORT=5000
NODE_ENV=production
EOF

# Copy VAPID keys from vapid-keys.txt to .env file
nano .env  # Edit and paste the keys
```

### Step 5: Create Systemd Service

```bash
# As root in container
exit  # Exit from appuser

# Create systemd service
cat > /etc/systemd/system/girlfriend-alert.service << EOF
[Unit]
Description=Girlfriend Alert App
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/home/appuser/app/girlfriend-alert
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable girlfriend-alert
systemctl start girlfriend-alert

# Check status
systemctl status girlfriend-alert
```

#### Alternative: Running as Root (Not Recommended for Production)

If you prefer to run as root (less secure but simpler):

```bash
# Create systemd service for root user
cat > /etc/systemd/system/girlfriend-alert.service << EOF
[Unit]
Description=Girlfriend Alert App
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/girlfriend-alert
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable girlfriend-alert
systemctl start girlfriend-alert

# Check status
systemctl status girlfriend-alert
```

### Step 6: Configure Container Networking

```bash
# Exit container
exit

# Configure port forwarding (from host)
lxc config device add girlfriend-alert http proxy listen=tcp:0.0.0.0:5000 connect=tcp:127.0.0.1:5000

# Check container IP
lxc list girlfriend-alert
```

## 🌐 Network Access Configuration

### For Local Network Access

```bash
# Get your container host's IP
ip addr show | grep inet

# The app will be accessible at:
# http://YOUR-HOST-IP:5000
```

### For Internet Access (Advanced)

#### Option 1: Reverse Proxy with Nginx
```bash
# On host system, install nginx
sudo apt install nginx

# Create nginx config
sudo tee /etc/nginx/sites-available/girlfriend-alert << EOF
server {
    listen 80;
    server_name your-domain.com;  # or your public IP
    
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/girlfriend-alert /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

#### Option 2: Cloudflare Tunnel (Free & Secure)
```bash
# Inside container
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared-linux-amd64.deb

# Login to Cloudflare (follow prompts)
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create girlfriend-alert

# Configure tunnel
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml << EOF
tunnel: YOUR-TUNNEL-ID
credentials-file: /home/appuser/.cloudflared/YOUR-TUNNEL-ID.json

ingress:
  - hostname: your-app.yourdomain.com
    service: http://localhost:5000
  - service: http_status:404
EOF

# Run tunnel
cloudflared tunnel run girlfriend-alert
```

## 📱 Mobile App Configuration

### Update Socket.io Connection for Production

Create a production configuration:

```bash
# Inside container, edit the React app
nano /home/appuser/app/girlfriend-alert/client/src/App.js
```

Replace the socket connection with:

```javascript
// Auto-detect the server URL
const getServerUrl = () => {
  if (process.env.NODE_ENV === 'production') {
    return window.location.origin;
  }
  return 'http://localhost:5000';
};

const newSocket = io(getServerUrl());
```

Rebuild the app:
```bash
cd /home/appuser/app/girlfriend-alert/client
npm run build
systemctl restart girlfriend-alert
```

## 🔧 Management Commands

### Container Management
```bash
# Start container
lxc start girlfriend-alert

# Stop container
lxc stop girlfriend-alert

# Restart container
lxc restart girlfriend-alert

# Enter container
lxc exec girlfriend-alert -- bash

# View container info
lxc info girlfriend-alert
```

### App Management
```bash
# Check app status
lxc exec girlfriend-alert -- systemctl status girlfriend-alert

# View app logs
lxc exec girlfriend-alert -- journalctl -u girlfriend-alert -f

# Restart app
lxc exec girlfriend-alert -- systemctl restart girlfriend-alert

# Update app (if using git)
lxc exec girlfriend-alert -- su - appuser -c "cd app/girlfriend-alert && git pull && npm install && cd client && npm run build"
```

## 🔐 Security Considerations

### Basic Security Setup
```bash
# Inside container
# Update packages regularly
apt update && apt upgrade -y

# Configure firewall
ufw enable
ufw allow 5000/tcp

# Disable root SSH (if SSH is enabled)
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
```

### SSL/HTTPS Setup with Let's Encrypt
```bash
# If using domain name, get SSL certificate
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## 📊 Monitoring & Maintenance

### Log Monitoring
```bash
# Create log monitoring script
cat > /home/appuser/monitor.sh << 'EOF'
#!/bin/bash
echo "=== Girlfriend Alert Status ==="
systemctl is-active girlfriend-alert
echo ""
echo "=== Latest Logs ==="
journalctl -u girlfriend-alert --no-pager -n 10
echo ""
echo "=== Resource Usage ==="
ps aux | grep node
echo ""
df -h /
EOF

chmod +x /home/appuser/monitor.sh
```

### Backup Script
```bash
# Create backup script
cat > /home/appuser/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/appuser/backups"
mkdir -p $BACKUP_DIR

# Backup app and config
tar -czf $BACKUP_DIR/girlfriend-alert-$DATE.tar.gz \
  /home/appuser/app/girlfriend-alert \
  /etc/systemd/system/girlfriend-alert.service

echo "Backup created: $BACKUP_DIR/girlfriend-alert-$DATE.tar.gz"
EOF

chmod +x /home/appuser/backup.sh
```

## 🚀 Quick Start Summary

1. **Create container**: `lxc launch ubuntu:22.04 girlfriend-alert`
2. **Install Node.js**: Use the setup commands above
3. **Copy your app**: Use `lxc file push` or git clone
4. **Setup service**: Create systemd service file
5. **Configure networking**: Add port forwarding
6. **Access app**: `http://YOUR-HOST-IP:5000`

## 📱 Final Steps for Your Girlfriend

1. **Give her the URL**: `http://YOUR-HOST-IP:5000`
2. **Add to home screen**: In Safari, share → "Add to Home Screen"
3. **Enable notifications**: Allow when prompted
4. **Enjoy instant alerts!** 💕

Your app is now containerized, portable, and production-ready! 🎉

## 🔧 Troubleshooting

### Common Issues
- **Can't access app**: Check firewall and port forwarding
- **Container won't start**: Check LXD status: `sudo systemctl status lxd`
- **App crashes**: Check logs: `journalctl -u girlfriend-alert -f`
- **No notifications**: Ensure HTTPS for production (required for push notifications)

### Useful Commands
```bash
# Check all containers
lxc list

# Container resource usage
lxc info girlfriend-alert

# Network configuration
lxc config show girlfriend-alert
```
