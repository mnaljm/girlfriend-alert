#!/bin/bash
# Container Management Script for Girlfriend Alert

CONTAINER_NAME="girlfriend-alert"

show_help() {
    echo "Girlfriend Alert LXC Container Manager"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start the container and app"
    echo "  stop        Stop the container"
    echo "  restart     Restart the container and app"
    echo "  status      Show container and app status"
    echo "  logs        Show application logs"
    echo "  shell       Enter container shell"
    echo "  update      Update the application"
    echo "  backup      Create backup of app and config"
    echo "  monitor     Show real-time status"
    echo "  ip          Show container IP addresses"
    echo "  help        Show this help message"
}

check_container() {
    if ! lxc info $CONTAINER_NAME &> /dev/null; then
        echo "❌ Container $CONTAINER_NAME not found"
        echo "Run deploy-lxc.sh first to create the container"
        exit 1
    fi
}

case "$1" in
    start)
        check_container
        echo "🚀 Starting container and app..."
        lxc start $CONTAINER_NAME
        sleep 3
        lxc exec $CONTAINER_NAME -- systemctl start girlfriend-alert
        echo "✅ Started successfully"
        ;;
    
    stop)
        check_container
        echo "🛑 Stopping container..."
        lxc exec $CONTAINER_NAME -- systemctl stop girlfriend-alert || true
        lxc stop $CONTAINER_NAME
        echo "✅ Stopped successfully"
        ;;
    
    restart)
        check_container
        echo "🔄 Restarting container and app..."
        lxc restart $CONTAINER_NAME
        sleep 5
        lxc exec $CONTAINER_NAME -- systemctl restart girlfriend-alert
        echo "✅ Restarted successfully"
        ;;
    
    status)
        check_container
        echo "📊 Container Status:"
        lxc list $CONTAINER_NAME
        echo ""
        echo "📱 App Status:"
        lxc exec $CONTAINER_NAME -- systemctl status girlfriend-alert --no-pager
        ;;
    
    logs)
        check_container
        echo "📋 Application Logs (Press Ctrl+C to exit):"
        lxc exec $CONTAINER_NAME -- journalctl -u girlfriend-alert -f
        ;;
    
    shell)
        check_container
        echo "🐚 Entering container shell..."
        lxc exec $CONTAINER_NAME -- bash
        ;;
    
    update)
        check_container
        echo "🔄 Updating application..."
        lxc exec $CONTAINER_NAME -- su - appuser -c "
            cd app
            git pull || echo 'No git repository found - manual update needed'
            npm install
            cd client && npm install && npm run build && cd ..
        "
        lxc exec $CONTAINER_NAME -- systemctl restart girlfriend-alert
        echo "✅ Update complete"
        ;;
    
    backup)
        check_container
        DATE=$(date +%Y%m%d_%H%M%S)
        BACKUP_NAME="girlfriend-alert-backup-$DATE.tar.gz"
        echo "💾 Creating backup..."
        lxc exec $CONTAINER_NAME -- bash -c "
            mkdir -p /home/appuser/backups
            tar -czf /home/appuser/backups/$BACKUP_NAME \
                /home/appuser/app \
                /etc/systemd/system/girlfriend-alert.service
        "
        # Copy backup to host
        lxc file pull $CONTAINER_NAME/home/appuser/backups/$BACKUP_NAME ./
        echo "✅ Backup created: $BACKUP_NAME"
        ;;
    
    monitor)
        check_container
        echo "📊 Real-time monitoring (Press Ctrl+C to exit):"
        while true; do
            clear
            echo "=== Girlfriend Alert Container Monitor ==="
            echo "Time: $(date)"
            echo ""
            echo "Container Status:"
            lxc list $CONTAINER_NAME | head -4
            echo ""
            echo "App Status:"
            lxc exec $CONTAINER_NAME -- systemctl is-active girlfriend-alert
            echo ""
            echo "Resource Usage:"
            lxc exec $CONTAINER_NAME -- ps aux | grep node | head -5
            echo ""
            echo "Latest Logs:"
            lxc exec $CONTAINER_NAME -- journalctl -u girlfriend-alert --no-pager -n 3
            sleep 5
        done
        ;;
    
    ip)
        check_container
        echo "🌐 Network Information:"
        echo "Container IPs:"
        lxc list $CONTAINER_NAME -c 4
        echo ""
        echo "Host IP:"
        hostname -I
        echo ""
        echo "Access URLs:"
        HOST_IP=$(hostname -I | awk '{print $1}')
        echo "  http://localhost:5000"
        echo "  http://$HOST_IP:5000"
        ;;
    
    help|--help|-h)
        show_help
        ;;
    
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
