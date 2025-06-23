# ------------------------------
# Build stage
# ------------------------------
FROM node:20-alpine AS builder

# Create app directory
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy rest of the application
COPY . .

# Build admin panel
RUN npm run build

# ------------------------------
# Development stage
# ------------------------------
FROM node:20-alpine

WORKDIR /app

# Copy everything from build stage
COPY --from=builder /app /app

# Expose the port Strapi runs on
EXPOSE 1337

# Set environment for development
ENV NODE_ENV=development

# Start Strapi in development mode
CMD ["npm", "run", "develop"]
