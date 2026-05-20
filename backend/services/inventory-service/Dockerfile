FROM node:20-alpine

WORKDIR /app

# Copy monorepo root package files
COPY package*.json ./
COPY services/inventory-service/package*.json ./services/inventory-service/

# Install all dependencies (monorepo context)
RUN npm ci

# Copy Prisma schema and generate client
COPY prisma ./prisma
RUN npx prisma generate

# Copy credentials config for local Docker compose use
COPY config ./config
COPY inspiring-rite-489103-t0-aa47c9862dcd.json* ./

# Copy the inventory-service source code
COPY services/inventory-service ./services/inventory-service

# Expose port and run the service
EXPOSE 3002
CMD ["node", "services/inventory-service/src/app.js"]
