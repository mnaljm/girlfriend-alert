# 🐳 Docker Deployment Guide
## Girlfriend Alert App

This guide provides an alternative to LXC using Docker containers, which might be easier to set up on various systems.

## 📋 Prerequisites

- **Docker** installed on your system
- **Docker Compose** (usually included with Docker Desktop)
- **Basic terminal knowledge**

### Quick Docker Installation

#### Windows
1. Download Docker Desktop from [docker.com](https://docker.com)
2. Install and restart your computer
3. Enable WSL2 if prompted

#### Linux (Ubuntu/Debian)
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo apt install docker-compose-plugin
```

#### macOS
```bash
# Using Homebrew
brew install --cask docker
```

## 🚀 Quick Deployment

### Method 1: Docker Compose (Recommended)

1. **Generate VAPID Keys**
```bash
# Install web-push globally
npm install -g web-push

# Generate keys
web-push generate-vapid-keys
```

2. **Update Environment Variables**
```bash
# Edit .env file with your VAPID keys
nano .env
```

3. **Build and Start**
```bash
# Build and start the container
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

4. **Access the App**
- Local: http://localhost:5000
- Network: http://YOUR-IP:5000

### Method 2: Docker Run

```bash
# Build the image
docker build -t girlfriend-alert .

# Run container
docker run -d \
  --name girlfriend-alert \
  -p 5000:5000 \
  -e VAPID_PUBLIC_KEY="your-public-key" \
  -e VAPID_PRIVATE_KEY="your-private-key" \
  --restart unless-stopped \
  girlfriend-alert

# Check logs
docker logs -f girlfriend-alert
```

## 🌐 Production Deployment Options

### Option 1: Simple Cloud Deployment

#### DigitalOcean App Platform
```yaml
# .do/app.yaml
name: girlfriend-alert
services:
- name: web
  source_dir: /
  github:
    repo: your-username/girlfriend-alert
    branch: main
  run_command: node server.js
  environment_slug: node-js
  instance_count: 1
  instance_size_slug: basic-xxs
  envs:
  - key: VAPID_PUBLIC_KEY
    value: your-public-key
  - key: VAPID_PRIVATE_KEY
    value: your-private-key
  http_port: 5000
```

#### Railway
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
railway init
railway up
```

#### Render
1. Connect your GitHub repository
2. Add environment variables
3. Deploy automatically

### Option 2: VPS with Docker

```bash
# On your VPS (Ubuntu)
# 1. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 2. Clone your repository
git clone https://github.com/your-username/girlfriend-alert.git
cd girlfriend-alert

# 3. Set environment variables
echo "VAPID_PUBLIC_KEY=your-key" > .env
echo "VAPID_PRIVATE_KEY=your-key" >> .env

# 4. Deploy with Docker Compose
docker-compose up -d

# 5. Setup nginx reverse proxy (optional)
sudo apt install nginx
```

### Option 3: Home Server / NAS

#### Synology NAS
1. Install Docker package from Package Center
2. Upload docker-compose.yml via File Station
3. Create container through Docker UI

#### QNAP
1. Install Container Station
2. Import docker-compose.yml
3. Configure port mapping

#### Unraid
1. Install Docker template
2. Configure environment variables
3. Start container

## 🔧 Container Management

### Basic Commands
```bash
# View running containers
docker ps

# View all containers
docker ps -a

# Start/stop
docker-compose start
docker-compose stop

# Restart
docker-compose restart

# Update application
docker-compose pull
docker-compose up -d

# View logs
docker-compose logs -f girlfriend-alert

# Enter container shell
docker-compose exec girlfriend-alert sh
```

### Updating the App
```bash
# Method 1: Rebuild container
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Method 2: If using git in container
docker-compose exec girlfriend-alert sh -c "
  cd /app && 
  git pull && 
  npm install && 
  cd client && 
  npm run build
"
docker-compose restart
```

## 🔐 Security & SSL

### HTTPS with Let's Encrypt
```yaml
# Add to docker-compose.yml
version: '3.8'
services:
  girlfriend-alert:
    # ... existing config

  certbot:
    image: certbot/certbot
    volumes:
      - ./ssl:/etc/letsencrypt
    command: certonly --webroot --webroot-path=/var/www/certbot --email your-email@example.com --agree-tos --no-eff-email -d your-domain.com

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx-ssl.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/letsencrypt:ro
    depends_on:
      - girlfriend-alert
```

### Nginx Configuration with SSL
```nginx
# nginx-ssl.conf
events {
    worker_connections 1024;
}

http {
    upstream app {
        server girlfriend-alert:5000;
    }

    server {
        listen 80;
        server_name your-domain.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl;
        server_name your-domain.com;

        ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

        location / {
            proxy_pass http://app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
```

## 📊 Monitoring & Maintenance

### Health Monitoring
```bash
# Check container health
docker-compose ps

# View resource usage
docker stats girlfriend-alert

# Monitor logs in real-time
docker-compose logs -f --tail=50
```

### Backup Script
```bash
#!/bin/bash
# backup-docker.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"
mkdir -p $BACKUP_DIR

# Stop container
docker-compose stop

# Create backup
tar -czf $BACKUP_DIR/girlfriend-alert-$DATE.tar.gz \
  .env \
  docker-compose.yml \
  nginx.conf \
  $(docker inspect girlfriend-alert --format='{{.Mounts}}' | grep -o '/var/lib/docker/volumes/[^"]*')

# Start container
docker-compose start

echo "Backup created: $BACKUP_DIR/girlfriend-alert-$DATE.tar.gz"
```

### Auto-restart Script
```bash
#!/bin/bash
# monitor-docker.sh

while true; do
    if ! docker-compose ps | grep -q "girlfriend-alert.*Up"; then
        echo "$(date): Container is down, restarting..."
        docker-compose up -d
    fi
    sleep 30
done
```

## 🌍 Domain & DNS Setup

### Free Domain Options
- **Cloudflare Tunnel**: Free subdomain with built-in SSL
- **ngrok**: Quick tunneling for testing
- **DuckDNS**: Free dynamic DNS

### Cloudflare Tunnel Setup
```bash
# Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Login and create tunnel
cloudflared tunnel login
cloudflared tunnel create girlfriend-alert

# Configure tunnel
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml << EOF
tunnel: your-tunnel-id
credentials-file: ~/.cloudflared/your-tunnel-id.json

ingress:
  - hostname: your-app.your-domain.com
    service: http://localhost:5000
  - service: http_status:404
EOF

# Run tunnel
cloudflared tunnel run girlfriend-alert
```

## 📱 Mobile App Considerations

### Service Worker Updates
For production deployment, update the service worker registration:

```javascript
// In client/src/App.js, update the service worker registration
if ('serviceWorker' in navigator && 'PushManager' in window) {
  navigator.serviceWorker.register('/sw.js', {
    updateViaCache: 'none'
  }).then(registration => {
    console.log('Service Worker registered:', registration);
  });
}
```

### PWA Manifest Updates
```json
{
  "short_name": "GF Alert",
  "name": "Girlfriend Alert",
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#ff6b9d",
  "background_color": "#667eea",
  "scope": "/",
  "orientation": "portrait"
}
```

## 🚀 Quick Start Summary

1. **Install Docker**: Follow installation guide above
2. **Generate VAPID keys**: `web-push generate-vapid-keys`
3. **Update .env**: Add your VAPID keys
4. **Deploy**: `docker-compose up -d`
5. **Access**: http://YOUR-IP:5000
6. **Mobile**: Add to home screen for best experience

Your containerized girlfriend alert app is ready! 🎉💕
