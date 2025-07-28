import React, { useState, useEffect, useRef } from 'react';
import io from 'socket.io-client';
import './App.css';

function App() {
  const [socket, setSocket] = useState(null);
  const [connected, setConnected] = useState(false);
  const [user, setUser] = useState({ name: '', role: '' });
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [message, setMessage] = useState('');
  const [urgency, setUrgency] = useState('normal');
  const [alerts, setAlerts] = useState([]);
  const [connectedUsers, setConnectedUsers] = useState([]);
  const [notificationPermission, setNotificationPermission] = useState('default');
  const alertsEndRef = useRef(null);

  useEffect(() => {
    // Request notification permission on load
    if ('Notification' in window) {
      setNotificationPermission(Notification.permission);
      if (Notification.permission === 'default') {
        Notification.requestPermission().then(permission => {
          setNotificationPermission(permission);
        });
      }
    }

    // Register service worker for push notifications
    if ('serviceWorker' in navigator && 'PushManager' in window) {
      navigator.serviceWorker.register('/sw.js')
        .then(registration => {
          console.log('Service Worker registered:', registration);
        })
        .catch(error => {
          console.log('Service Worker registration failed:', error);
        });
    }
  }, []);

  useEffect(() => {
    if (alerts.length > 0) {
      alertsEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }
  }, [alerts]);

  const connectSocket = () => {
    const newSocket = io('http://localhost:5000');
    
    newSocket.on('connect', () => {
      setConnected(true);
      setSocket(newSocket);
      
      // Identify user
      newSocket.emit('identify', user);
      
      // Subscribe to push notifications
      subscribeToPushNotifications(newSocket);
    });

    newSocket.on('disconnect', () => {
      setConnected(false);
    });

    newSocket.on('alert-received', (alertData) => {
      setAlerts(prev => [...prev, alertData]);
      
      // Show browser notification
      if (notificationPermission === 'granted') {
        new Notification(`Alert from ${alertData.from?.name || 'Someone'}! 💕`, {
          body: alertData.message,
          icon: '/logo192.png',
          tag: 'girlfriend-alert'
        });
      }
      
      // Play notification sound
      playNotificationSound();
    });

    newSocket.on('users-update', (data) => {
      setConnectedUsers(data.users);
    });

    return newSocket;
  };

  const subscribeToPushNotifications = async (socketInstance) => {
    if ('serviceWorker' in navigator && 'PushManager' in window) {
      try {
        const registration = await navigator.serviceWorker.ready;
        const response = await fetch('/api/vapid-public-key');
        const { publicKey } = await response.json();
        
        const subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: urlBase64ToUint8Array(publicKey)
        });
        
        socketInstance.emit('subscribe-push', subscription);
      } catch (error) {
        console.error('Failed to subscribe to push notifications:', error);
      }
    }
  };

  const urlBase64ToUint8Array = (base64String) => {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding)
      .replace(/-/g, '+')
      .replace(/_/g, '/');
    
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  };

  const playNotificationSound = () => {
    // Create a simple notification sound
    const audioContext = new (window.AudioContext || window.webkitAudioContext)();
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
    oscillator.frequency.setValueAtTime(1000, audioContext.currentTime + 0.1);
    
    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);
    
    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + 0.5);
  };

  const handleLogin = (e) => {
    e.preventDefault();
    if (user.name.trim() && user.role.trim()) {
      setIsLoggedIn(true);
      connectSocket();
    }
  };

  const sendAlert = (e) => {
    e.preventDefault();
    if (socket && message.trim()) {
      socket.emit('send-alert', {
        message: message.trim(),
        urgency
      });
      
      // Add to local alerts as sent
      setAlerts(prev => [...prev, {
        from: { ...user, isSelf: true },
        message: message.trim(),
        urgency,
        timestamp: new Date().toISOString()
      }]);
      
      setMessage('');
    }
  };

  const getUrgencyColor = (urgencyLevel) => {
    switch (urgencyLevel) {
      case 'low': return '#4CAF50';
      case 'normal': return '#2196F3';
      case 'high': return '#FF9800';
      case 'urgent': return '#F44336';
      default: return '#2196F3';
    }
  };

  const getUrgencyEmoji = (urgencyLevel) => {
    switch (urgencyLevel) {
      case 'low': return '😊';
      case 'normal': return '💕';
      case 'high': return '⚡';
      case 'urgent': return '🚨';
      default: return '💕';
    }
  };

  if (!isLoggedIn) {
    return (
      <div className="login-container">
        <div className="login-card">
          <h1>💕 Girlfriend Alert</h1>
          <p>Stay connected with instant alerts</p>
          
          <form onSubmit={handleLogin}>
            <input
              type="text"
              placeholder="Your name"
              value={user.name}
              onChange={(e) => setUser({...user, name: e.target.value})}
              required
            />
            
            <select
              value={user.role}
              onChange={(e) => setUser({...user, role: e.target.value})}
              required
            >
              <option value="">Select your role</option>
              <option value="girlfriend">Girlfriend 👩‍❤️‍👨</option>
              <option value="boyfriend">Boyfriend 👨‍❤️‍👩</option>
            </select>
            
            <button type="submit">Connect 💕</button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1>💕 Girlfriend Alert</h1>
        <div className="connection-status">
          <span className={`status-indicator ${connected ? 'connected' : 'disconnected'}`}></span>
          {connected ? 'Connected' : 'Disconnected'}
        </div>
      </header>

      <div className="main-content">
        <div className="user-info">
          <h2>Welcome, {user.name}! 👋</h2>
          <p>Connected users: {connectedUsers.length}</p>
        </div>

        <div className="alert-section">
          <form onSubmit={sendAlert} className="alert-form">
            <div className="urgency-selector">
              <label>Urgency level:</label>
              <select value={urgency} onChange={(e) => setUrgency(e.target.value)}>
                <option value="low">😊 Low - Just saying hi</option>
                <option value="normal">💕 Normal - Need attention</option>
                <option value="high">⚡ High - Important</option>
                <option value="urgent">🚨 Urgent - Emergency!</option>
              </select>
            </div>
            
            <div className="message-input">
              <textarea
                placeholder="What do you need? 💭"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                rows="3"
                required
              />
            </div>
            
            <button 
              type="submit" 
              className={`send-button urgency-${urgency}`}
              disabled={!connected}
            >
              {getUrgencyEmoji(urgency)} Send Alert
            </button>
          </form>
        </div>

        <div className="alerts-history">
          <h3>Alert History</h3>
          <div className="alerts-list">
            {alerts.length === 0 ? (
              <p className="no-alerts">No alerts yet. Send your first one! 💕</p>
            ) : (
              alerts.map((alert, index) => (
                <div 
                  key={index} 
                  className={`alert-item ${alert.from?.isSelf ? 'sent' : 'received'}`}
                  style={{ borderLeftColor: getUrgencyColor(alert.urgency) }}
                >
                  <div className="alert-header">
                    <span className="sender">
                      {alert.from?.isSelf ? 'You' : alert.from?.name || 'Someone'}
                    </span>
                    <span className="urgency">
                      {getUrgencyEmoji(alert.urgency)}
                    </span>
                    <span className="timestamp">
                      {new Date(alert.timestamp).toLocaleTimeString()}
                    </span>
                  </div>
                  <p className="alert-message">{alert.message}</p>
                </div>
              ))
            )}
            <div ref={alertsEndRef} />
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
