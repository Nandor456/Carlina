# syntax=docker/dockerfile:1.6

# ── Build stage ────────────────────────────────────────────────
FROM node:20-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig*.json nest-cli.json ./
COPY src ./src
RUN npm run build

# ── Runtime stage ──────────────────────────────────────────────
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

# sharp/bcrypt need these at runtime
RUN apk add --no-cache vips

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=build /app/dist ./dist

RUN mkdir -p /app/uploads && chown -R node:node /app
USER node

EXPOSE 3000
CMD ["node", "dist/main.js"]
