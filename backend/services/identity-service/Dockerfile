FROM node:20-alpine

WORKDIR /app

# Copy monorepo root package files
COPY package*.json ./
COPY services/identity-service/package*.json ./services/identity-service/

# Install all dependencies (monorepo context)
RUN npm ci

# Copy Prisma schema and generate client
COPY prisma ./prisma
RUN npx prisma generate

# Copy credentials config for local Docker compose use
COPY config ./config
COPY inspiring-rite-489103-t0-aa47c9862dcd.json* ./

# Copy docs for auto-deployed Swagger UI
COPY docs ./docs

# Copy the identity-service source code
COPY services/identity-service ./services/identity-service

# Expose port and run the service
EXPOSE 3001
CMD ["node", "services/identity-service/src/app.js"]
