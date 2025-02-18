FROM node:20-slim as builder

WORKDIR /app

# Copy package files
COPY altistats.com/package.json altistats.com/pnpm-lock.yaml ./

# Install dependencies
RUN npm install -g pnpm; pnpm install

# Copy source files
COPY altistats.com/ ./

# Build the application
RUN npm run build

CMD ["bash"]

# FROM node:20-slim

# WORKDIR /app

# # Copy built application
# COPY --from=builder /app/build ./build
# COPY --from=builder /app/package.json ./package.json
# COPY --from=builder /app/node_modules ./node_modules

# ENV NODE_ENV=production
# ENV ALTI_HOME=/alti_home

# CMD ["node", "./build"]
