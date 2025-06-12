# ------------------------------
# Build stage
# ------------------------------
FROM node:20-alpine AS builder

# Create app directory
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --omit=dev

# Copy rest of the application
COPY . .

# Build admin panel
RUN npm run build

# ------------------------------
# Production stage
# ------------------------------
FROM node:20-alpine

# Add production deps only
WORKDIR /app

# Copy only necessary files from build stage
COPY --from=builder /app /app

# Expose the port Strapi runs on
EXPOSE 1337

# Define environment variables if needed
ENV NODE_ENV=production

# Start the application
CMD ["npm", "start"]
