#!/bin/bash
set -e

CONFIG_PATH=/data/options.json

MODE=$(jq --raw-output '.mode // empty' $CONFIG_PATH)

echo "--- VERSIONS ---"
echo "add-on version: 0.0.5"
echo -n "neolink version: " && neolink --version
echo "neolink mode: ${MODE}"
echo "ATTENTION: if you expected a newer Neolink version, please reinstall this Add-on!"
echo "--- Neolink ---"
if [ "${MODE}" == "dual" ]; then
    neolink rtsp --config /config/addons/neolink.toml & neolink mqtt --config /config/addons/neolink.toml & wait -n
else
    neolink ${MODE} --config /config/addons/neolink.toml &
    {
        while true; do
            neolink image --config /config/addons/neolink.toml --file-path /config/snaps/livingroom.jpg livingroom;
            sleep(10);
        done;
    } & {
        while true; do
            neolink image --config /config/addons/neolink.toml --file-path /config/snaps/masterbed.jpg masterbed;
            sleep(10);
        done;
    } & wait -n
fi

