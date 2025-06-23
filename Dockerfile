# ------------------------------
# Build stage
# ------------------------------
FROM node:20-alpine AS builder

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (needed for build)
RUN npm ci

# Copy rest of the application
COPY . .

# Build admin panel
RUN npm run build

# ------------------------------
# Production stage
# ------------------------------
FROM node:20-alpine

# Create app directory
WORKDIR /app

# Copy everything from build stage
COPY --from=builder /app /app

# Install only production dependencies
RUN npm ci --omit=dev && npm cache clean --force

# Expose the port Strapi runs on
EXPOSE 1337

# Set production environment
ENV NODE_ENV=production
ENV STRAPI_DISABLE_UPDATE_NOTIFICATION=true
ENV STRAPI_TELEMETRY_DISABLED=true

# Start the application
CMD ["npm", "start"]