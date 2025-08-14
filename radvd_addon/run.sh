#!/bin/sh

mkdir -p /run/radvd

echo "radvd version:"
radvd --version

PREFIX=$(jq -r '.prefix' /data/options.json)
INTERFACE=$(jq -r '.interface' /data/options.json)
LOG_LEVEL=$(jq -r '.log_level' /data/options.json)
ENABLE_DHCP=$(jq -r '.enable_dhcp // false' /data/options.json)
ENABLE_SLAAC=$(jq -r '.enable_slaac // true' /data/options.json)
DHCP_RANGE_START=$(jq -r '.dhcp_range_start // empty' /data/options.json)
DHCP_RANGE_END=$(jq -r '.dhcp_range_end // empty' /data/options.json)
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

# Generate radvd.conf with SLAAC toggled
ENABLE_SLAAC_RAW=$(jq -r '.enable_slaac // true' /data/options.json)
if [ "$ENABLE_SLAAC_RAW" = "true" ]; then
  SLAAC_FLAG="on"
else
  SLAAC_FLAG="off"
fi

if [ "$ENABLE_DHCP" = "true" ]; then
  MANAGED_FLAG="on"
else
  MANAGED_FLAG="off"
fi

cat <<EOF > /etc/radvd.conf
interface ${INTERFACE} {
  AdvSendAdvert on;
  MinRtrAdvInterval 5;
  MaxRtrAdvInterval 20;
  AdvManagedFlag ${MANAGED_FLAG};
  AdvOtherConfigFlag on;
  prefix ${PREFIX} {
    AdvOnLink on;
    AdvAutonomous ${SLAAC_FLAG};
  };
};
EOF

echo "===== /etc/radvd.conf ====="  
cat /etc/radvd.conf  

# Start radvd in foreground with log level
radvd -n $RADVD_ARGS -C /etc/radvd.conf &
RADVD_PID=$!

# DHCPd part, starts only if enabled
if [ "$ENABLE_DHCP" = "true" ]; then
  # Generate dnsmasq.conf
  cat <<EOF > /etc/dnsmasq.conf
interface=${INTERFACE}
enable-ra
#ra-param=${INTERFACE},64,12h,ra-names
dhcp-range=${DHCP_RANGE_START},${DHCP_RANGE_END},64,12h
EOF

  # Add DHCPv6 reservations if any
  for lease in $(echo "$LEASES" | jq -c '.[]'); do
    MAC=$(echo "$lease" | jq -r '.mac')
    IP=$(echo "$lease" | jq -r '.ip')
    echo "dhcp-host=$MAC,[${IP}]" >> /etc/dnsmasq.conf
  done

echo "===== /etc/dnsmasq.conf ====="  
cat /etc/dnsmasq.conf  

  dnsmasq --no-resolv --no-hosts --port=0 --conf-file=/etc/dnsmasq.conf --no-daemon &
  DNSMASQ_PID=$!
fi

# Wait for radvd process so container stays alive
wait $RADVD_PID
wait $DNSMASQ_PID
