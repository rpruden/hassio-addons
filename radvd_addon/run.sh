#!/bin/sh

mkdir -p /run/radvd

echo "radvd version:"
radvd --version

PREFIX=$(jq -r '.prefix' /data/options.json)
INTERFACE=$(jq -r '.interface' /data/options.json)
LOG_LEVEL=$(jq -r '.log_level' /data/options.json)

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

cat <<EOF > /etc/radvd.conf
interface ${INTERFACE} {
  AdvSendAdvert on;
  MinRtrAdvInterval 5;
  MaxRtrAdvInterval 20;
  prefix ${PREFIX} {
    AdvOnLink on;
    AdvAutonomous on;
    AdvStableFlag on;
  };
};
EOF

exec radvd -n $RADVD_ARGS -C /etc/radvd.conf
