#!/bin/bash

# Define environment variables
SERVER_PORT=${SERVER_PORT:-30120}
SERVER_HOSTNAME=${SERVER_HOSTNAME:-"Default Server"}
FIVEM_LICENSE=${FIVEM_LICENSE:-"your-license-key"}
STEAM_WEBAPIKEY=${STEAM_WEBAPIKEY:-"your-steam-api-key"}
MAX_PLAYERS=${MAX_PLAYERS:-32}
TXADMIN_PORT=${TXADMIN_PORT:-40120}

# Path to the parent directory where new framework directories are created
PARENT_DIR="/home/container/txData"  # Update this path as needed

# Find the latest directory created if txAdmin is enabled
if [ "$TXADMIN_ENABLE" == "1" ]; then
    LATEST_DIR=$(ls -td ${PARENT_DIR}/*/ | head -1)
    SERVER_CFG_PATH="${LATEST_DIR}/server.cfg"
else
    # Use default path if txAdmin is not enabled
    SERVER_CFG_PATH="/home/container/server.cfg"
fi

# Check if server.cfg exists
if [ -f "$SERVER_CFG_PATH" ]; then
    echo "Updating server.cfg in $LATEST_DIR with new values..."

    # Create a backup of the original server.cfg
    cp "$SERVER_CFG_PATH" "$SERVER_CFG_PATH.bak"

    # Update the server.cfg file with the new values
    sed -i "s/^endpoint_add_tcp.*/endpoint_add_tcp \"0.0.0.0:$SERVER_PORT\"/" "$SERVER_CFG_PATH"
    sed -i "s/^endpoint_add_udp.*/endpoint_add_udp \"0.0.0.0:$SERVER_PORT\"/" "$SERVER_CFG_PATH"
    sed -i "s/^sv_hostname.*/sv_hostname \"$SERVER_HOSTNAME\"/" "$SERVER_CFG_PATH"
    sed -i "s/^set sv_licenseKey.*/set sv_licenseKey $FIVEM_LICENSE/" "$SERVER_CFG_PATH"
    sed -i "s/^set steam_webApiKey.*/set steam_webApiKey $STEAM_WEBAPIKEY/" "$SERVER_CFG_PATH"
    sed -i "s/^sv_maxclients.*/sv_maxclients $MAX_PLAYERS/" "$SERVER_CFG_PATH"

    if [ $? -eq 0 ]; then
        echo "server.cfg updated successfully in $LATEST_DIR."
    else
        echo "Failed to update server.cfg."
        mv "$SERVER_CFG_PATH.bak" "$SERVER_CFG_PATH"
        exit 1
    fi
else
    echo "No server.cfg found in $SERVER_CFG_PATH. Exiting."
    exit 1
fi

# Start the server
echo "Starting the server..."
cd "$(dirname "$SERVER_CFG_PATH")"
$(pwd)/alpine/opt/cfx-server/ld-musl-x86_64.so.1 --library-path "$(pwd)/alpine/usr/lib/v8/:$(pwd)/alpine/lib/:$(pwd)/alpine/usr/lib/" -- $(pwd)/alpine/opt/cfx-server/FXServer +set citizen_dir $(pwd)/alpine/opt/cfx-server/citizen/ +set sv_licenseKey $FIVEM_LICENSE +set steam_webApiKey $STEAM_WEBAPIKEY +set sv_maxplayers $MAX_PLAYERS +set serverProfile default +set txAdminPort $TXADMIN_PORT $( [ "$TXADMIN_ENABLE" == "1" ] || printf %s '+exec server.cfg' )
