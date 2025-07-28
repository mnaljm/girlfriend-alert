#!/bin/bash
# Quick Docker Deployment Script for Girlfriend Alert

set -e

echo "================================================"
echo "    Girlfriend Alert Docker Deployment"
echo "================================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first:"
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker found"

# Check if .env file exists and has VAPID keys
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating template..."
    cat > .env << 'EOF'
# Add your VAPID keys here
VAPID_PUBLIC_KEY=your-public-key-here
VAPID_PRIVATE_KEY=your-private-key-here
PORT=5000
NODE_ENV=production
EOF
fi

# Check if VAPID keys are set
if grep -q "your-public-key-here" .env || grep -q "your-private-key-here" .env; then
    echo "⚠️  VAPID keys not configured in .env file"
    
    # Try to generate VAPID keys if web-push is available
    if command -v npx &> /dev/null; then
        echo "🔑 Generating VAPID keys..."
        npx web-push generate-vapid-keys > vapid-keys.txt 2>/dev/null || true
        
        if [ -f vapid-keys.txt ]; then
            echo "✅ VAPID keys generated in vapid-keys.txt"
            echo "📝 Please copy the keys to your .env file:"
            cat vapid-keys.txt
            echo ""
            read -p "Press Enter when you've updated the .env file..."
        fi
    else
        echo "📝 Please generate VAPID keys and update .env file:"
        echo "1. Install Node.js if not already installed"
        echo "2. Run: npx web-push generate-vapid-keys"
        echo "3. Copy the keys to .env file"
        echo ""
        read -p "Press Enter when you've updated the .env file..."
    fi
fi

echo "🐳 Building Docker image..."
docker build -t girlfriend-alert .

echo "🚀 Starting container..."
# Use docker-compose if available, otherwise use docker run
if command -v docker-compose &> /dev/null; then
    docker-compose up -d
elif docker compose version &> /dev/null 2>&1; then
    docker compose up -d
else
    # Fallback to docker run
    docker stop girlfriend-alert 2>/dev/null || true
    docker rm girlfriend-alert 2>/dev/null || true
    
    docker run -d \
        --name girlfriend-alert \
        -p 5000:5000 \
        --env-file .env \
        --restart unless-stopped \
        girlfriend-alert
fi

# Wait for container to start
echo "⏳ Waiting for container to start..."
sleep 5

# Check if container is running
if docker ps | grep -q girlfriend-alert; then
    echo ""
    echo "================================================"
    echo "✅ Deployment successful!"
    echo "================================================"
    echo ""
    
    # Get local IP
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
    
    echo "🌐 Access URLs:"
    echo "   Local: http://localhost:5000"
    if [ ! -z "$LOCAL_IP" ]; then
        echo "   Network: http://$LOCAL_IP:5000"
    fi
    echo ""
    echo "📱 For mobile access:"
    echo "   Use the network URL on same WiFi"
    echo "   Add to home screen for best experience"
    echo ""
    echo "🔧 Management commands:"
    echo "   View logs: docker logs -f girlfriend-alert"
    echo "   Stop: docker stop girlfriend-alert"
    echo "   Start: docker start girlfriend-alert"
    echo "   Remove: docker rm -f girlfriend-alert"
    echo ""
    echo "💕 Your girlfriend alert app is ready!"
    
    # Optionally open browser
    if command -v xdg-open &> /dev/null; then
        read -p "Open in browser? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            xdg-open http://localhost:5000
        fi
    elif command -v open &> /dev/null; then
        read -p "Open in browser? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open http://localhost:5000
        fi
    fi
    
else
    echo "❌ Container failed to start. Checking logs..."
    docker logs girlfriend-alert
    exit 1
fi
