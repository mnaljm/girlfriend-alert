const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const webpush = require('web-push');
const path = require('path');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('client/build'));

// Web Push setup (you'll need to generate VAPID keys)
const vapidKeys = {
  publicKey: process.env.VAPID_PUBLIC_KEY || 'BMHj4QV0JLGENPrQN4JeLUtxA9V_A8wBCv_TqRgC3HjHRSW3qjgxpB1K-9V-h7JFgU8Y3jfMOX1x_7WfY7h9H4A',
  privateKey: process.env.VAPID_PRIVATE_KEY || 'your-private-key-here'
};

webpush.setVapidDetails(
  'mailto:your-email@example.com',
  vapidKeys.publicKey,
  vapidKeys.privateKey
);

// Store connected users and their subscriptions
const connectedUsers = new Map();
const pushSubscriptions = new Map();

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // Handle user identification
  socket.on('identify', (userData) => {
    connectedUsers.set(socket.id, userData);
    console.log(`User identified: ${userData.name} (${userData.role})`);
    
    // Notify all users about connected users
    io.emit('users-update', {
      users: Array.from(connectedUsers.values()),
      totalConnected: connectedUsers.size
    });
  });

  // Handle alert sending
  socket.on('send-alert', (alertData) => {
    const sender = connectedUsers.get(socket.id);
    console.log(`Alert from ${sender?.name}: ${alertData.message}`);
    
    // Broadcast alert to all other connected users
    socket.broadcast.emit('alert-received', {
      from: sender,
      message: alertData.message,
      urgency: alertData.urgency,
      timestamp: new Date().toISOString()
    });

    // Send push notifications to subscribed users
    sendPushNotifications(alertData, sender);
  });

  // Handle push notification subscription
  socket.on('subscribe-push', (subscription) => {
    const user = connectedUsers.get(socket.id);
    if (user) {
      pushSubscriptions.set(socket.id, subscription);
      console.log(`Push subscription saved for ${user.name}`);
    }
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    const user = connectedUsers.get(socket.id);
    console.log(`User disconnected: ${user?.name || socket.id}`);
    
    connectedUsers.delete(socket.id);
    pushSubscriptions.delete(socket.id);
    
    // Notify remaining users
    io.emit('users-update', {
      users: Array.from(connectedUsers.values()),
      totalConnected: connectedUsers.size
    });
  });
});

// Function to send push notifications
async function sendPushNotifications(alertData, sender) {
  const payload = JSON.stringify({
    title: `Alert from ${sender?.name || 'Someone'}! 💕`,
    body: alertData.message,
    icon: '/icon-192x192.png',
    badge: '/badge-72x72.png',
    urgency: alertData.urgency,
    timestamp: Date.now()
  });

  const promises = Array.from(pushSubscriptions.values()).map(async (subscription) => {
    try {
      await webpush.sendNotification(subscription, payload);
      console.log('Push notification sent successfully');
    } catch (error) {
      console.error('Error sending push notification:', error);
    }
  });

  await Promise.all(promises);
}

// API Routes
app.get('/api/vapid-public-key', (req, res) => {
  res.json({ publicKey: vapidKeys.publicKey });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    connectedUsers: connectedUsers.size,
    timestamp: new Date().toISOString()
  });
});

// Serve React app
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'client/build', 'index.html'));
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 Real-time alerts ready!`);
});
