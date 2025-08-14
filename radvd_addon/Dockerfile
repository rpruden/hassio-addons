# Use Alpine-based Home Assistant add-on base image
FROM ghcr.io/hassio-addons/base-alpine:3.18.0

# Install dependencies (Alpine uses apk, not apt)
# NOTE: Using dhcp6-server instead of isc-dhcp-server, which isn’t in Alpine repos
RUN apk add --no-cache radvd dhcp6-server jq bash

# Copy the run script into the container
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Set the script as the container's startup command
CMD [ "/run.sh" ]
