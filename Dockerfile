# Use Node.js 18 LTS
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S appuser -u 1001 -G nodejs

# Copy package files
COPY package*.json ./
COPY client/package*.json ./client/

# Install dependencies
RUN npm ci --only=production && \
    cd client && npm ci --only=production && cd ..

# Copy application code
COPY . .

# Build React app
RUN cd client && npm run build && cd ..

# Create .env file template
RUN echo "VAPID_PUBLIC_KEY=replace-with-your-public-key" > .env && \
    echo "VAPID_PRIVATE_KEY=replace-with-your-private-key" >> .env && \
    echo "PORT=5000" >> .env && \
    echo "NODE_ENV=production" >> .env

# Change ownership to non-root user
RUN chown -R appuser:nodejs /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/api/health || exit 1

# Start the application
CMD ["node", "server.js"]
