#!/bin/bash
###############################################################################
# DVSwitch Network Switcher
# Switches between DMR networks using configs from var.txt
###############################################################################

NETWORK="$1"
INI_FILE="/opt/MMDVM_Bridge/MMDVM_Bridge.ini"
VAR_FILE="/var/lib/dvswitch/dvs/var.txt"

if [ -z "$NETWORK" ]; then
    echo "Usage: $0 {BrandMeister|TGIF|DMRplus|FreeDMR|Other1|Other2}"
    exit 1
fi

if [ ! -f "$VAR_FILE" ]; then
    echo "Error: $VAR_FILE not found"
    exit 1
fi

# Source the var.txt file to get network configurations
source "$VAR_FILE"

# Function to update network config
update_network() {
    local address="$1"
    local port="$2"
    local password="$3"
    local name="$4"
    
    if [ -z "$address" ] || [ -z "$port" ] || [ -z "$password" ]; then
        echo "Error: $name is not configured in $VAR_FILE"
        exit 1
    fi
    
    # Stop MMDVM_Bridge
    systemctl stop mmdvm_bridge
    sleep 2
    
    # Update Address
    sed -i "/^\[DMR Network\]/,/^\[/ s|^Address=.*|Address=$address|" "$INI_FILE"
    
    # Update Port
    sed -i "/^\[DMR Network\]/,/^\[/ s|^Port=.*|Port=$port|" "$INI_FILE"
    
    # Update Password
    sed -i "/^\[DMR Network\]/,/^\[/ s|^Password=.*|Password=$password|" "$INI_FILE"
    
    # Start MMDVM_Bridge
    sleep 1
    systemctl start mmdvm_bridge
    
    echo "Switched to $name network"
}

case "$NETWORK" in
    BrandMeister)
        # Get current TG from StartupDstId or use 3100 as default
        CURRENT_TG=$(grep "StartupDstId" "$INI_FILE" | head -1 | sed 's/.*= *//' | tr -d ' ')
        [ -z "$CURRENT_TG" ] && CURRENT_TG="3100"
        
        update_network "$bm_address" "$bm_port" "$bm_password" "$bm_name"
        
        # Add BrandMeister Options for static TG connection
        if grep -q "^Options=" "$INI_FILE"; then
            sed -i "/^\[DMR Network\]/,/^\[/ s|^Options=.*|Options=StartRef=$CURRENT_TG;RelinkTime=15;|" "$INI_FILE"
        else
            sed -i "/^\[DMR Network\]/,/^\[/ s|^Password=.*|&\nOptions=StartRef=$CURRENT_TG;RelinkTime=15;|" "$INI_FILE"
        fi
        
        # Restart to apply Options
        systemctl restart mmdvm_bridge
        echo "BrandMeister configured with static TG $CURRENT_TG"
        ;;
    TGIF)
        update_network "$tgif_address" "$tgif_port" "$tgif_password" "$tgif_name"
        # Remove Options line (TGIF doesn't use it)
        sed -i "/^\[DMR Network\]/,/^\[/ /^Options=/d" "$INI_FILE"
        systemctl restart mmdvm_bridge
        ;;
    DMRplus)
        update_network "$dmrplus_address" "$dmrplus_port" "$dmrplus_password" "$dmrplus_name"
        ;;
    FreeDMR)
        # FreeDMR might be in other1 or other2
        if [[ "$other1_name" == *"FreeDMR"* ]]; then
            update_network "$other1_address" "$other1_port" "$other1_password" "$other1_name"
        elif [[ "$other2_name" == *"FreeDMR"* ]]; then
            update_network "$other2_address" "$other2_port" "$other2_password" "$other2_name"
        else
            echo "Error: FreeDMR not configured. Use Other1 or Other2 in var.txt"
            exit 1
        fi
        ;;
    Other1)
        update_network "$other1_address" "$other1_port" "$other1_password" "$other1_name"
        ;;
    Other2)
        update_network "$other2_address" "$other2_port" "$other2_password" "$other2_name"
        ;;
    *)
        echo "Unknown network: $NETWORK"
        echo "Valid options: BrandMeister, TGIF, DMRplus, FreeDMR, Other1, Other2"
        exit 1
        ;;
esac
