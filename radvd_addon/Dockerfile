FROM ghcr.io/home-assistant/amd64-base-debian:latest

# Install dependencies
RUN apt-get update && \
    apt-get install -y radvd isc-dhcp-server jq bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Entrypoint
CMD [ "/run.sh" ]
