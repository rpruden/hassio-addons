#FROM ghcr.io/hassio-addons/base-alpine:3.18.0
ARG BUILD_FROM=ghcr.io/hassio-addons/base-alpine:3.18.0
FROM ${BUILD_FROM}

# Install dependencies
RUN apk add --no-cache radvd dnsmasq jq bash

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
