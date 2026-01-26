#!/bin/bash
echo "Content-type: application/json"
echo ""

QUERY_STRING="${QUERY_STRING}"

if [ "$REQUEST_METHOD" = "POST" ]; then
    read -n $CONTENT_LENGTH POST_DATA
    
    # Check if this is an add favorite request
    if [[ "$POST_DATA" == *"action=add_favorite"* ]]; then
        TG=$(echo "$POST_DATA" | grep -o "tg=[0-9]*" | cut -d'=' -f2)
        NAME=$(echo "$POST_DATA" | grep -o "name=[^&]*" | cut -d'=' -f2 | sed 's/%20/ /g' | sed 's/+/ /g' | sed 's/%2B/ /g')
        
        if [ -z "$TG" ] || [ -z "$NAME" ]; then
            echo '{"status":"error","message":"Missing talkgroup or name"}'
            exit 0
        fi
        
        FAVORITES_FILE="/var/lib/dvswitch/dvs/tgdb/DMR_fvrt_list.txt"
        
        if grep -q "^${TG}|||" "$FAVORITES_FILE" 2>/dev/null; then
            echo '{"status":"error","message":"Talkgroup already in favorites"}'
            exit 0
        fi
        
        echo "${TG}|||${NAME}" >> "$FAVORITES_FILE"
        echo '{"status":"success","message":"Added to favorites"}'
        exit 0
    fi
    
    # Check if this is a delete favorite request
    if [[ "$POST_DATA" == *"action=delete_favorite"* ]]; then
        TG=$(echo "$POST_DATA" | grep -o "tg=[0-9]*" | cut -d'=' -f2)
        
        if [ -z "$TG" ]; then
            echo '{"status":"error","message":"Missing talkgroup number"}'
            exit 0
        fi
        
        FAVORITES_FILE="/var/lib/dvswitch/dvs/tgdb/DMR_fvrt_list.txt"
        
        sed -i "/^${TG}|||/d" "$FAVORITES_FILE"
        echo '{"status":"success","message":"Removed from favorites"}'
        exit 0
    fi
    
    # Regular command execution
    CMD=$(echo "$POST_DATA" | sed 's/cmd=//' | sed 's/%20/ /g' | sed 's/%2F/\//g' | sed 's/+/ /g')
    
    # Check if this is a network switch command
    if [[ "$CMD" == *"network-switcher"* ]]; then
        # Extract network name
        NETWORK=$(echo "$CMD" | grep -o 'BrandMeister\|TGIF\|DMRplus\|FreeDMR')
        if [ -n "$NETWORK" ]; then
            OUTPUT=$(sudo /usr/local/bin/dvswitch-network-switcher.sh "$NETWORK" 2>&1)
            RESULT=$?
            if [ $RESULT -eq 0 ]; then
                echo '{"status":"success","output":"Network switched"}'
            else
                echo "{\"status\":\"error\",\"output\":\"$OUTPUT\"}"
            fi
            exit 0
        fi
    fi
    
    if [[ ! "$CMD" =~ ^/opt/MMDVM_Bridge/dvswitch\.sh ]]; then
        echo '{"status":"error","message":"Invalid command"}'
        exit 1
    fi
    
    OUTPUT=$($CMD 2>&1)
    RESULT=$?
    
    if [ $RESULT -eq 0 ]; then
        echo '{"status":"success","output":"Command executed"}'
    else
        echo '{"status":"error","output":"Command failed"}'
    fi
    
