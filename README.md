# 💕 Girlfriend Alert App

A real-time web application that allows instant alerts between two people, perfect for couples who want to stay connected throughout the day!

## ✨ Features

- **Real-time alerts** - Instant notifications using Socket.io
- **Push notifications** - Get alerts even when the browser is closed
- **Mobile-friendly** - Works perfectly on iPhone and all devices
- **Urgency levels** - From casual "hi" to emergency alerts
- **Beautiful UI** - Modern, responsive design with emoji reactions
- **Cross-platform** - Works on PC, phone, and tablet

## 🚀 Quick Start

### Prerequisites

Before running this app, make sure you have:
- **Node.js** installed (version 14 or higher)
- **npm** (comes with Node.js)

If you don't have Node.js installed:
1. Go to [nodejs.org](https://nodejs.org)
2. Download the LTS version for Windows
3. Run the installer and follow the instructions

### Installation

1. **Install all dependencies:**
   ```powershell
   npm run install-all
   ```

2. **Generate VAPID keys for push notifications:**
   ```powershell
   npx web-push generate-vapid-keys
   ```

3. **Update the .env file** with your VAPID keys:
   ```
   VAPID_PUBLIC_KEY=your-public-key-here
   VAPID_PRIVATE_KEY=your-private-key-here
   PORT=5000
   ```

4. **Start the application:**
   ```powershell
   npm run dev
   ```

The app will be available at:
- **Frontend:** http://localhost:3000
- **Backend:** http://localhost:5000

## 📱 How to Use

### First Time Setup

1. **Open the app** on both devices (your PC and your girlfriend's iPhone)
2. **Each person logs in** with their name and role (Girlfriend/Boyfriend)
3. **Allow notifications** when prompted by the browser
4. **Add to home screen** on iPhone for the best experience:
   - Open in Safari
   - Tap the Share button
   - Select "Add to Home Screen"

### Sending Alerts

1. Choose your urgency level:
   - 😊 **Low** - Just saying hi
   - 💕 **Normal** - Need attention
   - ⚡ **High** - Important
   - 🚨 **Urgent** - Emergency!

2. Type your message
3. Hit "Send Alert"

Your partner will receive:
- Real-time notification in the app
- Browser push notification
- Sound alert
- Visual urgency indicator

## 🔧 Technical Details

### Architecture
- **Frontend:** React.js with modern CSS
- **Backend:** Node.js + Express
- **Real-time:** Socket.io
- **Notifications:** Web Push API + Service Workers

### Browser Support
- Chrome/Edge (recommended)
- Firefox
- Safari (iPhone/Mac)

### Security
- HTTPS required for push notifications in production
- VAPID keys for secure push messaging
- No personal data stored on servers

## 🌐 Deployment

### For Local Network Access

To allow your girlfriend to access the app from her phone on the same WiFi:

1. Find your computer's IP address:
   ```powershell
   ipconfig
   ```

2. Look for "IPv4 Address" under your WiFi adapter

3. Update the Socket.io connection in `client/src/App.js`:
   ```javascript
   const newSocket = io('http://YOUR-IP-ADDRESS:5000');
   ```

4. Have your girlfriend visit: `http://YOUR-IP-ADDRESS:3000`

### For Internet Access

For access over the internet, you'll need to deploy to a cloud service:

- **Heroku** (free tier available)
- **Vercel** (free for personal use)
- **Netlify + Railway** (free tiers)
- **DigitalOcean** (paid)

## 🎨 Customization

### Changing Colors/Theme
Edit `client/src/App.css` to customize:
- Background gradients
- Button colors
- Urgency level colors

### Adding New Urgency Levels
1. Update the select options in `App.js`
2. Add corresponding styles in `App.css`
3. Update the emoji functions

### Custom Notification Sounds
Replace the audio generation in the `playNotificationSound()` function

## 🐛 Troubleshooting

### "npx is not recognized"
- Node.js isn't installed or not in PATH
- Restart your terminal after installing Node.js

### Push notifications not working
- Make sure you're using HTTPS (required for service workers)
- Check that notifications are allowed in browser settings
- Verify VAPID keys are correctly set

### Can't access from phone
- Make sure both devices are on the same WiFi
- Check Windows Firewall settings
- Try accessing via computer's IP address

### Connection issues
- Check that port 5000 and 3000 aren't blocked
- Restart the development server
- Clear browser cache

## 💡 Tips for Best Experience

1. **Add to home screen** on mobile devices
2. **Keep the app open** in a browser tab for instant notifications
3. **Test different urgency levels** to find what works for you
4. **Use WiFi** for best performance on mobile

## 🤝 Contributing

Want to add features? Feel free to:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - feel free to use and modify!

---

Built with ❤️ for keeping couples connected!
