#!/bin/bash
# LXC Container Setup Script for Girlfriend Alert App

set -e

CONTAINER_NAME="girlfriend-alert"
APP_USER="appuser"

echo "================================================"
echo "    Girlfriend Alert LXC Container Setup"
echo "================================================"

# Check if LXD is installed
if ! command -v lxc &> /dev/null; then
    echo "❌ LXD is not installed. Please install it first:"
    echo "Ubuntu/Debian: sudo apt install lxd && sudo lxd init"
    exit 1
fi

echo "✅ LXD found"

# Create container
echo "🚀 Creating Ubuntu 22.04 container..."
if lxc info $CONTAINER_NAME &> /dev/null; then
    echo "⚠️  Container $CONTAINER_NAME already exists"
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        lxc stop $CONTAINER_NAME || true
        lxc delete $CONTAINER_NAME
    else
        echo "Exiting..."
        exit 1
    fi
fi

lxc launch ubuntu:22.04 $CONTAINER_NAME

echo "⏳ Waiting for container to be ready..."
lxc exec $CONTAINER_NAME -- cloud-init status --wait

echo "📦 Installing dependencies..."
lxc exec $CONTAINER_NAME -- bash -c "
    apt update && apt upgrade -y
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs git
    
    # Create app user
    useradd -m -s /bin/bash $APP_USER
    mkdir -p /home/$APP_USER/app
    chown $APP_USER:$APP_USER /home/$APP_USER/app
"

echo "📂 Copying application files..."
# Copy the entire project
lxc file push -r . $CONTAINER_NAME/home/$APP_USER/app/ --create-dirs
lxc exec $CONTAINER_NAME -- chown -R $APP_USER:$APP_USER /home/$APP_USER/app

echo "🔧 Setting up application..."
lxc exec $CONTAINER_NAME -- su - $APP_USER -c "
    cd app
    npm install
    cd client && npm install && npm run build && cd ..
    
    # Generate VAPID keys
    npx web-push generate-vapid-keys > vapid-keys.txt
    
    # Create .env file template
    cat > .env << 'EOF'
# Copy VAPID keys from vapid-keys.txt
VAPID_PUBLIC_KEY=your-public-key-here
VAPID_PRIVATE_KEY=your-private-key-here
PORT=5000
NODE_ENV=production
EOF
"

echo "🔧 Creating systemd service..."
lxc exec $CONTAINER_NAME -- bash -c "
cat > /etc/systemd/system/girlfriend-alert.service << 'EOF'
[Unit]
Description=Girlfriend Alert App
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=/home/$APP_USER/app
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable girlfriend-alert
"

echo "🌐 Configuring networking..."
lxc config device add $CONTAINER_NAME http proxy listen=tcp:0.0.0.0:5000 connect=tcp:127.0.0.1:5000

# Get container IP
CONTAINER_IP=$(lxc list $CONTAINER_NAME -c 4 --format csv | cut -d' ' -f1)
HOST_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "================================================"
echo "✅ Container setup complete!"
echo "================================================"
echo ""
echo "📝 Next steps:"
echo "1. Edit VAPID keys:"
echo "   lxc exec $CONTAINER_NAME -- su - $APP_USER -c 'nano app/.env'"
echo ""
echo "2. Copy VAPID keys from app/vapid-keys.txt to app/.env"
echo ""
echo "3. Start the service:"
echo "   lxc exec $CONTAINER_NAME -- systemctl start girlfriend-alert"
echo ""
echo "4. Check status:"
echo "   lxc exec $CONTAINER_NAME -- systemctl status girlfriend-alert"
echo ""
echo "🌐 Access URLs:"
echo "   Local: http://localhost:5000"
echo "   Network: http://$HOST_IP:5000"
if [ ! -z "$CONTAINER_IP" ]; then
    echo "   Container: http://$CONTAINER_IP:5000"
fi
echo ""
echo "📱 For mobile access, use: http://$HOST_IP:5000"
echo ""
