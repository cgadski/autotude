FROM node:20-alpine AS builder

RUN npm install -g pnpm
WORKDIR /app
COPY package.json ./
RUN pnpm install

COPY ./ ./
RUN pnpm run build

FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/build ./build
COPY --from=builder /app/package.json ./
COPY --from=builder /app/sql ./sql

RUN npm install -g pnpm && pnpm install --prod

ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

CMD ["node", "build"]
