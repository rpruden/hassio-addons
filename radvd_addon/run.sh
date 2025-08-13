#!/bin/sh

mkdir -p /run/radvd

echo "radvd version:"
radvd --version

PREFIX=$(jq -r '.prefix' /data/options.json)
INTERFACE=$(jq -r '.interface' /data/options.json)
LOG_LEVEL=$(jq -r '.log_level' /data/options.json)

# DHCPv6 configs from options.json
DHCP_RANGE_START=$(jq -r '.dhcpv6_range_start // empty' /data/options.json)
DHCP_RANGE_END=$(jq -r '.dhcpv6_range_end // empty' /data/options.json)
# reserved leases: JSON array of objects with mac & ip properties
LEASES=$(jq -c '.dhcpv6_leases // []' /data/options.json)

# Translate string log level to numeric debug level for radvd
case "$LOG_LEVEL" in
  none)
    RADVD_ARGS="-m none"
    ;;
  error)
    RADVD_ARGS="-d 0"
    ;;
  warning)
    RADVD_ARGS="-d 1"
    ;;
  info)
    RADVD_ARGS="-d 2"
    ;;
  debug)
    RADVD_ARGS="-d 3"
    ;;
  *)
    RADVD_ARGS="-d 1"
    ;;
esac

# Generate radvd.conf (SLAAC advertisements)
cat <<EOF > /etc/radvd.conf
interface ${INTERFACE} {
  AdvSendAdvert on;
  MinRtrAdvInterval 5;
  MaxRtrAdvInterval 20;
  prefix ${PREFIX} {
    AdvOnLink on;
    AdvAutonomous on;
  };
};
EOF

# Generate dhcpd6.conf (DHCPv6 server config)
# This will only create a pool if DHCP_RANGE_START and DHCP_RANGE_END are provided
cat <<EOF > /etc/dhcpd6.conf
default-lease-time 600;
max-lease-time 7200;
log-facility local7;

subnet6 ${PREFIX} {
EOF

if [ -n "$DHCP_RANGE_START" ] && [ -n "$DHCP_RANGE_END" ]; then
cat <<EOF >> /etc/dhcpd6.conf
  range6 ${DHCP_RANGE_START} ${DHCP_RANGE_END};
EOF
fi

# Add static leases if any
for lease in $(echo "$LEASES" | jq -c '.[]'); do
  MAC=$(echo "$lease" | jq -r '.mac')
  IP=$(echo "$lease" | jq -r '.ip')
  cat <<EOF >> /etc/dhcpd6.conf
  host reserved-${MAC//:/} {
    hardware ethernet $MAC;
    fixed-address6 $IP;
  };
EOF
done

cat <<EOF >> /etc/dhcpd6.conf
}
EOF

# Start radvd in foreground with log level
radvd -n $RADVD_ARGS -C /etc/radvd.conf &

# Start DHCPv6 server for your interface
dhcpd -6 -cf /etc/dhcpd6.conf $INTERFACE
