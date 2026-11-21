FROM node:22-alpine AS builder
ARG NINE_ROUTER_REPO=https://github.com/giienew/9router-pro.git
ARG NINE_ROUTER_REF=master
RUN apk add --no-cache git python3 make g++ linux-headers
WORKDIR /src
RUN git clone --depth 1 --branch ${NINE_ROUTER_REF} ${NINE_ROUTER_REPO} .
RUN npm install
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build
RUN mkdir -p /opt/lazy-runtime && cd /opt/lazy-runtime \
 && npm init -y >/dev/null \
 && npm install --no-save wreq-js playwright-core

FROM node:22-alpine
RUN apk add --no-cache bash curl ffmpeg tini \
 && adduser -D -h /home/container container
WORKDIR /app
COPY --from=builder /src/public ./public
COPY --from=builder /src/.next/static ./.next/static
COPY --from=builder /src/.next/standalone ./
COPY --from=builder /src/custom-server.js ./custom-server.js
COPY --from=builder /src/open-sse ./open-sse
COPY --from=builder /src/src/mitm ./src/mitm
COPY --from=builder /src/node_modules/node-forge ./node_modules/node-forge
COPY --from=builder /src/node_modules/next ./node_modules/next
COPY --from=builder /src/node_modules/sql.js ./node_modules/sql.js
COPY --from=builder /src/node_modules/node-machine-id ./node_modules/node-machine-id
COPY --from=builder /opt/lazy-runtime/node_modules/. ./node_modules/
COPY entrypoint.sh /entrypoint.sh
COPY start-9router.sh /usr/local/bin/start-9router
RUN chmod +x /entrypoint.sh /usr/local/bin/start-9router \
 && chmod -R a+rwX /app
USER container
ENV USER=container HOME=/home/container NODE_ENV=production NEXT_TELEMETRY_DISABLED=1
WORKDIR /home/container
ENTRYPOINT ["/sbin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
