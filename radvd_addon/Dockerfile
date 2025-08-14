#ARG BUILD_FROM=ghcr.io/hassio-addons/base-alpine:3.18.0
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:latest
FROM ${BUILD_FROM}

# Install dependencies
#RUN apk add --no-cache radvd isc-dhcp-server jq bash
RUN apt-get update && \
    apt-get install -y radvd isc-dhcp-server jq bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Entrypoint
CMD [ "/run.sh" ]