elif [[ "$QUERY_STRING" == *"action=get_favorites"* ]]; then
    FAVORITES_FILE="/var/lib/dvswitch/dvs/tgdb/DMR_fvrt_list.txt"
    
    # Build favorites array
    FAVORITES_JSON=""
    FIRST=true
    while IFS= read -r line; do
        # Remove any carriage returns
        line=$(echo "$line" | tr -d '\r')
        
        if [ -z "$line" ]; then
            continue
        fi
        
        TG=$(echo "$line" | sed 's/|||.*//')
        NAME=$(echo "$line" | sed 's/.*|||//')
        
        if [ -z "$TG" ] || [[ ! "$TG" =~ ^[0-9]+$ ]]; then
            continue
        fi
        
        if [ "$FIRST" = true ]; then
            FAVORITES_JSON="{\"tg\":$TG,\"name\":\"$NAME\"}"
            FIRST=false
        else
            FAVORITES_JSON="${FAVORITES_JSON},{\"tg\":$TG,\"name\":\"$NAME\"}"
        fi
    done < "$FAVORITES_FILE"
    
    # Get callsign
    CALLSIGN=$(/opt/MMDVM_Bridge/dvswitch.sh show 2>/dev/null | grep '"call"' | sed 's/.*"call": "\([^"]*\)".*/\1/')
    if [ -z "$CALLSIGN" ]; then
        CALLSIGN="NOCALL"
    fi
    
    # Get node number
    NODE_NUMBER=$(grep -A 50 "^\[nodes\]" /etc/asterisk/rpt.conf | grep "^[0-9]" | grep -v "^1999" | head -1 | cut -d'=' -f1 | tr -d ' ')
    if [ -z "$NODE_NUMBER" ]; then
        NODE_NUMBER="UNKNOWN"
    fi
    
    # Get current mode
    CURRENT_MODE=$(/opt/MMDVM_Bridge/dvswitch.sh show 2>/dev/null | grep '"mode"' | sed 's/.*"mode": "\([^"]*\)".*/\1/')
    if [ -z "$CURRENT_MODE" ]; then
        CURRENT_MODE="UNKNOWN"
    fi
    
    # Get current DMR network
    DMR_NETWORK="UNKNOWN"
    if [ -f "/opt/MMDVM_Bridge/MMDVM_Bridge.ini" ]; then
        DMR_ADDRESS=$(grep -A 10 "^\[DMR Network\]" /opt/MMDVM_Bridge/MMDVM_Bridge.ini | grep "^Address" | cut -d'=' -f2 | tr -d ' ')
        case "$DMR_ADDRESS" in
            *brandmeister*|*bm.sytes*|*3102.master.brandmeister*)
                DMR_NETWORK="BrandMeister"
                ;;
            *tgif*)
                DMR_NETWORK="TGIF"
                ;;
            *dmrplus*|*dmr-marc*)
                DMR_NETWORK="DMRplus"
                ;;
            *freedmr*)
                DMR_NETWORK="FreeDMR"
                ;;
            *)
                if [ -n "$DMR_ADDRESS" ]; then
                    DMR_NETWORK="${DMR_ADDRESS%%.*}"
                fi
                ;;
        esac
    fi
    
    # Get available networks from var.txt
    AVAILABLE_NETWORKS=""
    if [ -f "/var/lib/dvswitch/dvs/var.txt" ]; then
        source /var/lib/dvswitch/dvs/var.txt
        
        # Check which networks are configured (have address and password)
        [ -n "$bm_address" ] && [ -n "$bm_password" ] && AVAILABLE_NETWORKS="${AVAILABLE_NETWORKS}\"BrandMeister\","
        [ -n "$tgif_address" ] && [ -n "$tgif_password" ] && AVAILABLE_NETWORKS="${AVAILABLE_NETWORKS}\"TGIF\","
        [ -n "$dmrplus_address" ] && [ -n "$dmrplus_password" ] && AVAILABLE_NETWORKS="${AVAILABLE_NETWORKS}\"DMRplus\","
        [ -n "$other1_address" ] && [ -n "$other1_password" ] && AVAILABLE_NETWORKS="${AVAILABLE_NETWORKS}\"${other1_name:-Other1}\","
        [ -n "$other2_address" ] && [ -n "$other2_password" ] && AVAILABLE_NETWORKS="${AVAILABLE_NETWORKS}\"${other2_name:-Other2}\","
        
        # Remove trailing comma
        AVAILABLE_NETWORKS=$(echo "$AVAILABLE_NETWORKS" | sed 's/,$//')
    fi
    
    # Output complete JSON in one echo
    echo "{\"status\":\"success\",\"favorites\":[$FAVORITES_JSON],\"callsign\":\"$CALLSIGN\",\"node\":\"$NODE_NUMBER\",\"mode\":\"$CURRENT_MODE\",\"network\":\"$DMR_NETWORK\",\"available_networks\":[$AVAILABLE_NETWORKS]}"
else
    echo '{"status":"error","message":"Invalid request"}'
fi
