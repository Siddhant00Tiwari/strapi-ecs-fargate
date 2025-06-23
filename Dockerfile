# ------------------------------
# Build stage
# ------------------------------
FROM node:20-alpine AS builder

# Create app directory
WORKDIR /app

# Copy package files first for better Docker layer caching
COPY package*.json ./
COPY tsconfig.json* ./

# Install ALL dependencies (including devDependencies needed for build)
RUN npm ci

# Copy source code
COPY . .

# Set production environment for optimal build
ENV NODE_ENV=production

# Build the application and admin panel
RUN npm run build

# ------------------------------
# Production stage
# ------------------------------
FROM node:20-alpine AS production

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create app directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S strapi -u 1001 -G nodejs

# Copy package files
COPY package*.json ./

# Install ONLY production dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy built application from builder stage
COPY --from=builder --chown=strapi:nodejs /app/dist ./dist
COPY --from=builder --chown=strapi:nodejs /app/build ./build
COPY --from=builder --chown=strapi:nodejs /app/public ./public
COPY --from=builder --chown=strapi:nodejs /app/config ./config
COPY --from=builder --chown=strapi:nodejs /app/database ./database
COPY --from=builder --chown=strapi:nodejs /app/src ./src
COPY --from=builder --chown=strapi:nodejs /app/node_modules ./node_modules

# Change ownership of the entire app directory
RUN chown -R strapi:nodejs /app

# Switch to non-root user
USER strapi

# Expose the port Strapi runs on
EXPOSE 1337

# Set production environment variables
ENV NODE_ENV=production
ENV STRAPI_DISABLE_UPDATE_NOTIFICATION=true
ENV STRAPI_TELEMETRY_DISABLED=true

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:1337/_health || \
      wget --no-verbose --tries=1 --spider http://localhost:1337/ || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start Strapi in production mode
CMD ["npm", "start"]