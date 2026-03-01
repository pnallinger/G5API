# Build from project root (context: .) so we can access docker/ folder
# Run: docker compose build OR docker build -f G5API/Dockerfile .
FROM node:20-alpine

WORKDIR /app

# Install gettext for envsubst
RUN apk add --no-cache gettext

# Dependencies first (layer caching)
COPY G5API/package*.json ./
RUN npm ci

# App code
COPY G5API/ .

# Build TypeScript
RUN npm run build

# Production deps only for runtime
RUN npm prune --production

# Config template and entrypoint from docker/
COPY docker/g5api-production.json.template ./config/production.json.template
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3301

# Health check - G5API has /isloggedin at root
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:3301/isloggedin || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "dist/bin/www.js"]
