#!/bin/bash

SCRIPT_PATH="/etc/NetworkManager/dispatcher.d/wifi-auto-login.sh"
CONFIG_PATH="/etc/wifi-auto-login.conf"
LOGFILE="/var/log/wifi-monitor.log"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use: sudo $0"
   exit 1
fi

setup_config() {
    echo "Setting up WiFi Auto-Login..."


    echo "Enter the WiFi SSIDs you want to auto-login for (one per line) e.g Boys Hostel."
    echo "Type 'done' when finished."
    
    SSID_LIST=()
    while true; do
        read -r SSID
        [[ "$SSID" == "done" ]] && break
        SSID_LIST+=("$SSID")
    done

    echo -n "Enter your username: "
    read -r USERNAME
    echo -n "Enter your password: "
    read -s PASSWORD
    echo ""

    # Store configuration securely
    {
        echo "USERNAME=\"$USERNAME\""
        echo "PASSWORD=\"$PASSWORD\""
        echo "SSID_LIST=("
        for ssid in "${SSID_LIST[@]}"; do
            echo "    \"$ssid\""
        done
        echo ")"
    } > "$CONFIG_PATH"

    chmod 600 "$CONFIG_PATH"
    echo "Configuration saved at $CONFIG_PATH"
}

# Run setup if no config file exists
if [ ! -f "$CONFIG_PATH" ]; then
    setup_config
fi

cat << 'EOF' > "$SCRIPT_PATH"
#!/bin/bash

CONFIG_PATH="/etc/wifi-auto-login.conf"
LOGFILE="/var/log/wifi-monitor.log"
INTERFACE="$1"
ACTION="$2"

# Load SSID list and credentials
source "$CONFIG_PATH"

CURRENT_SSID=$(iwgetid -r)

# Only trigger on connectivity change
if [ "$ACTION" = "connectivity-change" ]; then
    echo "$(date): Connectivity changed. Checking SSID..." >> $LOGFILE
    echo "$(date): Connected to SSID: $CURRENT_SSID" >> $LOGFILE

    for ssid in "${SSID_LIST[@]}"; do
        if [[ "$CURRENT_SSID" == "$ssid" ]]; then
            echo "$(date): Target WiFi detected: $CURRENT_SSID. Checking portal..." >> $LOGFILE

            if [ "$CONNECTIVITY_STATE" = "PORTAL" ]; then
                echo "$(date): Internet is in PORTAL state. Attempting login..." >> $LOGFILE

                HTML=$(curl -s http://www.google.com)
                TOKEN=$(echo "$HTML" | grep -oP 'fgtauth\?\K[0-9a-f]+')

                if [ -z "$TOKEN" ]; then
                    echo "$(date): Failed to get authentication token." >> $LOGFILE
                    exit 1
                fi

                # Retrieve magic value
                LOGIN_PAGE=$(curl -s "http://10.54.0.1:1000/fgtauth?$TOKEN")
                MAGIC=$(echo "$LOGIN_PAGE" | grep -oP 'name="magic" value="\K[^"]+')

                if [ -z "$MAGIC" ]; then
                    echo "$(date): Failed to extract magic token." >> $LOGFILE
                    exit 1
                fi

                # Submit login request
                curl -s -X POST "http://10.54.0.1:1000/" \
                    -d "username=$USERNAME&password=$PASSWORD&magic=$MAGIC&4Tredir=http://www.google.com/"

                echo "$(date): Auto-login attempt completed." >> $LOGFILE
            fi
        fi
    done
fi
EOF

# Make script executable
chmod +x "$SCRIPT_PATH"

echo "Restarting NetworkManager to apply changes..."
systemctl restart NetworkManager

echo "Running script to test login..."
bash "$SCRIPT_PATH"

echo "Setup complete. The script will run automatically when connecting to specified networks."
