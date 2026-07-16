FROM node:20-alpine AS build
WORKDIR /workspace
COPY app/package.json app/package-lock.json* ./
RUN npm install --omit=dev --no-audit --no-fund
COPY app/ ./

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /workspace ./
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD wget --spider -q http://127.0.0.1:3000/healthz || exit 1
CMD ["node", "server.js"]
