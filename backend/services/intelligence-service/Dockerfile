FROM node:20-alpine

WORKDIR /app

# Copy monorepo root package files
COPY package*.json ./
COPY services/intelligence-service/package*.json ./services/intelligence-service/

# Install all dependencies (monorepo context)
RUN npm ci

# Copy credentials config for local Docker compose use
COPY config ./config
COPY inspiring-rite-489103-t0-aa47c9862dcd.json* ./

# Copy the intelligence-service source code
COPY services/intelligence-service ./services/intelligence-service

# Expose port and run the service
EXPOSE 3003
CMD ["node", "services/intelligence-service/src/app.js"]
