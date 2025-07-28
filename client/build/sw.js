// Service Worker for push notifications
const CACHE_NAME = 'girlfriend-alert-v1';
const urlsToCache = [
  '/',
  '/static/js/bundle.js',
  '/static/css/main.css',
  '/manifest.json'
];

// Install event
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        return cache.addAll(urlsToCache);
      })
  );
});

// Fetch event
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // Return cached version or fetch from network
        return response || fetch(event.request);
      }
    )
  );
});

// Push event
self.addEventListener('push', (event) => {
  console.log('Push received:', event);
  
  let notificationData = {};
  
  if (event.data) {
    try {
      notificationData = event.data.json();
    } catch (e) {
      notificationData = {
        title: 'Girlfriend Alert! 💕',
        body: event.data.text() || 'You have a new alert!',
        icon: '/logo192.png',
        badge: '/favicon.ico'
      };
    }
  }

  const options = {
    body: notificationData.body || 'You have a new alert!',
    icon: notificationData.icon || '/logo192.png',
    badge: notificationData.badge || '/favicon.ico',
    vibrate: [200, 100, 200, 100, 200, 100, 400],
    data: {
      url: '/',
      urgency: notificationData.urgency || 'normal'
    },
    actions: [
      {
        action: 'open',
        title: 'Open App',
        icon: '/logo192.png'
      },
      {
        action: 'close',
        title: 'Dismiss'
      }
    ],
    requireInteraction: notificationData.urgency === 'urgent',
    silent: false,
    tag: 'girlfriend-alert'
  };

  event.waitUntil(
    self.registration.showNotification(
      notificationData.title || 'Girlfriend Alert! 💕',
      options
    )
  );
});

// Notification click event
self.addEventListener('notificationclick', (event) => {
  console.log('Notification click received:', event);
  
  event.notification.close();
  
  if (event.action === 'open' || !event.action) {
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});
